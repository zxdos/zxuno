---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use IEEE.STD_LOGIC_MISC.all;
use ieee.numeric_std.all;

LIBRARY work;
-- Simple version that:
-- i) needs: CLK(58 or 28MHZ) SDRAM,joystick,keyboard
-- ii) provides: VIDEO,AUDIO
-- iii) passes upstream: DMA port, for attaching ZPU for SDCARD/drive emulation

-- THIS SHOULD DO FOR ALL PLATFORMS EXCEPT THOSE USING GPIO FOR PBI etc

ENTITY atari800core_simple_sdram is
	GENERIC
	(
		-- use CLK of 1.79*cycle_length
		-- I've tested 16 and 32 only, but 4 and 8 might work...
		cycle_length : integer := 16; -- or 32...

		-- how many bits for video
		video_bits : integer := 8;
		palette : integer :=1; -- 0:gtia colour on VIDEO_B, 1:altirra, 2:laoo
	
		-- For initial port may help to have no
		internal_rom : integer := 1;  -- if 0 expects it in sdram,is 1:16k os+basic, is 2:... TODO
		internal_ram : integer := 16384;  -- at start of memory map
	
		-- Use 1MB memory map if low memory set (for Aeon lite)
		low_memory : integer := 0;

		-- one or two pokey chips
		stereo : integer := 1;

		-- resistor ladder style 8-bit sample thing
		covox : integer := 1
	);
	PORT
	(
		CLK :  IN  STD_LOGIC; -- cycle_length*1.79MHz
		RESET_N : IN STD_LOGIC;

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS :  OUT  STD_LOGIC;
		VIDEO_HS :  OUT  STD_LOGIC;
		VIDEO_CS :  OUT  STD_LOGIC;
		VIDEO_B :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_G :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_R :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
			-- These ones are probably only needed for e.g. svideo
		VIDEO_BLANK : out std_logic;
		VIDEO_BURST : out std_logic;
		VIDEO_START_OF_FIELD : out std_logic;
		VIDEO_ODD_LINE : out std_logic;

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L : OUT std_logic_vector(15 downto 0);
		AUDIO_R : OUT std_logic_vector(15 downto 0);

		-- JOYSTICK
		JOY1_n : IN std_logic_vector(4 downto 0); -- FRLDU, 0=pressed
		JOY2_n : IN std_logic_vector(4 downto 0); -- FRLDU, 0=pressed
		PADDLE0 : IN signed(7 downto 0) := to_signed(-128,8);
		PADDLE1 : IN signed(7 downto 0) := to_signed(-128,8);
		PADDLE2 : IN signed(7 downto 0) := to_signed(-128,8);
		PADDLE3 : IN signed(7 downto 0) := to_signed(-128,8);

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		KEYBOARD_SCAN : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

		-- SIO
		SIO_COMMAND : out std_logic;
		SIO_RXD : in std_logic;
		SIO_TXD : out std_logic;

		-- GTIA consol
		CONSOL_OPTION : IN STD_LOGIC;
		CONSOL_SELECT : IN STD_LOGIC;
		CONSOL_START : IN STD_LOGIC;

		-----------------------
		-- After here all FPGA implementation specific
		-- e.g. need to write up RAM/ROM
		-- we can dma from memory space
		-- etc.

		-- External RAM/ROM - adhere to standard memory map
		-- TODO - lower/upper memory split defined by generic
		-- (TODO SRAM lower ram, SDRAM upper ram - no overlap?)
		---- SDRAM memory map (8MB) (lower 512k if USE_SDRAM=1)
		---- base 64k RAM  - banks 0-3    "000 0000 1111 1111 1111 1111" (TOP)
		---- to 512k RAM   - banks 4-31   "000 0111 1111 1111 1111 1111" (TOP) 
		---- to 4MB RAM    - banks 32-255 "011 1111 1111 1111 1111 1111" (TOP)
		---- +64k          - banks 256-259"100 0000 0000 1111 1111 1111" (TOP)
		---- SCRATCH       - 4MB+64k-5MB
		---- CARTS         -              "101 YYYY YYY0 0000 0000 0000" (BOT) - 2MB! 8kb banks
		--SDRAM_CART_ADDR      <= "101"&cart_select& "0000000000000";
		---- BASIC/OS ROM  -              "111 XXXX XX00 0000 0000 0000" (BOT) (BASIC IN SLOT 0!), 2nd to last 512K				
		--SDRAM_BASIC_ROM_ADDR <= "111"&"000000"   &"00000000000000";
		--SDRAM_OS_ROM_ADDR    <= "111"&rom_select &"00000000000000";
		---- SYSTEM        -              "111 1000 0000 0000 0000 0000" (BOT) - LAST 512K
		-- TODO - review if we need to pass out so many of these
		-- Perhaps we can simplify address decoder and have an external layer?
		SDRAM_REQUEST : OUT std_logic;
		SDRAM_REQUEST_COMPLETE : IN std_logic;
		SDRAM_READ_ENABLE : out STD_LOGIC;
		SDRAM_WRITE_ENABLE : out std_logic;
		SDRAM_ADDR : out STD_LOGIC_VECTOR(22 DOWNTO 0);
		SDRAM_DO : in STD_LOGIC_VECTOR(31 DOWNTO 0);
		SDRAM_DI : out STD_LOGIC_VECTOR(31 DOWNTO 0);
		SDRAM_32BIT_WRITE_ENABLE : out std_logic;
		SDRAM_16BIT_WRITE_ENABLE : out std_logic;
		SDRAM_8BIT_WRITE_ENABLE : out std_logic;
		SDRAM_REFRESH : out std_logic;

		-- DMA memory map differs
		-- e.g. some special addresses to read behind hardware registers
		-- 0x0000-0xffff: Atari registers + 3 mirrors (bit 16/17)
		-- 23 downto 21:
		-- 001 : SRAM,512k
		-- 010|011 : ROM, 4MB
		-- 10xx : SDRAM, 8MB (If you have more, its unmapped for now... Can bank switch! Atari can't access this much anyway...)
		DMA_FETCH : in STD_LOGIC; -- we want to read/write
		DMA_READ_ENABLE : in std_logic;
		DMA_32BIT_WRITE_ENABLE : in std_logic;
		DMA_16BIT_WRITE_ENABLE : in std_logic;
		DMA_8BIT_WRITE_ENABLE : in std_logic;
		DMA_ADDR : in std_logic_vector(23 downto 0);
		DMA_WRITE_DATA : in std_logic_vector(31 downto 0);
		MEMORY_READY_DMA : out std_logic; -- op complete
		DMA_MEMORY_DATA : out std_logic_vector(31 downto 0);

		-- Special config params
   		RAM_SELECT : in std_logic_vector(2 downto 0); -- 64K,128K,320KB Compy, 320KB Rambo, 576K Compy, 576K Rambo, 1088K, 4MB
		PAL :  in STD_LOGIC;
		HALT : in std_logic;
		THROTTLE_COUNT_6502 : in std_logic_vector(5 downto 0); -- standard speed is cycle_length-1
		emulated_cartridge_select: in std_logic_vector(5 downto 0);
		freezer_enable: in std_logic := '0';
		freezer_activate: in std_logic := '0'
	);
end atari800core_simple_sdram;

ARCHITECTURE vhdl OF atari800core_simple_sdram IS 
	-- PIA
	SIGNAL	CA1_IN :  STD_LOGIC;
	SIGNAL	CB1_IN:  STD_LOGIC;
	SIGNAL	CA2_OUT :  STD_LOGIC;
	SIGNAL	CA2_DIR_OUT:  STD_LOGIC;
	SIGNAL	CB2_OUT :  STD_LOGIC;
	SIGNAL	CB2_DIR_OUT:  STD_LOGIC;
	SIGNAL	CA2_IN:  STD_LOGIC;
	SIGNAL	CB2_IN:  STD_LOGIC;
	SIGNAL	PORTA_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTA_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTA_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTB_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTB_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	--SIGNAL	PORTB_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- GTIA
	signal GTIA_TRIG : std_logic_vector(3 downto 0);
	
	-- ANTIC
	signal ANTIC_LIGHTPEN : std_logic;
	
	-- CARTRIDGE ACCESS
	SIGNAL	CART_RD4 :  STD_LOGIC;
	SIGNAL	CART_RD5 :  STD_LOGIC;
	
	-- PBI
	SIGNAL PBI_WRITE_DATA : std_logic_vector(31 downto 0);
	
	-- INTERNAL ROM/RAM
	SIGNAL	RAM_ADDR :  STD_LOGIC_VECTOR(18 DOWNTO 0);
	SIGNAL	RAM_DO :  STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	RAM_REQUEST :  STD_LOGIC;
	SIGNAL	RAM_REQUEST_COMPLETE :  STD_LOGIC;
	SIGNAL	RAM_WRITE_ENABLE :  STD_LOGIC;
	
	SIGNAL	ROM_ADDR :  STD_LOGIC_VECTOR(21 DOWNTO 0);
	SIGNAL	ROM_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	ROM_REQUEST :  STD_LOGIC;
	SIGNAL	ROM_REQUEST_COMPLETE :  STD_LOGIC;
	
	-- CONFIG
	SIGNAL USE_SDRAM : STD_LOGIC;
	SIGNAL ROM_IN_RAM : STD_LOGIC;

	-- POTS
	SIGNAL POT_RESET : STD_LOGIC;
	SIGNAL POT_IN : STD_LOGIC_VECTOR(7 downto 0);

BEGIN

-- PIA mapping
CA1_IN <= '1';
CB1_IN <= '1';
CA2_IN <= CA2_OUT when CA2_DIR_OUT='1' else '1';
CB2_IN <= CB2_OUT when CB2_DIR_OUT='1' else '1';
SIO_COMMAND <= CB2_OUT;
PORTA_IN <= ((JOY2_n(3)&JOY2_n(2)&JOY2_n(1)&JOY2_n(0)&JOY1_n(3)&JOY1_n(2)&JOY1_n(1)&JOY1_n(0)) and not (porta_dir_out)) or (porta_dir_out and porta_out);
PORTB_IN <= PORTB_OUT;

-- ANTIC lightpen
ANTIC_LIGHTPEN <= JOY2_n(4) and JOY1_n(4);

-- GTIA triggers
GTIA_TRIG <= "11"&JOY2_n(4)&JOY1_n(4);

-- Cartridge not inserted
CART_RD4 <= '0';
CART_RD5 <= '0';

-- Since we're not exposing PBI, expose a few key parts needed for SDRAM
SDRAM_DI <= PBI_WRITE_DATA;

-- Paddles!
pot0 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		reverse => 1
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => '1',
		POT_RESET => POT_RESET,
		POS => PADDLE0,
		POT_HIGH => POT_IN(0)
	);
