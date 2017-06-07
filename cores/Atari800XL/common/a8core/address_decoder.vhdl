---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;


ENTITY address_decoder IS
GENERIC
(
	low_memory : integer := 2; -- if 0, we assume 8MB SDRAM, if 1, we assume 1MB 'SDRAM', if 2 we assume 512KB 'SDRAM'.
	stereo : integer := 0; 
	system : integer := 0 -- 0=Atari XL, 10=Atari5200 (space left for more systems)
);
PORT 
( 
	CLK : IN STD_LOGIC;
	
	-- bus masters - either CPU or antic
	-- antic has priority and is slected when ANTIC_FETCH high
	CPU_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	CPU_FETCH : in std_logic;
	CPU_WRITE_N : IN STD_LOGIC;
	CPU_WRITE_DATA : in std_logic_vector(7 downto 0);	
	
	ANTIC_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	ANTIC_FETCH : IN STD_LOGIC;

	DMA_ADDR : in std_logic_vector(23 downto 0);	
	DMA_FETCH : in std_logic;
	DMA_READ_ENABLE : in std_logic;
	DMA_32BIT_WRITE_ENABLE : in std_logic; -- common case
	DMA_16BIT_WRITE_ENABLE : in std_logic; -- for sram
	DMA_8BIT_WRITE_ENABLE : in std_logic; -- for hardware regs	
	DMA_WRITE_DATA : in std_logic_vector(31 downto 0);
	
	-- sources of data
	ROM_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	-- flash rom
	GTIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_GTIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	POKEY_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_POKEY_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	POKEY2_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	CACHE_POKEY2_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	ANTIC_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_ANTIC_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	PIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	RAM_DATA : IN STD_LOGIC_VECTOR(15 downto 0);
	CART_ROM_DATA : in std_logic_Vector(7 downto 0);
	
	-- completion flags
	RAM_REQUEST_COMPLETE : IN STD_LOGIC;
	ROM_REQUEST_COMPLETE : IN STD_LOGIC;
	CART_REQUEST_COMPLETE : IN STD_LOGIC;
	
	-- configuration options	
	PORTB : IN STD_LOGIC_VECTOR(7 downto 0);
	
	reset_n : in std_logic;

	rom_in_ram : in std_logic;
	
	cart_select : in std_logic_vector(5 downto 0);
	
	ram_select : in std_logic_vector(2 downto 0);
	
	CART_RD4 : in std_logic;
	CART_RD5 : in std_logic;
	
	use_sdram : in std_logic;
		
	-- Memory read mux output
	MEMORY_DATA : OUT STD_LOGIC_VECTOR(31 downto 0);
	
	-- Flash and internal RAM take 2 cycles to access. SRAM takes 1 cycle.
	-- Allow us to say we're not ready for a cycle
	MEMORY_READY_ANTIC : OUT STD_LOGIC;
	MEMORY_READY_DMA : OUT STD_LOGIC;
	MEMORY_READY_CPU : out std_logic;	
	
	-- Each chip does not have whole address bus, so several are addressed at once
	-- For reads not an issue, but for writes we need to only write to a single place!
		-- these all take 1 cycle, so fine to leave device selected in general
	GTIA_WR_ENABLE : OUT STD_LOGIC;
	POKEY_WR_ENABLE : OUT STD_LOGIC;
	POKEY2_WR_ENABLE : OUT STD_LOGIC;
	ANTIC_WR_ENABLE : OUT STD_LOGIC;
	PIA_WR_ENABLE : OUT STD_LOGIC;
	PIA_RD_ENABLE : OUT STD_LOGIC; -- ... except PIA takes action on reads!
	RAM_WR_ENABLE : OUT STD_LOGIC;	
	PBI_WR_ENABLE : OUT STD_LOGIC;
	D6_WR_ENABLE : OUT STD_LOGIC;
 	
	-- ROM and RAM have extended address busses to allow for bank switching etc.
	ROM_ADDR : OUT STD_LOGIC_VECTOR(21 downto 0);
	RAM_ADDR : OUT STD_LOGIC_VECTOR(18 downto 0);
	PBI_ADDR : out  std_logic_vector(15 downto 0);
	
	RAM_REQUEST : out std_logic;
	ROM_REQUEST : out std_logic;
	CART_REQUEST : out std_logic;
	
	CART_S4_n : out std_logic;
	CART_S5_n : out std_logic;
	CART_CCTL_n : out std_logic;

	CART_TRIG3_OUT: out std_logic;
	
	-- width of access
	WIDTH_8bit_ACCESS : out std_logic;
	WIDTH_16bit_ACCESS : out std_logic;
	WIDTH_32bit_ACCESS : out std_logic;
	
		-- interface as though SRAM - this module can take care of caching/write combining etc etc. For first cut... nothing. TODO: What extra info would help me here?
	SDRAM_ADDR : out std_logic_vector(22 downto 0); -- 1 extra bit for byte alignment
	SDRAM_READ_EN : out std_logic; -- if no reads pending may be a good time to do a refresh
	SDRAM_WRITE_EN : out std_logic;
	--SDRAM_REQUEST : out std_logic; -- Toggle this to issue a new request
	SDRAM_REQUEST : out std_logic; -- Usual pattern

	--SDRAM_REPLY : in std_logic; -- This matches the request once complete
	SDRAM_REQUEST_COMPLETE : in std_logic;
	SDRAM_DATA : in std_logic_vector(31 downto 0);
	
	WRITE_DATA : out std_logic_vector(31 downto 0);
	
	freezer_enable: in std_logic;
	freezer_activate: in std_logic;
	freezer_state_out: out std_logic_vector(2 downto 0);
	pbi_enable: in std_logic := '0'
);

END address_decoder;

