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

ENTITY atari800core_helloworld is
	GENERIC
	(
		-- use CLK of 1.79*cycle_length
		-- I've tested 16 and 32 only, but 4 and 8 might work...
		cycle_length : integer := 16; -- or 32...

		video_bits : integer := 8;
	
		internal_rom : integer :=1;
		internal_ram : integer := 16384  -- at start of memory map
	);
	PORT
	(
		CLK :  IN  STD_LOGIC; -- cycle_length*1.79MHz
		RESET_N : IN STD_LOGIC;

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS :  OUT  STD_LOGIC;
		VIDEO_HS :  OUT  STD_LOGIC;
		VIDEO_B :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_G :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_R :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L : OUT std_logic_vector(15 downto 0);
		AUDIO_R : OUT std_logic_vector(15 downto 0);

		-- JOYSTICK
		JOY1_n : IN std_logic_vector(4 downto 0); -- FRLDU, 0=pressed
		JOY2_n : IN std_logic_vector(4 downto 0); -- FRLDU, 0=pressed

		-- KEYBOARD
		PS2_CLK : IN STD_LOGIC;
		PS2_DAT : IN STD_LOGIC;

		-- video standard
		PAL :  in STD_LOGIC
	);
end atari800core_helloworld;

ARCHITECTURE vhdl OF atari800core_helloworld IS 

-- pokey keyboard
SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);

-- gtia consol keys
SIGNAL CONSOL_START : std_logic;
SIGNAL CONSOL_SELECT : std_logic;
SIGNAL CONSOL_OPTION : std_logic;

-- 6502 throttling
SIGNAL THROTTLE_COUNT_6502 : std_logic_vector(5 downto 0);

BEGIN

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION
		
		-- TODO - reset!
	);

-- THROTTLE
THROTTLE_COUNT_6502 <= "000001";

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => cycle_length,
		internal_rom => internal_rom,
		internal_ram =>internal_ram,
		video_bits => video_bits
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK => open,
		VIDEO_BURST => open,
		VIDEO_START_OF_FIELD => open,
		VIDEO_ODD_LINE => open,

		AUDIO_L => AUDIO_L,
		AUDIO_R => AUDIO_R,

		JOY1_n => JOY1_n,
		JOY2_n => JOY2_n,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => open,
		SIO_RXD => '1',
		SIO_TXD => open,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

		SDRAM_REQUEST => open,
		SDRAM_REQUEST_COMPLETE => '1',
		SDRAM_READ_ENABLE => open,
		SDRAM_WRITE_ENABLE => open,
		SDRAM_ADDR => open,
		SDRAM_DO => (others=>'1'),

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'1'),
		DMA_WRITE_DATA => (others=>'1'),
		MEMORY_READY_DMA => open,

   		RAM_SELECT => (others=>'0'),
		PAL => PAL,
		HALT => '0',
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		emulated_cartridge_select => (others=>'0'),
		freezer_enable => '0',
		freezer_activate => '0'
	);

end vhdl;

