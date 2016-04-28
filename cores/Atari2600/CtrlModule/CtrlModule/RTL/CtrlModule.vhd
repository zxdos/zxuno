-- Retro Ramblings Control Module
-- https://github.com/robinsonb5/CtrlModuleTutorial
--
-- Merged with TCA2600 project for the ZXUNO
-- 2016 DistWave

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.zpupkg.ALL;

entity CtrlModule is
	generic (
		sysclk_frequency : integer := 575  -- Sysclk frequency * 10 
	);
	port (
		clk 			: in std_logic;
		reset_n 	: in std_logic;

		-- Video signals for OSD
		vga_hsync : in std_logic;
		vga_vsync : in std_logic;
		osd_window : out std_logic;
		osd_pixel : out std_logic;

		-- PS/2 keyboard
		ps2k_clk_in : in std_logic := '1';
		ps2k_dat_in : in std_logic := '1';

		-- SD card interface
		spi_miso		: in std_logic := '1';
		spi_mosi		: out std_logic;
		spi_clk		: out std_logic;
		spi_cs 		: out std_logic;

		-- DIP switches
		dipswitches : out std_logic_vector(15 downto 0);
		size : out std_logic_vector(15 downto 0);
		
		-- Host control signals
		host_divert_sdcard : out std_logic;
		host_divert_keyboard : out std_logic;
		host_reset_n : out std_logic;
		host_select : out std_logic;
		host_start : out std_logic;
		
		-- Boot upload signals
		host_bootdata : out std_logic_vector(31 downto 0);
		host_bootdata_req : out std_logic;
		host_bootdata_ack : in std_logic :='0'
	);
end entity;

architecture rtl of CtrlModule is

-- ZPU signals
constant maxAddrBit : integer := 20; -- Optional - defaults to 32 - but helps keep the logic element count down.
signal mem_busy           : std_logic;
signal mem_read             : std_logic_vector(wordSize-1 downto 0);
signal mem_write            : std_logic_vector(wordSize-1 downto 0);
signal mem_addr             : std_logic_vector(maxAddrBit downto 0);
signal mem_writeEnable      : std_logic; 
signal mem_readEnable       : std_logic;
signal mem_hEnable      : std_logic; 
signal mem_bEnable      : std_logic; 

signal zpu_to_rom : ZPU_ToROM;
signal zpu_from_rom : ZPU_FromROM;


-- OSD related signals

signal osd_wr : std_logic;
signal osd_charwr : std_logic;
signal osd_char_q : std_logic_vector(7 downto 0);
signal osd_data : std_logic_vector(15 downto 0);
signal vblank : std_logic;


-- PS/2 related signals

signal ps2_int : std_logic;

signal kbdrecv : std_logic;
signal kbdrecvreg : std_logic;
signal kbdrecvbyte : std_logic_vector(10 downto 0);


-- Interrupt signals

constant int_max : integer := 2;
signal int_triggers : std_logic_vector(int_max downto 0);
signal int_status : std_logic_vector(int_max downto 0);
signal int_ack : std_logic;
signal int_req : std_logic;
signal int_enabled : std_logic :='0'; -- Disabled by default


-- SPI Clock counter
signal spi_tick : unsigned(8 downto 0);
signal spiclk_in : std_logic;
signal spi_fast : std_logic;

-- SPI signals
signal host_to_spi : std_logic_vector(7 downto 0);
signal spi_to_host : std_logic_vector(7 downto 0);
signal spi_trigger : std_logic;
signal spi_busy : std_logic;
signal spi_active : std_logic;

begin

-- ROM

	myrom : entity work.CtrlROM_ROM
	generic map
	(
		maxAddrBitBRAM => 13
	)
	port map (
		clk => clk,
		from_zpu => zpu_to_rom,
		to_zpu => zpu_from_rom
	);

	
