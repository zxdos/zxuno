---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_MISC.all;

library work;
use work.zpupkg.all;

ENTITY zpu_glue IS
PORT 
(
	CLK : in std_logic;
	RESET : in std_logic;
	PAUSE : in std_logic;

	ZPU_DI : in std_logic_vector(31 downto 0); -- response from general memory - for areas that only support 8/16 bit set top bits to 0
	ZPU_ROM_DI : in std_logic_vector(31 downto 0); -- response from own program memory
	ZPU_RAM_DI : in std_logic_vector(31 downto 0); -- response from own stack	
	ZPU_CONFIG_DI : in std_logic_vector(31 downto 0); -- response from config registers
	
	ZPU_DO : out std_logic_vector(31 downto 0);
	
	ZPU_ADDR_ROM_RAM : out std_logic_vector(15 downto 0); -- direct from zpu, for short paths
	ZPU_ADDR_FETCH : out std_logic_vector(23 downto 0); -- clk->q, for longer paths
	
	-- request
	MEMORY_FETCH : out std_logic;
	ZPU_READ_ENABLE : out std_logic;
	ZPU_32BIT_WRITE_ENABLE : out std_logic; -- common case
	ZPU_16BIT_WRITE_ENABLE : out std_logic; -- for sram (never happens yet!)
	ZPU_8BIT_WRITE_ENABLE : out std_logic; -- for hardware regs
	
	-- config
	ZPU_CONFIG_WRITE : out std_logic;
	ZPU_CONFIG_READ : out std_logic;
	
	-- stack request
	ZPU_STACK_WRITE : out std_logic_vector(3 downto 0);

	-- write to ROM!!
	ZPU_ROM_WREN : out std_logic;

	-- response
	MEMORY_READY : in std_logic
);
END zpu_glue;