ARCHITECTURE vhdl OF address_decoder IS
	signal ADDR_next : std_logic_vector(23 downto 0);
	signal ADDR_reg : std_logic_vector(23 downto 0);

	signal DATA_WRITE_next : std_logic_vector(31 downto 0);
	signal DATA_WRITE_reg : std_logic_vector(31 downto 0);
	
	signal width_8bit_next : std_logic;
	signal width_16bit_next : std_logic;
	signal width_32bit_next : std_logic;
	signal write_enable_next : std_logic;

	signal width_8bit_reg : std_logic;
	signal width_16bit_reg : std_logic;
	signal width_32bit_reg : std_logic;
	signal write_enable_reg : std_logic;
	
	signal request_complete : std_logic;
	signal notify_antic : std_logic;
	signal notify_DMA : std_logic;
	signal notify_cpu : std_logic;
	signal start_request : std_logic;
	
	signal extended_access_addr : std_logic;
	signal extended_access_cpu_or_antic : std_logic;
	signal extended_access_antic : std_logic;
	signal extended_access_cpu: std_logic; -- 130XE and compy shop switch antic seperately
	
	signal extended_access_either: std_logic; -- RAMBO switches both together using CPU bit

	signal extended_self_test : std_logic;
	signal extended_bank : std_logic_vector(8 downto 0); -- ONLY "000" - "103" valid...
	
	-- even though we have 3 targets (flash, ram, rom) and 3 masters, only allow access to one a a time - simpler.
	signal state_next : std_logic_vector(1 downto 0);
	signal state_reg : std_logic_vector(1 downto 0);
	constant state_idle : std_logic_vector(1 downto 0) := "00";
	constant state_waiting_cpu : std_logic_vector(1 downto 0) := "01";
	constant state_waiting_DMA : std_logic_vector(1 downto 0) := "10";
	constant state_waiting_antic : std_logic_vector(1 downto 0) := "11";
		
	signal ram_chip_select : std_logic;
	signal sdram_chip_select : std_logic;
	
--	signal sdram_request_next : std_logic;
--	signal sdram_request_reg : std_logic;
--	signal SDRAM_REQUEST_COMPLETE	: std_logic;
	
	signal fetch_priority : std_logic_vector(2 downto 0);
	
	signal fetch_wait_next : std_logic_vector(8 downto 0);
	signal fetch_wait_reg : std_logic_vector(8 downto 0);	
	
	signal antic_fetch_real_next : std_logic;
	signal antic_fetch_real_reg : std_logic;
	signal cpu_fetch_real_next : std_logic;
	signal cpu_fetch_real_reg : std_logic;

	signal SDRAM_CART_ADDR   : std_logic_vector(22 downto 0);
	signal SDRAM_BASIC_ROM_ADDR  : std_logic_vector(22 downto 0);
	signal SDRAM_OS_ROM_ADDR : std_logic_vector(22 downto 0);
	signal SDRAM_FREEZER_RAM_ADDR   : std_logic_vector(22 downto 0);
	signal SDRAM_FREEZER_ROM_ADDR   : std_logic_vector(22 downto 0);
	
	signal sdram_only_bank : std_logic;

	signal emu_cart_enable: std_logic;

	signal emu_cart_cctl_n: std_logic;
	signal emu_cart_data_in: std_logic_vector(7 downto 0);
	signal emu_cart_rw: std_logic;
	signal emu_cart_s4_n: std_logic;
	signal emu_cart_s5_n: std_logic;
	signal emu_cart_s4_n_out: std_logic;
	signal emu_cart_s5_n_out: std_logic;
	signal emu_cart_rd4: std_logic;
	signal emu_cart_rd5: std_logic;
	signal emu_cart_address: std_logic_vector(20 downto 0);
	signal emu_cart_address_enable: boolean;
	signal emu_cart_cctl_dout: std_logic_vector(7 downto 0);
	signal emu_cart_cctl_dout_enable: boolean;

	signal atari_clk_enable: std_logic;
	signal freezer_disable_atari: boolean;
	signal freezer_access_type: std_logic_vector(1 downto 0);
	signal freezer_access_address: std_logic_vector(16 downto 0);
	signal freezer_dout: std_logic_vector(7 downto 0);
	signal freezer_request: std_logic;
	signal freezer_request_complete: std_logic;
	signal freezer_activate_n: std_logic;
	