-- Main CPU
-- We instantiate the CPU with the optional instructions enabled, which allows us to reduce
-- the size of the ROM by leaving out emulation code.
	zpu: zpu_core_flex
	generic map (
		IMPL_MULTIPLY => true,
		IMPL_COMPARISON_SUB => true,
		IMPL_EQBRANCH => true,
		IMPL_STOREBH => true,
		IMPL_LOADBH => true,
		IMPL_CALL => true,
		IMPL_SHIFT => true,
		IMPL_XOR => true,
		CACHE => true,	-- Modest speed-up when running from ROM
--		IMPL_EMULATION => minimal, -- Emulate only byte/halfword accesses, with alternateive emulation table
		REMAP_STACK => false, -- We're not using SDRAM so no need to remap the Boot ROM / Stack RAM
		EXECUTE_RAM => false, -- We don't need to execute code from external RAM.
		maxAddrBit => maxAddrBit,
		maxAddrBitBRAM => 13
	)
	port map (
		clk                 => clk,
		reset               => not reset_n,
		in_mem_busy         => mem_busy,
		mem_read            => mem_read,
		mem_write           => mem_write,
		out_mem_addr        => mem_addr,
		out_mem_writeEnable => mem_writeEnable,
		out_mem_hEnable     => mem_hEnable,
		out_mem_bEnable     => mem_bEnable,
		out_mem_readEnable  => mem_readEnable,
		from_rom => zpu_from_rom,
		to_rom => zpu_to_rom,
		interrupt => int_req
	);


-- OSD

myosd : entity work.OnScreenDisplay
port map(
	reset_n => reset_n,
	clk => clk,
	-- Video
	hsync_n => vga_hsync,
	vsync_n => vga_vsync,
	vblank => vblank,
	pixel => osd_pixel,
	window => osd_window,
	-- Registers
	addr => mem_addr(8 downto 0),	-- low 9 bits of address
	data_in => mem_write(15 downto 0),
	data_out => osd_data(15 downto 0),
	reg_wr => osd_wr,			-- Trigger a write to the control registers
	char_wr => osd_charwr,	-- Trigger a write to the character RAM
	char_q => osd_char_q		-- Data from the character RAM
);


-- PS2 keyboard
mykeyboard : entity work.io_ps2_com
generic map (
	clockFilter => 15,
	ticksPerUsec => sysclk_frequency/10
)
port map (
	clk => clk,
	reset => not reset_n, -- active high!
	ps2_clk_in => ps2k_clk_in,
	ps2_dat_in => ps2k_dat_in,
	
	inIdle => open,
	sendTrigger => '0',
	sendByte => (others=>'X'),
	sendBusy => open,
	sendDone => open,
	recvTrigger => kbdrecv,
	recvByte => kbdrecvbyte
);


-- SPI Timer
process(clk)
begin
	if rising_edge(clk) then
		spiclk_in<='0';
		spi_tick<=spi_tick+1;
		if (spi_fast='1' and spi_tick(5)='1') or spi_tick(8)='1' then
			spiclk_in<='1'; -- Momentary pulse for SPI host.
			spi_tick<='0'&X"00";
		end if;
	end if;
end process;


-- SD Card host

spi : entity work.spi_interface
	port map(
		sysclk => clk,
		reset => reset_n,

		-- Host interface
		spiclk_in => spiclk_in,
		host_to_spi => host_to_spi,
		spi_to_host => spi_to_host,
		trigger => spi_trigger,
		busy => spi_busy,

		-- Hardware interface
		miso => spi_miso,
		mosi => spi_mosi,
		spiclk_out => spi_clk
	);

		
-- Interrupt controller

intcontroller: entity work.interrupt_controller
generic map (
	max_int => int_max
)
port map (
	clk => clk,
	reset_n => reset_n,
	enable => int_enabled,
	trigger => int_triggers,
	ack => int_ack,
	int => int_req,
	status => int_status
);

int_triggers<=(0=>kbdrecv,
					1=>vblank,
					others => '0');
	