architecture sticky of zpu_glue is
component ZPUMediumCore is
   generic(
      WORD_SIZE    : integer:=32;  -- 16/32 (2**wordPower)
      ADDR_W       : integer:=24;  -- Total address space width (incl. I/O)
      MEM_W        : integer:=16;  -- Memory (prog+data+stack) width - stack at end of memory - so end of sdram. 32K ROM, 32K RAM (MAX)
      D_CARE_VAL   : std_logic:='X'; -- Value used to fill the unsused bits
      MULT_PIPE    : boolean:=false; -- Pipeline multiplication
      BINOP_PIPE   : integer range 0 to 2:=0; -- Pipeline binary operations (-, =, < and <=)
      ENA_LEVEL0   : boolean:=true;  -- eq, loadb, neqbranch and pushspadd
      ENA_LEVEL1   : boolean:=true;  -- lessthan, ulessthan, mult, storeb, callpcrel and sub
      ENA_LEVEL2   : boolean:=true; -- lessthanorequal, ulessthanorequal, call and poppcrel
      ENA_LSHR     : boolean:=true;  -- lshiftright
      ENA_IDLE     : boolean:=false; -- Enable the enable_i input
      FAST_FETCH   : boolean:=true); -- Merge the st_fetch with the st_execute states
   port(
      clk_i        : in  std_logic; -- CPU Clock
      reset_i      : in  std_logic; -- Sync Reset
      enable_i     : in  std_logic; -- Hold the CPU (after reset)
      break_o      : out std_logic; -- Break instruction executed
      dbg_o        : out zpu_dbgo_t; -- Debug outputs (i.e. trace log)
      -- Memory interface
      mem_busy_i   : in  std_logic; -- Memory is busy
      data_i       : in  unsigned(WORD_SIZE-1 downto 0); -- Data from mem
      data_o       : out unsigned(WORD_SIZE-1 downto 0); -- Data to mem
      addr_o       : out unsigned(ADDR_W-1 downto 0); -- Memory address
      write_en_o   : out std_logic;  -- Memory write enable (32-bit)
      read_en_o    : out std_logic; -- Memory read enable (32-bit)
		byte_read_o : out std_logic;
		byte_write_o : out std_logic;
		short_write_o: out std_logic); -- never happens
	end component;	
			
	signal zpu_addr_unsigned : unsigned(23 downto 0);
	signal zpu_do_unsigned : unsigned(31 downto 0);
	signal ZPU_DI_unsigned : unsigned(31 downto 0);
	signal zpu_break : std_logic;
	signal zpu_debug : zpu_dbgo_t;
	
	signal zpu_mem_busy : std_logic;
	
	signal zpu_memory_fetch_pending_next : std_logic;
	signal zpu_memory_fetch_pending_reg : std_logic;
	
	signal ZPU_32bit_READ_ENABLE_temp : std_logic;
	signal ZPU_8bit_READ_ENABLE_temp : std_logic;	
	signal ZPU_READ_temp : std_logic;
	signal ZPU_32BIT_WRITE_ENABLE_temp : std_logic;
	signal ZPU_16BIT_WRITE_ENABLE_temp : std_logic;
	signal ZPU_8BIT_WRITE_ENABLE_temp : std_logic;	
	signal ZPU_WRITE_temp : std_logic;
	
	signal ZPU_32BIT_WRITE_ENABLE_next : std_logic;
	signal ZPU_16BIT_WRITE_ENABLE_next : std_logic;
	signal ZPU_8BIT_WRITE_ENABLE_next : std_logic;	
	signal ZPU_READ_next : std_logic;
	signal ZPU_32BIT_WRITE_ENABLE_reg : std_logic;
	signal ZPU_16BIT_WRITE_ENABLE_reg : std_logic;
	signal ZPU_8BIT_WRITE_ENABLE_reg : std_logic;	
	signal ZPU_READ_reg : std_logic;
	
	signal block_mem : std_logic;
	signal config_mem : std_logic;
	signal special_mem : std_logic;
	
	signal result_next : std_logic_vector(4 downto 0);
	signal result_reg : std_logic_vector(4 downto 0);
	constant result_external   : std_logic_vector(4 downto 0) := "00000";
	constant result_ram        : std_logic_vector(4 downto 0) := "00001";
	constant result_ram_8bit_0 : std_logic_vector(4 downto 0) := "00010";
	constant result_ram_8bit_1 : std_logic_vector(4 downto 0) := "00011";
	constant result_ram_8bit_2 : std_logic_vector(4 downto 0) := "00100";
	constant result_ram_8bit_3 : std_logic_vector(4 downto 0) := "00101";
	constant result_rom        : std_logic_vector(4 downto 0) := "00110";
	constant result_rom_8bit_0 : std_logic_vector(4 downto 0) := "00111";
	constant result_rom_8bit_1 : std_logic_vector(4 downto 0) := "01000";
	constant result_rom_8bit_2 : std_logic_vector(4 downto 0) := "01001";
	constant result_rom_8bit_3 : std_logic_vector(4 downto 0) := "01010";	
	constant result_config     : std_logic_vector(4 downto 0) := "01011";	
	constant result_external_special : std_logic_vector(4 downto 0) := "01100";
	
	signal request_type : std_logic_vector(4 downto 0);
	
	signal zpu_di_use : std_logic_vector(31 downto 0);
	
	signal memory_access : std_logic;

	-- 1 cycle delay on memory read - needed to allow running at higher clock
	signal zpu_di_next : std_logic_vector(31 downto 0);
	signal zpu_di_reg : std_logic_vector(31 downto 0);
	
	signal memory_ready_next : std_logic;
	signal memory_ready_reg : std_logic;
	
	signal zpu_enable : std_logic;
	
	signal zpu_addr_next : std_logic_vector(23 downto 0);
	signal zpu_addr_reg : std_logic_vector(23 downto 0);

	signal ZPU_DO_next : std_logic_vector(31 downto 0);
	signal ZPU_DO_reg : std_logic_vector(31 downto 0);
	