BEGIN
		-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			addr_reg <= (others=>'0');
			state_reg <= state_idle;
			width_8bit_reg <= '0';
			width_16bit_reg <= '0';
			width_32bit_reg <= '0';
			write_enable_reg <= '0';
			data_write_reg <= (others=> '0');
			--sdram_request_reg <= '0';
			fetch_wait_reg <= (others=>'0');

			cpu_fetch_real_reg <= '0';
			antic_fetch_real_reg <= '0';	
	elsif (clk'event and clk='1') then
			addr_reg <= addr_next;
			state_reg <= state_next;
			width_8bit_reg <= width_8bit_next;
			width_16bit_reg <= width_16bit_next;
			width_32bit_reg <= width_32bit_next;
			write_enable_reg <= write_enable_next;
			data_write_reg <= data_WRITE_next;
			--sdram_request_reg <= sdram_request_next;
			fetch_wait_reg <= fetch_wait_next;
			
			cpu_fetch_real_reg <= cpu_fetch_real_next;
			antic_fetch_real_reg <= antic_fetch_real_next;
		end if;
	end process;

	-- emulated cart
	atari_clk_enable <= notify_cpu or notify_antic; -- i.e. we enable cart and freezer on the final cycle of a 6502 or antic access
	emu_cart: entity work.CartLogic
	port map (clk => clk,
		clk_enable => atari_clk_enable,
		cart_mode => cart_select(5 downto 0),
		a => addr_next(12 downto 0),
		cctl_n => emu_cart_cctl_n,
		d_in => data_write_next(7 downto 0),
		rw => emu_cart_rw,
		s4_n => emu_cart_s4_n,
		s5_n => emu_cart_s5_n,
		s4_n_out => emu_cart_s4_n_out,
		s5_n_out => emu_cart_s5_n_out,
		rd4 => emu_cart_rd4,
		rd5 => emu_cart_rd5,
		cart_address => emu_cart_address,
		cart_address_enable => emu_cart_address_enable,
		cctl_dout => emu_cart_cctl_dout,
		cctl_dout_enable => emu_cart_cctl_dout_enable
	);

	process(cart_select)
	begin
		if (cart_select(5 downto 0) = "000000") then
			emu_cart_enable <= '0';
		else
			emu_cart_enable <= '1';
		end if;
	end process;

	-- freezer
	freezer_activate_n <= not (freezer_enable and freezer_activate);
	freezer: entity work.FreezerLogic
	port map(
		clk => clk,
		clk_enable => atari_clk_enable,
		a => addr_next(15 downto 0),
		d_in => data_write_next(7 downto 0),
		rw => not write_enable_next,
		reset_n => reset_n,
		activate_n => freezer_activate_n,
		dualpokey_n => '0',
		disable_atari => freezer_disable_atari,
		access_type => freezer_access_type,
		access_address => freezer_access_address,
		d_out => freezer_dout,
		request => freezer_request,
		request_complete => freezer_request_complete,
		state_out => freezer_state_out
	);

	-- use "real" cart as if it was stacked on top of the emulated cart
	--cart_s4_n <= emu_cart_s4_n_out;
	--cart_s5_n <= emu_cart_s5_n_out;

	CART_TRIG3_OUT <= (pbi_enable and CART_RD5) or emu_cart_rd5;
	
	-- ANTIC FETCH
	
	-- concept
	-- bus master sends request - antic or cpu
	-- antic has priority
	-- cpu may be idle
	-- once request complete MEMORY_READY is set
	-- if request interrupted then results are LOST - memory ready not set until priority request satisfied
	
	-- so
	-- memory_ready <= device_ready;
	
	-- problem
	-- request -> device access -> interrupt -> device finishes -> ignored? -> device access
	
	-- state machine
	
	-- state machine impl
	fetch_priority <= ANTIC_FETCH&DMA_FETCH&CPU_FETCH;
	process(fetch_wait_reg, state_reg, addr_reg, data_write_reg, width_8bit_reg, width_16bit_reg, width_32bit_reg, write_enable_reg, fetch_priority, antic_addr, DMA_addr, cpu_addr, request_complete, DMA_8bit_write_enable,DMA_16bit_write_enable,DMA_32bit_write_enable,DMA_read_enable, cpu_write_n, CPU_WRITE_DATA, DMA_WRITE_DATA, antic_fetch_real_reg, cpu_fetch_real_reg)
	begin
		start_request <= '0';
		notify_antic <= '0';
		notify_cpu <= '0';
		notify_DMA <= '0';
		state_next <= state_reg;
		fetch_wait_next <= std_logic_vector(unsigned(fetch_wait_reg) + to_unsigned(1,9));

		addr_next <= addr_reg;
		data_WRITE_next <= data_WRITE_reg;
		width_8bit_next <= width_8bit_reg;		
		width_16bit_next <= width_16bit_reg;		
		width_32bit_next <= width_32bit_reg;		
		write_enable_next <= write_enable_reg;
		
		antic_fetch_real_next <= antic_fetch_real_reg;
		cpu_fetch_real_next <= cpu_fetch_real_reg;
		
		case state_reg is
			when state_idle =>
				fetch_wait_next <= (others=>'0');
				write_enable_next <= '0';
				width_8bit_next <= '0';
				width_16bit_next <= '0';
				width_32bit_next <= '0';	
				data_WRITE_next <= (others => '0');
				addr_next <= DMA_ADDR(23 downto 16)&cpu_ADDR(15 downto 0);				
				
				case fetch_priority is
				when "100"|"101"|"110"|"111" => -- antic wins
					start_request <= '1';
					addr_next <= "00000000"&antic_ADDR;
					width_8bit_next <= '1';					
					if (request_complete = '1') then
						notify_antic <= '1';
					else
						state_next <= state_waiting_antic;
					end if;
					antic_fetch_real_next <= '1';
					cpu_fetch_real_next <= '0';
				when "010"|"011" => -- DMA wins (DMA usually accesses own ROM memory - this is NOT a DMA_fetch)
					-- TODO, lower priority than 6502, except on first request in block...
					start_request <= '1';
					addr_next <= DMA_ADDR;
					data_WRITE_next <= DMA_WRITE_DATA;

					width_8bit_next <= DMA_8BIT_WRITE_ENABLE or (DMA_READ_ENABLE and (DMA_addr(0) or DMA_addr(1)));
					width_16bit_next <= DMA_16BIT_WRITE_ENABLE;
					width_32bit_next <= DMA_32BIT_WRITE_ENABLE or (DMA_READ_ENABLE and not(DMA_addr(0) or DMA_addr(1))); -- narrower devices just return 8 bits on read
					
					write_enable_next <= not(DMA_READ_ENABLE);
					
					if (request_complete = '1') then
						notify_DMA <= '1';
					else
						state_next <= state_waiting_DMA;
					end if;					
				when "001" => -- 6502 wins
					start_request <= '1';
					addr_next <= "00000000"&cpu_ADDR;
					data_WRITE_next(7 downto 0) <= cpu_WRITE_DATA;
					width_8bit_next <= '1';
					write_enable_next <= not(cpu_WRITE_N);
					if (request_complete = '1') then
						notify_cpu <= '1';
					else
						state_next <= state_waiting_cpu;
					end if;
					cpu_fetch_real_next <= '1';
					antic_fetch_real_next <= '0';
				when "000" =>
					-- no requests
				when others =>
					-- nop
				end case;
			when state_waiting_antic =>
				if (request_complete = '1') then
					notify_antic <= '1';
					state_next <= state_idle;
				end if;
			when state_waiting_DMA =>
				if (request_complete = '1') then
					notify_DMA <= '1';
					state_next <= state_idle;
				end if;
			when state_waiting_cpu =>
				if (request_complete = '1') then
					notify_cpu <= '1';
					state_next <= state_idle;
				end if;				
			when others =>
				-- NOP
		end case;
	end process;
	
	-- output
	MEMORY_READY_ANTIC <= notify_antic;
	MEMORY_READY_DMA <= notify_DMA;
	MEMORY_READY_CPU <= notify_cpu;
	
	RAM_REQUEST <= ram_chip_select;
		
	SDRAM_REQUEST <= sdram_chip_select;
	--SDRAM_REQUEST <= sdram_request_next;
	SDRAM_READ_EN <= not(write_enable_next);
	SDRAM_WRITE_EN <= write_enable_next;
	
	WIDTH_8bit_ACCESS <= width_8bit_next;
	WIDTH_16bit_ACCESS <= width_16bit_next;
	WIDTH_32bit_ACCESS <= width_32bit_next;	
	
	WRITE_DATA <= DATA_WRITE_next;

	-- a little sdram glue - move to sdram wrapper? TODO
	--SDRAM_REQUEST_COMPLETE <= (SDRAM_REPLY xnor sdram_request_reg) and not(start_request);
	--sdram_request_next <= sdram_request_reg xor sdram_chip_select;	
	
	-- Calculate which memory area to use
	extended_access_addr <= addr_next(14) and not(addr_next(15)); --0x4000 to 0x7fff
	extended_access_cpu_or_antic <= extended_access_antic or extended_access_cpu;
	extended_access_antic <= (extended_access_addr and antic_fetch_real_next and not(portb(5)));
	extended_access_cpu <= (extended_access_addr and cpu_fetch_real_next and not(portb(4)));
	extended_access_either <= extended_access_addr and not(portb(4));
	sdram_only_bank <= or_reduce(extended_bank(8 downto 5));
	
	process(extended_access_cpu_or_antic,extended_access_either,extended_access_addr,addr_next,ram_select,portb)
	begin	
		extended_bank <= "0000000"&addr_next(15 downto 14);
		extended_self_test <= '1';
		
		case ram_select is
			when "000" => -- 64k
				-- default
			when "001" => -- 128k			
				if (extended_access_cpu_or_antic='1') then
					extended_bank(2 downto 0) <= '1'&portb(3 downto 2);
				end if;
			when "010" => -- 320k compy shop
				if (extended_access_cpu_or_antic='1') then
					extended_bank(4 downto 0) <= '1'&portb(7 downto 6)&portb(3 downto 2);
					extended_self_test <= '0';
				end if;
			when "011" => -- 320k rambo
				if (extended_access_either='1')then
					extended_bank(4 downto 0) <= '1'&portb(6 downto 5)&portb(3 downto 2);
				end if;
			when "100" => -- 576k compy shop
				if (extended_access_cpu_or_antic='1') then
					extended_bank(5 downto 0) <= '1'&portb(7 downto 6)&portb(3 downto 1);
					extended_self_test <= '0';
				end if;
			when "101" => -- 576k rambo
				if (extended_access_either='1') then
					extended_bank(5 downto 0) <= '1'&portb(6 downto 5)&portb(3 downto 1);
				end if;
			when "110" => -- 1088k rambo
				if (extended_access_either='1') then
					extended_bank(5 downto 0) <= portb(7 downto 5)&portb(3 downto 1);
					extended_bank(6) <= not(or_reduce(portb(7 downto 5)&portb(3)));
					extended_self_test <= '0';
				end if;
			when "111" => -- 4MB!	
				if (extended_access_addr='1') then
					extended_bank(7 downto 0) <= portb(7 downto 0);				
					extended_bank(8) <= not(or_reduce(portb(7 downto 2)));
					extended_self_test <= and_reduce(portb(6 downto 4));	 -- which means self-test is in the middle of half the banks - euuugh, oh well!						
				end if;
			when others =>
				-- TODO - portc!
		end case;
	end process;

gen_normal_memory : if low_memory=0 generate

	-- SRAM memory map (512k)
	-- base 64k RAM  - banks 0-3    "000 0000 1111 1111 1111 1111" (TOP)
	-- to 512k RAM   - banks 4-31   "000 0111 1111 1111 1111 1111" (TOP)
	-- SDRAM memory map (8MB)
	-- base 64k RAM  - banks 0-3    "000 0000 1111 1111 1111 1111" (TOP)
	-- to 512k RAM   - banks 4-31   "000 0111 1111 1111 1111 1111" (TOP) 
	-- to 4MB RAM    - banks 32-255 "011 1111 1111 1111 1111 1111" (TOP)
	-- +64k          - banks 256-259"100 0000 0000 1111 1111 1111" (TOP)
	-- SCRATCH       - 4MB+64k-5MB
	-- 128k freezer ram		"100 100Y YYYY YYYY YYYY YYYY"
	SDRAM_FREEZER_RAM_ADDR <= "100100" & freezer_access_address;
	-- 64k freezer rom		"100 1010 YYYY YYYY YYYY YYYY"
	SDRAM_FREEZER_ROM_ADDR <= "1001010" & freezer_access_address(15 downto 0);
	-- CARTS         -              "101 YYYY YYY0 0000 0000 0000" (BOT) - 2MB! 8kb banks
	--SDRAM_CART_ADDR      <= "101"&cart_select& "0000000000000";
	SDRAM_CART_ADDR	<= "1" & emu_cart_address(20) & (not emu_cart_address(20)) & emu_cart_address(19 downto 0);
	-- BASIC/OS ROM  -              "111 XXXX XX00 0000 0000 0000" (BOT) (BASIC IN SLOT 0!), 2nd to last 512K				
	SDRAM_BASIC_ROM_ADDR <= "111"&"000000"   &"00000000000000";
	SDRAM_OS_ROM_ADDR    <= "111"&"000001" &"00000000000000";
	-- SYSTEM        -              "111 1000 0000 0000 0000 0000" (BOT) - LAST 512K

end generate;

gen_low_memory1 : if low_memory=1 generate

	-- SRAM memory map (1024k) for Aeon lite 
	SDRAM_CART_ADDR      <= "0000" & "1"&emu_cart_address(17 downto 0); 
	SDRAM_BASIC_ROM_ADDR <= "000" & x"68000";
	SDRAM_OS_ROM_ADDR    <= "000" & x"6c000";
	SDRAM_FREEZER_RAM_ADDR <= "000" & "001" & freezer_access_address;
	SDRAM_FREEZER_ROM_ADDR <= "000" & x"7" & freezer_access_address(15 downto 0);

-- 0x10000-0x1FFFF (0x810000 in zpu space) = freeze backup - 64k
-- 0x20000-0x3FFFF (0x820000 in zpu space) = freezer ram (128k)
-- 0x40000-0x67FFF (0x840000 in zpu space) = carts - 160k
-- 0x48000-0x67FFF (0x848000 in zpu space) = directory cache - 128k
-- 0x68000-0x6FFFF (0x868000 in zpu space) = os rom/basic rom - 32k
-- 0x70000-0x7FFFF (0x870000 in zpu space) = freezer rom (64k)

end generate;

gen_low_memory2 : if low_memory=2 generate

	-- SRAM memory map (512k) for Papilio duo 
	SDRAM_CART_ADDR      <= "0000" & "01"&emu_cart_address(16 downto 0); 
	SDRAM_BASIC_ROM_ADDR <= "0000" & "0111000000000000000";
	SDRAM_OS_ROM_ADDR    <= "0000" & "0111100000000000000";

end generate;
	
  	process(
		-- address and writing absolutely points us at a device
		ADDR_next,WRITE_enable_next, 
	
		-- except for these additional special address bits	
		portb, 
		antic_fetch,
		ram_select,
		use_sdram,

		-- cart stuff
		cart_rd4,cart_rd5,
		emu_cart_rd4,emu_cart_rd5,

		emu_cart_enable,
		emu_cart_address, emu_cart_address_enable,
		emu_cart_cctl_dout, emu_cart_cctl_dout_enable,
		
		pbi_enable,
		
		-- input data from n sources
		GTIA_DATA,POKEY_DATA,POKEY2_DATA,PIA_DATA,ANTIC_DATA,CART_ROM_DATA,ROM_DATA,RAM_DATA,SDRAM_DATA,
		CACHE_GTIA_DATA,CACHE_POKEY_DATA,CACHE_POKEY2_DATA,CACHE_ANTIC_DATA,
		
		-- input data from n sources complete?
		-- hardware regs take 1 cycle, so always complete		
		ram_request_complete,sdram_request_complete,rom_request_complete,cart_request_complete,
		
		-- on new access this is set - we must select the appropriate device - for this cycle only
		start_request,
		
		rom_in_ram,
		
		-- SDRAM base addresses
		extended_self_test,extended_bank,sdram_only_bank,
		SDRAM_BASIC_ROM_ADDR,
		SDRAM_CART_ADDR,
		SDRAM_OS_ROM_ADDR,

		freezer_enable, freezer_disable_atari, freezer_access_type,
		freezer_dout, freezer_request_complete,
		SDRAM_FREEZER_RAM_ADDR, SDRAM_FREEZER_ROM_ADDR
		
	)
	begin
		MEMORY_DATA <= (others => '1');
		
		ROM_ADDR <= (others=>'0');
		RAM_ADDR <= addr_next(18 downto 0);
		SDRAM_ADDR <= addr_next(22 downto 0);
		
		PBI_ADDR <= ADDR_next(15 downto 0);
		
		request_complete <= '0';
		
		GTIA_WR_ENABLE <= '0';
		POKEY_WR_ENABLE <= '0';
		POKEY2_WR_ENABLE <= '0';
		ANTIC_WR_ENABLE <= '0';
		PIA_WR_ENABLE <= '0';
		PIA_RD_ENABLE <= '0';
		PBI_WR_ENABLE <= '0';
		D6_WR_ENABLE <= '0';

		RAM_WR_ENABLE <= write_enable_next;
		SDRAM_WRITE_EN <= write_enable_next;		
		
		CART_S4_n <= '1';
		CART_S5_n <= '1';
		CART_CCTL_n <= '1';

		emu_cart_s4_n <= '1';
		emu_cart_s5_n <= '1';

		emu_cart_cctl_n <= '1';

		if (write_enable_next = '1') then
			emu_cart_rw <= '0';
		else
			emu_cart_rw <= '1';
		end if;

		rom_request <= '0';
		cart_request <= '0';
		freezer_request <= '0';
		
		ram_chip_select <= '0';
		sdram_chip_select <= '0';
		
	--	if (addr_next(23 downto 17) = "0000000" ) then -- bit 16 left out on purpose, so the Atari 64k is available as 64k-128k for zpu. The zpu has rom at 0-64k...
		if (or_reduce(addr_next(23 downto 18)) = '0' ) then -- bit 16,17 left out on purpose, so the Atari 64k is available as 64k-128k for zpu. The zpu has rom at 0-64k...

		SDRAM_ADDR(13 downto 0) <= addr_next(13 downto 0);
		SDRAM_ADDR(22 downto 14) <= extended_bank;
		RAM_ADDR(13 downto 0) <= addr_next(13 downto 0);
		RAM_ADDR(18 downto 14) <= extended_bank(4 downto 0);
					
		if ((use_sdram or sdram_only_bank)='1') then
			MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
			sdram_chip_select <= start_request;
			request_complete <= sdram_request_COMPLETE;														
		else
			MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
			ram_chip_select <= start_request;
			request_complete <= ram_request_COMPLETE;									
		end if;
		
		if system=0 then
			case addr_next(15 downto 8) is 
				-- GTIA
				when X"D0" =>
					GTIA_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= GTIA_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_GTIA_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';
			
				-- POKEY
				when X"D2" =>				
					if (stereo=0 or addr_next(4) = '0') then
						POKEY_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= POKEY_DATA;
						MEMORY_DATA(15 downto 8) <= CACHE_POKEY_DATA;
					else
						POKEY2_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= POKEY2_DATA;
						MEMORY_DATA(15 downto 8) <= CACHE_POKEY2_DATA;
					end if;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';					

				-- PIA
				when X"D3" =>
					PIA_WR_ENABLE <= write_enable_next;
					PIA_RD_ENABLE <= '1';
					MEMORY_DATA(7 downto 0) <= PIA_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';					
					
				-- ANTIC
				when X"D4" =>
					ANTIC_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= ANTIC_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_ANTIC_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';					
					
				-- CART_CONFIG -- TODO - wait for n cycles (for now non-turbo mode should work?)
				when X"D5" =>
					sdram_chip_select <= '0';
					ram_chip_select <= '0';	

					if (emu_cart_enable = '1') then
						emu_cart_cctl_n <= '0';
						if write_enable_next = '1' then
							-- TODO: write to both emulated and real cart
							request_complete <= '1';
						else
							-- read only from emulated
							if emu_cart_cctl_dout_enable then
								MEMORY_DATA(7 downto 0) <= emu_cart_cctl_dout;
							else
								MEMORY_DATA(7 downto 0) <= x"ff";
							end if;
							request_complete <= '1';
						end if;
					else
						if (pbi_enable = '1') then
							PBI_WR_ENABLE <= write_enable_next;
							MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
							cart_request <= start_request;
							CART_CCTL_n <= '0';
							request_complete <= CART_REQUEST_COMPLETE;
						else
							MEMORY_DATA(7 downto 0) <= X"FF";
							request_complete <= '1';
						end if;
					end if;
					
				when X"D6" =>
					D6_WR_ENABLE <= write_enable_next;
					-- TODO - should this still have RAM with covox here?
										
				-- SELF TEST ROM 0x5000->0x57ff and XE RAM
				when 
					X"50"|X"51"|X"52"|X"53"|X"54"|X"55"|X"56"|X"57" =>
									
					if (portb(7) = '0' and portb(0) = '1' and extended_self_test = '1') then
						sdram_chip_select <= '0';
						ram_chip_select <= '0';	
						
						if (rom_in_ram = '1') then
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						else
							MEMORY_DATA(7 downto 0) <= ROM_DATA;						
						end if;
						
						if (write_enable_next = '1') then
							request_complete <= '1';
						else
							if (rom_in_ram = '1') then
								request_complete <= sdram_request_COMPLETE;							
								sdram_chip_select <= start_request;							
							else
								request_complete <= rom_request_COMPLETE;							
								rom_request <= start_request;															
							end if;
						end if;
						--ROM_ADDR <= "000000"&"00010"&ADDR(10 downto 0); -- x01000 based 2k (i.e. self test is 4k in - usually under hardware regs)
						SDRAM_ADDR <= SDRAM_OS_ROM_ADDR;
						SDRAM_ADDR(13 downto 0) <= "010"&ADDR_next(10 downto 0);
						ROM_ADDR <= "000000"&"00"&"010"&ADDR_next(10 downto 0); -- x01000 based 2k						
					end if;
				
				-- 0x80 cart
				when
					X"80"|X"81"|X"82"|X"83"|X"84"|X"85"|X"86"|X"87"|X"88"|X"89"|X"8A"|X"8B"|X"8C"|X"8D"|X"8E"|X"8F"
					|X"90"|X"91"|X"92"|X"93"|X"94"|X"95"|X"96"|X"97"|X"98"|X"99"|X"9A"|X"9B"|X"9C"|X"9D"|X"9E"|X"9F" =>
		
					if (emu_cart_enable = '1' and emu_cart_rd4 = '1') then
						emu_cart_s4_n <= '0';
						-- remap to SDRAM
						if (emu_cart_address_enable) then
							SDRAM_ADDR <= SDRAM_CART_ADDR;
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							request_complete <= sdram_request_COMPLETE;
							sdram_chip_select <= start_request;
							ram_chip_select <= '0';
						else
							MEMORY_DATA(7 downto 0) <= x"ff";
							request_complete <= '1';
							sdram_chip_select <= '0';
							ram_chip_select <= '0';
						end if;
					elsif (pbi_enable = '1' and cart_rd4 = '1') then
						PBI_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
						cart_request <= start_request;
						CART_S4_n <= '0';
						request_complete <= CART_REQUEST_COMPLETE;
						sdram_chip_select <= '0';
						ram_chip_select <= '0';							
					end if;	
			
				-- 0xa0 cart (BASIC ROM 0xa000 - 0xbfff (8k))
				when 
					X"A0"|X"A1"|X"A2"|X"A3"|X"A4"|X"A5"|X"A6"|X"A7"|X"A8"|X"A9"|X"AA"|X"AB"|X"AC"|X"AD"|X"AE"|X"AF"
					|X"B0"|X"B1"|X"B2"|X"B3"|X"B4"|X"B5"|X"B6"|X"B7"|X"B8"|X"B9"|X"BA"|X"BB"|X"BC"|X"BD"|X"BE"|X"BF" =>
					
					if (emu_cart_enable = '1' and emu_cart_rd5 = '1') then
						emu_cart_s5_n <= '0';
						-- remap to SDRAM
						if (emu_cart_address_enable) then
							SDRAM_ADDR <= SDRAM_CART_ADDR;
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							request_complete <= sdram_request_COMPLETE;							
							sdram_chip_select <= start_request;
							ram_chip_select <= '0';
						else
							MEMORY_DATA(7 downto 0) <= x"ff";
							request_complete <= '1';
							sdram_chip_select <= '0';
							ram_chip_select <= '0';
						end if;
					elsif (pbi_enable = '1' and cart_rd5 = '1') then
						PBI_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
						cart_request <= start_request;
						CART_S5_n <= '0';
						request_complete <= CART_REQUEST_COMPLETE;
						sdram_chip_select <= '0';
						ram_chip_select <= '0';													
					else
						if (portb(1) = '0') then
							sdram_chip_select <= '0';
							ram_chip_select <= '0';							
							--request_complete <= ROM_REQUEST_COMPLETE;
							--MEMORY_DATA(7 downto 0) <= ROM_DATA;
							--rom_request <= start_request;					
							if (rom_in_ram = '1') then
								MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							else
								MEMORY_DATA(7 downto 0) <= ROM_DATA;						
							end if;
							if (write_enable_next = '1') then
								request_complete <= '1';
							else
								if (rom_in_ram = '1') then
									request_complete <= sdram_request_COMPLETE;							
									sdram_chip_select <= start_request;							
								else
									request_complete <= rom_request_COMPLETE;							
									rom_request <= start_request;															
								end if;
							end if;
						
							ROM_ADDR <= "000000"&"110"&ADDR_next(12 downto 0); -- x0C000 based 8k
						 SDRAM_ADDR <= SDRAM_BASIC_ROM_ADDR;
						 SDRAM_ADDR(12 downto 0) <= ADDR_next(12 downto 0); -- x0C000 based 8k							
						end if;
					end if;
					
				-- OS ROM 0xc00->0xcff				
				-- OS ROM d800->0xfff
				when 
					X"C0"|X"C1"|X"C2"|X"C3"|X"C4"|X"C5"|X"C6"|X"C7"|X"C8"|X"C9"|X"CA"|X"CB"|X"CC"|X"CD"|X"CE"|X"CF"
					|X"D8"|X"D9"|X"DA"|X"DB"|X"DC"|X"DD"|X"DE"|X"DF"
					|X"E0"|X"E1"|X"E2"|X"E3"|X"E4"|X"E5"|X"E6"|X"E7"|X"E8"|X"E9"|X"EA"|X"EB"|X"EC"|X"ED"|X"EE"|X"EF"
					|X"F0"|X"F1"|X"F2"|X"F3"|X"F4"|X"F5"|X"F6"|X"F7"|X"F8"|X"F9"|X"FA"|X"FB"|X"FC"|X"FD"|X"FE"|X"FF" =>
					
					if (portb(0) = '1') then
						sdram_chip_select <= '0';
						ram_chip_select <= '0';																		
						--request_complete <= ROM_REQUEST_COMPLETE;
						--MEMORY_DATA(7 downto 0) <= ROM_DATA;
						--rom_request <= start_request;					
						if (rom_in_ram = '1') then
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						else
							MEMORY_DATA(7 downto 0) <= ROM_DATA;						
						end if;
						if (write_enable_next = '1') then
							request_complete <= '1';
						else
								if (rom_in_ram = '1') then
									request_complete <= sdram_request_COMPLETE;							
									sdram_chip_select <= start_request;							
								else
									request_complete <= rom_request_COMPLETE;							
									rom_request <= start_request;															
								end if;						
						end if;																			

						ROM_ADDR <= "000000"&"00"&ADDR_next(13 downto 0); -- x00000 based 16k
						SDRAM_ADDR <= SDRAM_OS_ROM_ADDR;
						SDRAM_ADDR(13 downto 0) <= ADDR_next(13 downto 0);
					end if;
					
				when others =>
			end case;

			-- Freezer overrides bus!
			if (freezer_enable = '1' and freezer_disable_atari) then
				sdram_chip_select <= '0';
				ram_chip_select <= '0';
				case freezer_access_type is
				when "01" => -- direct data access
					memory_data(7 downto 0) <= freezer_dout;
					freezer_request <= start_request;
					request_complete <= freezer_request_complete;
				when "10" => -- ram access
					SDRAM_ADDR <= SDRAM_FREEZER_RAM_ADDR;
					MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
					request_complete <= sdram_request_COMPLETE;
					sdram_chip_select <= start_request;
				when "11" => -- ram access
					SDRAM_ADDR <= SDRAM_FREEZER_ROM_ADDR;
					MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
					request_complete <= sdram_request_COMPLETE;
					sdram_chip_select <= start_request;
				when others => null;
					MEMORY_DATA(7 downto 0) <= (others => '1');
					request_complete <= '1';
				end case;
			end if;
		end if;

	 	if system=10 then
		case addr_next(15 downto 8) is 
				-- GTIA
				when 	X"c0"|X"c1"|X"c2"|X"c3"|X"c4"|X"c5"|X"c6"|X"c7"|
					X"c8"|X"c9"|X"ca"|X"cb"|X"cc"|X"cd"|X"ce"|X"cf" =>
					GTIA_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= GTIA_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_GTIA_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';
			
				-- POKEY
				when
					X"e8"|X"e9"|X"ea"|X"eb"|X"ec"|X"ed"|X"ee"|X"ef" =>
					POKEY_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= POKEY_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_POKEY_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';					

				-- ANTIC
				when X"D4" =>
					ANTIC_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= ANTIC_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_ANTIC_DATA;
					request_complete <= '1';
					sdram_chip_select <= '0';
					ram_chip_select <= '0';					
					
				-- CART_CONFIG -- TODO - wait for n cycles (for now non-turbo mode should work?)
				when
					X"40"|X"41"|X"42"|X"43"|X"44"|X"45"|X"46"|X"47"|
					X"48"|X"49"|X"4A"|X"4B"|X"4C"|X"4D"|X"4E"|X"4F"|
					X"50"|X"51"|X"52"|X"53"|X"54"|X"55"|X"56"|X"57"|
					X"58"|X"59"|X"5A"|X"5B"|X"5C"|X"5D"|X"5E"|X"5F"|
					X"60"|X"61"|X"62"|X"63"|X"64"|X"65"|X"66"|X"67"|
					X"68"|X"69"|X"6A"|X"6B"|X"6C"|X"6D"|X"6E"|X"6F"|
					X"70"|X"71"|X"72"|X"73"|X"74"|X"75"|X"76"|X"77"|
					X"78"|X"79"|X"7A"|X"7B"|X"7C"|X"7D"|X"7E"|X"7F" =>

					if (write_enable_next = '1') then
						sdram_chip_select <= '0';
						Ram_chip_select <= '0';							
						MEMORY_DATA(7 downto 0) <= X"FF";
						Request_complete <= '1';
					end if;
			--		if (cart_rd4 = '1') then
			--			MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
			--			rom_request <= start_request;
			--			CART_S4_n <= '0';
			--			request_complete <= CART_REQUEST_COMPLETE;
			--			sdram_chip_select <= '0';
			--			ram_chip_select <= '0';							
			--		else
			--			MEMORY_DATA(7 downto 0) <= X"FF";
			--			request_complete <= '1';
			--		end if;

				when
					X"80"|X"81"|X"82"|X"83"|X"84"|X"85"|X"86"|X"87"|
					X"88"|X"89"|X"8A"|X"8B"|X"8C"|X"8D"|X"8E"|X"8F"|
					X"90"|X"91"|X"92"|X"93"|X"94"|X"95"|X"96"|X"97"|
					X"98"|X"99"|X"9A"|X"9B"|X"9C"|X"9D"|X"9E"|X"9F"|
					X"a0"|X"a1"|X"a2"|X"a3"|X"a4"|X"a5"|X"a6"|X"a7"|
					X"a8"|X"a9"|X"aA"|X"aB"|X"aC"|X"aD"|X"aE"|X"aF"|
					X"b0"|X"b1"|X"b2"|X"b3"|X"b4"|X"b5"|X"b6"|X"b7"|
					X"b8"|X"b9"|X"bA"|X"bB"|X"bC"|X"bD"|X"bE"|X"bF" =>

					if (write_enable_next = '1') then
						sdram_chip_select <= '0';
						Ram_chip_select <= '0';							
						MEMORY_DATA(7 downto 0) <= X"FF";
						Request_complete <= '1';
					end if;
		
			--		if (cart_rd5 = '1') then
			--			MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
			--			rom_request <= start_request;
			--			CART_S4_n <= '0';
			--			request_complete <= CART_REQUEST_COMPLETE;
			--			sdram_chip_select <= '0';
			--			ram_chip_select <= '0';							
			--		else
			--			MEMORY_DATA(7 downto 0) <= X"FF";
			--			request_complete <= '1';
			--		end if;
			
				-- OS ROM f000->0xfff
				when 
					X"F0"|X"F1"|X"F2"|X"F3"|X"F4"|X"F5"|X"F6"|X"F7"|X"F8"|X"F9"|X"FA"|X"FB"|X"FC"|X"FD"|X"FE"|X"FF" =>
					
					sdram_chip_select <= '0';
					ram_chip_select <= '0';																		
					--request_complete <= ROM_REQUEST_COMPLETE;
					--MEMORY_DATA(7 downto 0) <= ROM_DATA;
					--rom_request <= start_request;					
					if (rom_in_ram = '1') then
						MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
					else
						MEMORY_DATA(7 downto 0) <= ROM_DATA;						
					end if;
					if (write_enable_next = '1') then
						request_complete <= '1';
					else
							if (rom_in_ram = '1') then
								request_complete <= sdram_request_COMPLETE;							
								sdram_chip_select <= start_request;							
							else
								request_complete <= rom_request_COMPLETE;							
								rom_request <= start_request;															
							end if;						
					end if;																			

					ROM_ADDR <= "000000"&"0000"&ADDR_next(11 downto 0); -- x00000 based 4k
					SDRAM_ADDR <= SDRAM_OS_ROM_ADDR;
					SDRAM_ADDR(11 downto 0) <= ADDR_next(11 downto 0);

				when
					X"d0"|X"d1"|X"d2"|X"d3"|
					X"d5"|X"d6"|X"d7"|X"d8"|X"d9"|X"dA"|X"dB"|X"dC"|X"dD"|X"dE"|X"dF"|
					X"E0"|X"E1"|X"E2"|X"E3"|X"E4"|X"E5"|X"E6"|X"E7" =>

					MEMORY_DATA(7 downto 0) <= X"00";
					request_complete <= '1';
					
				when others =>
			end case;				
		end if;
		else		
			sdram_chip_select <= '0';
			ram_chip_select <= '0';													
			case addr_next(23 downto 21) is			
				when "000" =>				
					-- internal area for zpu, never happens!
				when "001" => -- sram, 512K
					MEMORY_DATA(15 downto 0) <= RAM_DATA;
					ram_chip_select <= start_request;
					request_complete <= ram_request_COMPLETE;									
					RAM_ADDR <= addr_next(18 downto 0);

				when "010"|"011" => -- flash rom, 4MB
					request_complete <= ROM_REQUEST_COMPLETE;
					MEMORY_DATA(7 downto 0) <= ROM_DATA;
					rom_request <= start_request;
					ROM_ADDR <= addr_next(21 downto 0);
					
				when "100"|"101"|"110"|"111" => -- sdram, 8MB
					MEMORY_DATA <= SDRAM_DATA;
					sdram_chip_select <= start_request;
					request_complete <= sdram_request_COMPLETE;	
					SDRAM_ADDR <= addr_next(22 downto 0);				
				when others =>
					-- NOP
			end case;
		end if;
		
	end process;
END vhdl;