pot1 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		reverse => 1
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => '1',
		POT_RESET => POT_RESET,
		POS => PADDLE1,
		POT_HIGH => POT_IN(1)
	);
pot2 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		reverse => 1
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => '1',
		POT_RESET => POT_RESET,
		POS => PADDLE2,
		POT_HIGH => POT_IN(2)
	);
pot3 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		reverse => 1
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => '1',
		POT_RESET => POT_RESET,
		POS => PADDLE3,
		POT_HIGH => POT_IN(3)
	);
POT_IN(7 downto 4) <= (others=>'0');

-- Internal rom/ram
internalromram1 : entity work.internalromram
	GENERIC MAP
	(
		internal_rom => internal_rom,
		internal_ram => internal_ram
	)
	PORT MAP (
 		clock   => CLK,
		reset_n => RESET_N,

		ROM_ADDR => ROM_ADDR,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		ROM_REQUEST => ROM_REQUEST,
		ROM_DATA => ROM_DO,
		
		RAM_ADDR => RAM_ADDR,
		RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		RAM_DATA_IN => PBI_WRITE_DATA(7 downto 0),
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_REQUEST => RAM_REQUEST,
		RAM_DATA => RAM_DO(7 downto 0)
	);

	USE_SDRAM <= '1' when internal_ram=0 else '0';
	ROM_IN_RAM <= '1' when internal_rom=0 else '0';

