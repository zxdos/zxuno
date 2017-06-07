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
-- i) needs: CLK(58 or 28MHZ) joystick,PS2 keyboard
-- ii) provides: VIDEO,AUDIO,ROM,RAM

-- example...
-- KEEP THIS FILE SIMPLE!

ENTITY atari5200core_simplesdram is
	GENERIC
	(
		-- use CLK of 1.79*cycle_length
		-- I've tested 16 and 32 only, but 4 and 8 might work...
		cycle_length : integer := 16; -- or 32...

		video_bits : integer := 8;
	
		internal_rom : integer :=4;
		internal_ram : integer := 16384;  -- at start of memory map

		palette : integer := 1
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

		DMA_FETCH : in STD_LOGIC; -- we want to read/write
		DMA_READ_ENABLE : in std_logic;
		DMA_32BIT_WRITE_ENABLE : in std_logic;
		DMA_16BIT_WRITE_ENABLE : in std_logic;
		DMA_8BIT_WRITE_ENABLE : in std_logic;
		DMA_ADDR : in std_logic_vector(23 downto 0);
		DMA_WRITE_DATA : in std_logic_vector(31 downto 0);
		MEMORY_READY_DMA : out std_logic; -- op complete
		DMA_MEMORY_DATA : out std_logic_vector(31 downto 0);

		HALT : in std_logic;
		THROTTLE_COUNT_6502 : in std_logic_vector(5 downto 0); -- standard speed is cycle_length-1
	
		-- JOYSTICK
		JOY1_X : IN signed(7 downto 0);
		JOY1_Y : IN signed(7 downto 0);
		JOY1_BUTTON : IN std_logic;
		JOY2_X : IN signed(7 downto 0);
		JOY2_Y : IN signed(7 downto 0);
		JOY2_BUTTON : IN std_logic;

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		KEYBOARD_SCAN : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		CONTROLLER_SELECT : OUT STD_LOGIC_VECTOR(1 downto 0)
	);
end atari5200core_simplesdram;

ARCHITECTURE vhdl OF atari5200core_simplesdram IS 

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

-- TRIG
SIGNAL TRIG : STD_LOGIC_VECTOR(1 downto 0);

-- CONSOL
SIGNAL CONSOL_OUT : STD_LOGIC_VECTOR(3 downto 0);

-- POTS
SIGNAL POT_RESET : STD_LOGIC;
SIGNAL POT_IN : STD_LOGIC_VECTOR(7 downto 0);

constant min_lines : integer := 15;
constant max_lines : integer := 210;

BEGIN

-- triggers
TRIG(0) <= JOY1_BUTTON;
TRIG(1) <= JOY2_BUTTON;

-- pots 
pot0 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		min_lines=>min_lines,
		max_lines=>max_lines
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => CONSOL_OUT(2),
		POT_RESET => POT_RESET,
		POS => JOY1_X,
		POT_HIGH => POT_IN(0)
	);
pot1 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		min_lines=>min_lines,
		max_lines=>max_lines
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => CONSOL_OUT(2),
		POT_RESET => POT_RESET,
		POS => JOY1_Y,
		POT_HIGH => POT_IN(1)
	);
pot2 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		min_lines=>min_lines,
		max_lines=>max_lines
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => CONSOL_OUT(2),
		POT_RESET => POT_RESET,
		POS => JOY2_X,
		POT_HIGH => POT_IN(2)
	);
pot3 : entity work.pot_from_signed
	GENERIC MAP
	(
		cycle_length=>cycle_length,
		min_lines=>min_lines,
		max_lines=>max_lines
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLED => CONSOL_OUT(2),
		POT_RESET => POT_RESET,
		POS => JOY2_Y,
		POT_HIGH => POT_IN(3)
	);
POT_IN(7 downto 4) <= (others=>'0');

atari5200_simple_sdram1 : entity work.atari5200core
	GENERIC MAP
	(
		cycle_length => cycle_length,
		video_bits => video_bits,
		palette => palette
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

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		-- Pokey pots
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

		-- TODO - review this mechanism
		-- Since this is intended for real carts, instead should use real timing, though perhaps that can be external...
		PBI_ROM_DO => (others=>'1'),
		PBI_REQUEST => open,
		PBI_REQUEST_COMPLETE => '1',

		-- SIO
		SIO_RXD => '1',
		SIO_TXD => open,

		-- GTIA consol
		CONSOL_OUT => CONSOL_OUT, -- TODO sound, pots(err, pokey?), 2bit controller keyboard select
		CONSOL_IN => "1000",
		GTIA_TRIG => "11"&TRIG, -- triggers (4 ports...)

		-- ANTIC 
		ANTIC_REFRESH => SDRAM_REFRESH,
		
		-----------------------
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

		-- DMA memory map differs
		DMA_FETCH => DMA_FETCH,
		DMA_READ_ENABLE => DMA_READ_ENABLE,
		DMA_32BIT_WRITE_ENABLE => DMA_32BIT_WRITE_ENABLE,
		DMA_16BIT_WRITE_ENABLE => DMA_16BIT_WRITE_ENABLE,
		DMA_8BIT_WRITE_ENABLE => DMA_8BIT_WRITE_ENABLE,
		DMA_ADDR => DMA_ADDR,
		DMA_WRITE_DATA => DMA_WRITE_DATA,
		MEMORY_READY_DMA => MEMORY_READY_DMA,

		-- Special config params
		USE_SDRAM => USE_SDRAM,
		ROM_IN_RAM => ROM_IN_RAM,
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		HALT => HALT
	);

-- Since we're not exposing PBI, expose a few key parts needed for SDRAM
SDRAM_DI <= PBI_WRITE_DATA;

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

CONTROLLER_SELECT <= CONSOL_OUT(1 downto 0);

end vhdl;