process(clk,reset_n)
begin
	if reset_n='0' then
		int_enabled<='0';
		kbdrecvreg <='0';
		host_reset_n <='0';
		host_bootdata_req<='0';
		spi_active<='0';
		spi_cs<='1';
	elsif rising_edge(clk) then
		mem_busy<='1';
		osd_charwr<='0';
		osd_wr<='0';
		int_ack<='0';
		spi_trigger<='0';

		-- Write from CPU?
		if mem_writeEnable='1' then
			case mem_addr(maxAddrBit)&mem_addr(10 downto 8) is
				when X"B" =>	-- OSD controller at 0xFFFFFB00
					osd_wr<='1';
					mem_busy<='0';
				when X"C" =>	-- OSD controller at 0xFFFFFC00 & 0xFFFFFD00
					osd_charwr<='1';
					mem_busy<='0';
				when X"D" =>	-- OSD controller at 0xFFFFFC00 & 0xFFFFFD00
					osd_charwr<='1';
					mem_busy<='0';

				when X"F" =>	-- Peripherals at 0xFFFFFF00
					case mem_addr(7 downto 0) is

						when X"B0" => -- Interrupts
							int_enabled<=mem_write(0);
							mem_busy<='0';

						when X"D0" => -- SPI CS
							spi_cs<=not mem_write(0);
							spi_fast<=mem_write(8);
							mem_busy<='0';

						when X"D4" => -- SPI Data (blocking)
							spi_trigger<='1';
							host_to_spi<=mem_write(7 downto 0);
							spi_active<='1';

						when X"E8" => -- Host boot data
							-- Note that we don't clear mem_busy here; it's set instead when the ack signal comes in.
							host_bootdata<=mem_write;
							host_bootdata_req<='1';

						when X"EC" => -- Host control
							mem_busy<='0';
							host_reset_n<=not mem_write(0);
							host_divert_keyboard<=mem_write(1);
							host_divert_sdcard<=mem_write(2);
							host_select<=mem_write(3);
							host_start<=mem_write(4);
							
						when X"F8" => -- ROM Size
							mem_busy<='0';
							size<=mem_write(15 downto 0);
							
						when X"FC" => -- Host SW
							mem_busy<='0';
							dipswitches<=mem_write(15 downto 0);

						when others =>
							mem_busy<='0';
							null;
					end case;
				when others =>
					mem_busy<='0';
			end case;

		-- Read from CPU?
		elsif mem_readEnable='1' then
			case mem_addr(maxAddrBit)&mem_addr(10 downto 8) is
				when X"B" =>	-- OSD registers
					mem_read(31 downto 16)<=(others => '0');
					mem_read(15 downto 0)<=osd_data;
					mem_busy<='0';
				when X"C" =>	-- OSD controller at 0xFFFFFC00 & 0xFFFFFD00
					mem_read(31 downto 8)<=(others => 'X');
					mem_read(7 downto 0)<=osd_char_q;
					mem_busy<='0';
				when X"D" =>	-- OSD controller at 0xFFFFFC00 & 0xFFFFFD00
					mem_read(31 downto 8)<=(others => 'X');
					mem_read(7 downto 0)<=osd_char_q;
					mem_busy<='0';
				when X"F" =>	-- Peripherals
					case mem_addr(7 downto 0) is
					
						when X"B0" => -- Read from Interrupt status register
							mem_read<=(others=>'X');
							mem_read(int_max downto 0)<=int_status;
							int_ack<='1';
							mem_busy<='0';

						when X"D0" => -- SPI Status
							mem_read<=(others=>'X');
							mem_read(15)<=spi_busy;
							mem_busy<='0';

						when X"D4" => -- SPI read (blocking)
							spi_active<='1';
							
						when X"E0" =>	-- Read from PS/2 regs

							mem_read<=(others =>'X');
							mem_read(11 downto 0)<=kbdrecvreg & '1' & kbdrecvbyte(10 downto 1);
							kbdrecvreg<='0';
							mem_busy<='0';
						when others =>
							mem_busy<='0';
							null;
					end case;

				when others => 
					mem_busy<='0';
			end case;
		end if;

		-- Boot data termination - allow CPU to proceed once boot data is acknowleged:
		if host_bootdata_ack='1' then
			mem_busy<='0';
			host_bootdata_req<='0';
		end if;

		
		-- SPI cycle termination
		if spi_active='1' and spi_busy='0' then
			mem_read(7 downto 0)<=spi_to_host;
			mem_read(31 downto 8)<=(others => '0');
			spi_active<='0';
			mem_busy<='0';
		end if;
		

		if kbdrecv='1' then
			kbdrecvreg <= '1'; -- remains high until cleared by a read
		end if;
		
	end if; -- rising-edge(clk)

end process;
	
end architecture;