atari800xl : entity work.atari800core
	GENERIC MAP
	(
		cycle_length => cycle_length,
		video_bits => video_bits,
		palette => palette,
		low_memory => low_memory,
		stereo => stereo,
		covox => covox
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK => VIDEO_BLANK,
		VIDEO_BURST => VIDEO_BURST,
		VIDEO_START_OF_FIELD => VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE => VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L,
		AUDIO_R => AUDIO_R,

		CA1_IN => CA1_IN,
		CB1_IN => CB1_IN,
		CA2_IN => CA2_IN,
		CA2_OUT => CA2_OUT,
		CA2_DIR_OUT => CA2_DIR_OUT,
		CB2_IN => CB2_IN,
		CB2_OUT => CB2_OUT,
		CB2_DIR_OUT => CB2_DIR_OUT,
		PORTA_IN => PORTA_IN,
		PORTA_DIR_OUT => PORTA_DIR_OUT,
		PORTA_OUT => PORTA_OUT,
		PORTB_IN => PORTB_IN,
		PORTB_DIR_OUT => open,--PORTB_DIR_OUT,
		PORTB_OUT => PORTB_OUT,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		POT_IN => POT_IN,
		POT_RESET => POT_RESET,
		
		-- PBI
		PBI_ADDR => open,
		PBI_WRITE_ENABLE => open,
		PBI_SNOOP_DATA => DMA_MEMORY_DATA,
		PBI_WRITE_DATA => PBI_WRITE_DATA,
		PBI_WIDTH_8bit_ACCESS => SDRAM_8BIT_WRITE_ENABLE,
		PBI_WIDTH_16bit_ACCESS => SDRAM_16BIT_WRITE_ENABLE,
		PBI_WIDTH_32bit_ACCESS => SDRAM_32BIT_WRITE_ENABLE,

		PBI_ROM_DO => "11111111",
		PBI_REQUEST => open,
		PBI_REQUEST_COMPLETE => '1',

		CART_RD4 => CART_RD4,
		CART_RD5 => CART_RD5,
		CART_S4_n => open,
		CART_S5_N => open,
		CART_CCTL_N => open,

		SIO_RXD => SIO_RXD,
		SIO_TXD => SIO_TXD,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START=> CONSOL_START,
		GTIA_TRIG => GTIA_TRIG,
		
		ANTIC_LIGHTPEN => ANTIC_LIGHTPEN,
		ANTIC_REFRESH => SDRAM_REFRESH,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,

		RAM_ADDR => RAM_ADDR,
		RAM_DO => RAM_DO,
		RAM_REQUEST => RAM_REQUEST,
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_WRITE_ENABLE => RAM_WRITE_ENABLE,
		
		ROM_ADDR => ROM_ADDR,
		ROM_DO => ROM_DO,
		ROM_REQUEST => ROM_REQUEST,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,

		DMA_FETCH => DMA_FETCH,
		DMA_READ_ENABLE => DMA_READ_ENABLE,
		DMA_32BIT_WRITE_ENABLE => DMA_32BIT_WRITE_ENABLE,
		DMA_16BIT_WRITE_ENABLE => DMA_16BIT_WRITE_ENABLE,
		DMA_8BIT_WRITE_ENABLE => DMA_8BIT_WRITE_ENABLE,
		DMA_ADDR => DMA_ADDR,
		DMA_WRITE_DATA => DMA_WRITE_DATA,
		MEMORY_READY_DMA => MEMORY_READY_DMA,

		RAM_SELECT => RAM_SELECT,
		CART_EMULATION_SELECT => emulated_cartridge_select,
		PAL => PAL,
		USE_SDRAM => USE_SDRAM,
		ROM_IN_RAM => ROM_IN_RAM,
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		HALT => HALT,
		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate
	);

end vhdl;