begin
		-- register
	process(clk,reset)
	begin
		if (reset='1') then
			zpu_memory_fetch_pending_reg <= '0';
			result_reg <= result_rom;
			zpu_di_reg <= (others=>'0');
			zpu_do_reg <= (others=>'0');
			memory_ready_reg <= '0';
			zpu_addr_reg <= (others=>'0');
			ZPU_32BIT_WRITE_ENABLE_reg <= '0';
			ZPU_16BIT_WRITE_ENABLE_reg <= '0';
			ZPU_8BIT_WRITE_ENABLE_reg <= '0';	
			ZPU_READ_reg <= '0';
		elsif (clk'event and clk='1') then
			zpu_memory_fetch_pending_reg <= zpu_memory_fetch_pending_next;
			result_reg <= result_next;
			zpu_di_reg <= zpu_di_next;
			zpu_do_reg <= zpu_do_next;
			memory_ready_reg <= memory_ready_next;
			zpu_addr_reg <=zpu_addr_next;
			ZPU_32BIT_WRITE_ENABLE_reg <= ZPU_32BIT_WRITE_ENABLE_next;
			ZPU_16BIT_WRITE_ENABLE_reg <= ZPU_16BIT_WRITE_ENABLE_next;
			ZPU_8BIT_WRITE_ENABLE_reg <= ZPU_8BIT_WRITE_ENABLE_next;
			ZPU_READ_reg <= ZPU_READ_next;
		end if;
	end process;

-- a little glue
	process(zpu_ADDR_unsigned)
	begin
		block_mem <= '0';
		config_mem <= '0';
		special_mem <= '0';
		-- $00000-$0FFFF = Own ROM/RAM
		-- $10000-$1FFFF = Atari
		-- $20000-$2FFFF = Atari - savestate (gtia/antic/pokey have memory behind them)
		-- $40000-$4FFFF = Config area
		if (or_reduce(std_logic_vector(zpu_ADDR_unsigned(23 downto 21))) = '0') then -- special area
			block_mem <= not(zpu_addr_unsigned(18) or zpu_addr_unsigned(17) or zpu_addr_unsigned(16));
			config_mem <= zpu_addr_unsigned(18);
			special_mem <= zpu_addr_unsigned(17);
		end if;	
	end process;

	ZPU_READ_TEMP <= zpu_32bit_read_enable_temp or zpu_8BIT_read_enable_temp;
	ZPU_WRITE_TEMP<= zpu_32BIT_WRITE_ENABLE_temp or zpu_16BIT_WRITE_ENABLE_temp or zpu_8BIT_WRITE_ENABLE_temp;
	process(zpu_addr_reg,pause,memory_ready,zpu_memory_fetch_pending_next,request_type, zpu_memory_fetch_pending_reg, memory_ready_reg, zpu_ADDR_unsigned, zpu_8bit_read_enable_temp, zpu_write_temp, result_reg, block_mem, config_mem, special_mem, memory_access,
	        zpu_read_reg,zpu_8BIT_WRITE_ENABLE_reg, zpu_16BIT_WRITE_ENABLE_reg, zpu_32BIT_WRITE_ENABLE_reg,
			  zpu_read_temp,zpu_8BIT_WRITE_ENABLE_temp, zpu_16BIT_WRITE_ENABLE_temp, zpu_32BIT_WRITE_ENABLE_temp,
	zpu_do_unsigned, zpu_do_reg
			  )
	begin
		zpu_memory_fetch_pending_next <= zpu_memory_fetch_pending_reg;
		result_next <= result_reg;
		memory_ready_next <= memory_ready;
		zpu_stACK_WRITE <= (others=>'0');
		ZPU_ROM_WREN <= '0';
		ZPU_config_write <= '0';
		ZPU_config_read <= '0';
		zpu_addr_next <= zpu_addr_reg;
		zpu_do_next <= zpu_do_reg;
	
		ZPU_MEM_BUSY <= pause;
		
		MEMORY_ACCESS <= zpu_READ_temp or ZPU_WRITE_temp;

		if (memory_access = '1') then
			zpu_do_next <= std_logic_vector(zpu_do_unsigned);
		end if;
		
		memory_fetch <= zpu_memory_fetch_pending_reg;
		
		zpu_read_next <= zpu_read_reg;
		zpu_8bit_write_enable_next <= zpu_8bit_write_enable_reg;
		zpu_16bit_write_enable_next <= zpu_16bit_write_enable_reg;
		zpu_32bit_write_enable_next <= zpu_32bit_write_enable_reg;	
		
		request_type <= config_mem&block_mem&zpu_addr_unsigned(15)&memory_access&zpu_memory_fetch_pending_reg;
		case request_type is
			when "00010"|"00110" =>
				zpu_memory_fetch_pending_next <= '1';
				if (special_mem='0') then
					result_next <= result_external;
				else
					result_next <= result_external_special;
				end if;
				
				ZPU_MEM_BUSY <= '1';
				zpu_addr_next <= std_logic_vector(zpu_addr_unsigned);
				zpu_read_next <= zpu_read_temp;
				zpu_8bit_write_enable_next <= zpu_8bit_write_enable_temp;
				zpu_16bit_write_enable_next <= zpu_16bit_write_enable_temp;
				zpu_32bit_write_enable_next <= zpu_32bit_write_enable_temp;					
			when "01010" =>
				if (zpu_8bit_read_enable_temp='1') then
					case (zpu_addr_unsigned(1 downto 0)) is
					when "00" =>
						result_next <= result_rom_8bit_3;										
					when "01" =>
						result_next <= result_rom_8bit_2;
					when "10" =>
						result_next <= result_rom_8bit_1;										
					when "11" =>
						result_next <= result_rom_8bit_0;
					when others =>
						--nop
					end case;
				else
					result_next <= result_rom;
				end if;
				ZPU_ROM_WREN <= ZPU_WRITE_TEMP;
				ZPU_MEM_BUSY <= '1';
				zpu_addr_next <= std_logic_vector(zpu_addr_unsigned);
			when "01110" =>
				if (zpu_8bit_read_enable_temp='1' or zpu_8BIT_WRITE_ENABLE_temp='1') then
					case (zpu_addr_unsigned(1 downto 0)) is
					when "00" =>
						result_next <= result_ram_8bit_3;										
						ZPU_STACK_WRITE(3) <= zpu_8BIT_write_enable_temp;
					when "01" =>
						result_next <= result_ram_8bit_2;
						ZPU_STACK_WRITE(2) <= zpu_8BIT_write_enable_temp;
					when "10" =>
						result_next <= result_ram_8bit_1;					
						ZPU_STACK_WRITE(1) <= zpu_8BIT_write_enable_temp;					
					when "11" =>
						result_next <= result_ram_8bit_0;
						ZPU_STACK_WRITE(0) <= zpu_8BIT_write_enable_temp;
					when others =>
						--nop
					end case;
				else
					result_next <= result_ram;
					ZPU_STACK_WRITE <= (others=>zpu_write_temp);					
				end if;
				ZPU_MEM_BUSY <= '1';				
				zpu_addr_next <= std_logic_vector(zpu_addr_unsigned);
			when "10110"|"10010" =>
				result_next <= result_config;
				ZPU_MEM_BUSY <= '1';
				ZPU_config_write <= ZPU_WRITE_temp; 
				ZPU_config_read <= ZPU_READ_temp; 
				zpu_addr_next <= std_logic_vector(zpu_addr_unsigned);				
			when "00001"|"00011"|"00101"|"00111"|"01001"|"01011"|"01101"|"01111"|
				  "10001"|"10011"|"10101"|"10111"|"11001"|"11011"|"11101"|"11111"|"00X01" =>
				ZPU_MEM_BUSY <= not(memory_ready_reg) or pause;
				zpu_memory_fetch_pending_next <= not(memory_ready);
			when others =>
				-- nop
		end case;
	end process;

	zpu_di_next <= zpu_di;
	process(result_reg, zpu_di_reg, zpu_rom_di, zpu_ram_di, zpu_config_di)
	begin
		zpu_di_use <= (others=>'0');
		case result_reg is 
			when result_external =>
				zpu_di_use <= zpu_di_reg;
			when result_external_special =>
				zpu_di_use(7 downto 0) <= zpu_di_reg(15 downto 8);				
			when result_rom =>
				zpu_di_use <= zpu_rom_DI;
			when result_rom_8bit_0 =>
				zpu_di_use(7 downto 0) <= zpu_rom_DI(7 downto 0);
			when result_rom_8bit_1 =>
				zpu_di_use(7 downto 0) <= zpu_rom_DI(15 downto 8);
			when result_rom_8bit_2 =>
				zpu_di_use(7 downto 0) <= zpu_rom_DI(23 downto 16);
			when result_rom_8bit_3 =>
				zpu_di_use(7 downto 0) <= zpu_rom_DI(31 downto 24);				
			when result_ram =>
				zpu_di_use <= zpu_ram_DI;
			when result_ram_8bit_0 =>
				zpu_di_use(7 downto 0) <= zpu_ram_DI(7 downto 0);
			when result_ram_8bit_1 =>
				zpu_di_use(7 downto 0) <= zpu_ram_DI(15 downto 8);
			when result_ram_8bit_2 =>
				zpu_di_use(7 downto 0) <= zpu_ram_DI(23 downto 16);
			when result_ram_8bit_3 =>
				zpu_di_use(7 downto 0) <= zpu_ram_DI(31 downto 24);				
			when result_config =>
				zpu_di_use <= zpu_config_di;
			when others =>
				-- nothing
		end case;
	end process;

-- zpu itself
	--zpu_enable <= enable and not(pause);
	zpu_enable <= '1'; -- does nothing useful...
	
myzpu: ZPUMediumCore
	port map (clk_i=>clk, reset_i=>reset,enable_i=>zpu_enable,break_o=>zpu_break,dbg_o=>zpu_debug,mem_busy_i=>ZPU_MEM_BUSY,
	data_i=>zpu_di_unsigned,data_o=>zpu_do_unsigned,addr_o=>zpu_addr_unsigned,write_en_o=>zpu_32bit_write_enable_temp,read_en_o=>zpu_32bit_read_enable_temp,
	byte_read_o=>zpu_8bit_read_enable_temp, byte_write_o=>zpu_8bit_write_enable_temp,short_write_o=>zpu_16bit_write_enable_temp);
	
	zpu_di_unsigned <= unsigned(zpu_di_use);
	zpu_do <= zpu_do_next;
	ZPU_ADDR_ROM_RAM <= zpu_addr_next(15 downto 0);
	ZPU_ADDR_FETCH <= zpu_addr_reg;
		
	zpu_read_enable <= zpu_read_reg;
	zpu_8bit_write_enable <= zpu_8bit_write_enable_reg;
	zpu_16bit_write_enable <= zpu_16bit_write_enable_reg;
	zpu_32bit_write_enable <= zpu_32bit_write_enable_reg;

end sticky;
