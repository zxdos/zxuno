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

-- There is a higher level that just wires up internal ROM/RAM/joysticks to demonstrate how to use this
-- Also see board specific top levels
ENTITY atari5200core IS 
	GENERIC
	(
		cycle_length : integer := 16; -- or 32...
		video_bits : integer := 8;
		palette : integer :=0; -- 0:gtia colour on VIDEO_B, 1:on
		low_memory : integer := 0 -- 0:8MB memory map, 1:1MB memory map
	);
	PORT
	(
		CLK :  IN  STD_LOGIC; -- cycle_length*1.79MHz
		RESET_N : IN STD_LOGIC;

		-- VIDEO OUT - NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS :  OUT  STD_LOGIC;
		VIDEO_HS :  OUT  STD_LOGIC;
		VIDEO_CS :  OUT  STD_LOGIC;
		VIDEO_B :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_G :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_R :  OUT  STD_LOGIC_VECTOR(video_bits-1 DOWNTO 0);
		VIDEO_BLANK : out std_logic;
		VIDEO_BURST : out std_logic;
		VIDEO_START_OF_FIELD : out std_logic;
		VIDEO_ODD_LINE : out std_logic;

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L : OUT std_logic_vector(15 downto 0);
		AUDIO_R : OUT std_logic_vector(15 downto 0);

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		KEYBOARD_SCAN : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

		-- Pokey pots
		POT_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		POT_RESET : OUT STD_LOGIC;
		
		-- PBI
		PBI_ADDR : out STD_LOGIC_VECTOR(15 DOWNTO 0);
		PBI_WRITE_ENABLE : out STD_LOGIC; -- currently only for CART config...
		PBI_SNOOP_DATA : out std_logic_vector(31 downto 0); -- snoop the bus (i.e. what gets feed to the CPU data in)
		PBI_WRITE_DATA : out std_logic_vector(31 downto 0); -- we want to write this to external ram
		PBI_WIDTH_8bit_ACCESS : out std_logic;
		PBI_WIDTH_16bit_ACCESS : out std_logic;
		PBI_WIDTH_32bit_ACCESS : out std_logic;

		-- TODO - review this mechanism
		-- Since this is intended for real carts, instead should use real timing, though perhaps that can be external...
		PBI_ROM_DO : in STD_LOGIC_VECTOR(7 DOWNTO 0);
		PBI_REQUEST : out STD_LOGIC;
		PBI_REQUEST_COMPLETE : in STD_LOGIC;
		-- TODO - also need to allow rest of PBI accesses, refresh handling etc. Can wait...
		-- TODO MPD, IRQ, RDY, REFRESH, EXTSEL, RST

		-- CARTRIDGE ACCESS (need this, but need to review how it works...)
		-- (R/W/DO on PBI)
		--CART_RD4 : in STD_LOGIC;
		--CART_RD5 : in STD_LOGIC;
		--CART_S4_n : out STD_LOGIC;
		--CART_S5_N : out STD_LOGIC;
		--CART_CCTL_N : out std_logic;

		-- SIO
		SIO_RXD : in std_logic;
		SIO_TXD : out std_logic;
		-- SIO_COMMAND_TX - see PIA PB2
		-- TODO CLOCK IN/CLOCK OUT (unused almost everywhere...)

		-- GTIA consol
		CONSOL_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
		CONSOL_IN : IN STD_LOGIC_VECTOR(3 downto 0);
		GTIA_TRIG : IN STD_LOGIC_VECTOR(3 downto 0);

		-- ANTIC lightpen
		ANTIC_REFRESH : out STD_LOGIC; -- 1 'original' cycle high when antic doing refresh cycle...
		
		-----------------------
		-- After here all FPGA implementation specific
		-- e.g. need to write up RAM/ROM
		-- we can dma from memory space
		-- etc.

		-- External RAM/ROM - adhere to standard memory map
		-- TODO - lower/upper memory split defined by generic
		-- (TODO SRAM lower ram, SDRAM upper ram - no overlap?)
		---- SRAM memory map (512k) (if USE_SDRAM=0)
		---- base 64k RAM  - banks 0-3    "000 0000 1111 1111 1111 1111" (TOP)
		---- to 512k RAM   - banks 4-31   "000 0111 1111 1111 1111 1111" (TOP)
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

		RAM_ADDR : OUT STD_LOGIC_VECTOR(18 DOWNTO 0);
		RAM_DO : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		RAM_REQUEST : OUT STD_LOGIC;
		RAM_REQUEST_COMPLETE : IN STD_LOGIC;
		RAM_WRITE_ENABLE : OUT STD_LOGIC;
		
		ROM_ADDR : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
		ROM_DO : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		ROM_REQUEST : OUT STD_LOGIC;
		ROM_REQUEST_COMPLETE : IN STD_LOGIC;

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

		-- Special config params
		USE_SDRAM :  in STD_LOGIC;
		ROM_IN_RAM : in std_logic;
		HALT : in std_logic;
		THROTTLE_COUNT_6502 : in STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END atari5200core;

ARCHITECTURE bdf_type OF atari5200core IS 

-- ANTIC
SIGNAL	ANTIC_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	ANTIC_AN :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	ANTIC_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_ANTIC_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	ANTIC_FETCH :  STD_LOGIC;
SIGNAL	ANTIC_HIGHRES_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_ORIGINAL_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_RDY :  STD_LOGIC;
SIGNAL	ANTIC_WRITE_ENABLE :  STD_LOGIC;
signal hcount_temp : std_logic_vector(7 downto 0);
signal vcount_temp : std_logic_vector(8 downto 0);
signal ANTIC_REFRESH_CYCLE : STD_LOGIC;

-- GTIA
SIGNAL	GTIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_GTIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	GTIA_WRITE_ENABLE :  STD_LOGIC;

signal COLOUR : std_logic_vector(7 downto 0);

-- GTIA PALETTE
signal VIDEO_R_WIDE : std_logic_vector(7 downto 0);
signal VIDEO_G_WIDE : std_logic_vector(7 downto 0);
signal VIDEO_B_WIDE : std_logic_vector(7 downto 0);

-- CPU
SIGNAL	CPU_6502_RESET :  STD_LOGIC;
SIGNAL	CPU_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	CPU_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CPU_FETCH :  STD_LOGIC;
SIGNAL	IRQ_n :  STD_LOGIC;
SIGNAL	NMI_n :  STD_LOGIC;
SIGNAL	R_W_N :  STD_LOGIC;

-- CLOCKING STUFF
-- TODO - review/explain what all these are for
SIGNAL	CPU_SHARED_ENABLE :  STD_LOGIC;
SIGNAL	ENABLE_179_MEMWAIT :  STD_LOGIC;
SIGNAL	ANTIC_ENABLE_179 :  STD_LOGIC;

-- POKEY
SIGNAL	POKEY_IRQ :  STD_LOGIC;

SIGNAL	POKEY_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_POKEY_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POKEY_WRITE_ENABLE :  STD_LOGIC;
signal POKEY1_CHANNEL0 : std_logic_vector(3 downto 0);
signal POKEY1_CHANNEL1 : std_logic_vector(3 downto 0);
signal POKEY1_CHANNEL2 : std_logic_vector(3 downto 0);
signal POKEY1_CHANNEL3 : std_logic_vector(3 downto 0);

-- MEMORY IS READY - input to all devices
SIGNAL	MEMORY_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MEMORY_READY_ANTIC :  STD_LOGIC;
SIGNAL	MEMORY_READY_CPU :  STD_LOGIC;

SIGNAL	WRITE_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL	WIDTH_16BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_32BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_8BIT_ACCESS :  STD_LOGIC;

-- PBI
SIGNAL PBI_ADDR_INT : std_logic_vector(15 downto 0);

BEGIN 

PBI_WIDTH_8bit_ACCESS <= WIDTH_8bit_access;
PBI_WIDTH_16bit_ACCESS <= WIDTH_16bit_access;
PBI_WIDTH_32bit_ACCESS <= WIDTH_32bit_access;
PBI_WRITE_DATA <= WRITE_DATA;
PBI_SNOOP_DATA <= MEMORY_DATA;

enables : entity work.shared_enable
GENERIC MAP(cycle_length => cycle_length)
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 ANTIC_REFRESH => ANTIC_REFRESH_CYCLE,
		 PAUSE_6502 => HALT,
		 THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		 ANTIC_ENABLE_179 => ANTIC_ENABLE_179,
		 oldcpu_enable => ENABLE_179_MEMWAIT,
		 CPU_ENABLE_OUT => CPU_SHARED_ENABLE);

CPU_6502_RESET <= NOT(RESET_N); 
cpu6502 : entity work.cpu
PORT MAP(CLK => CLK,
		 RESET => CPU_6502_RESET,
		 ENABLE => RESET_N,
		 IRQ_n => IRQ_n,
		 NMI_n => NMI_n,
		 MEMORY_READY => MEMORY_READY_CPU,
		 THROTTLE => CPU_SHARED_ENABLE,
		 RDY => ANTIC_RDY,
		 DI => MEMORY_DATA(7 DOWNTO 0),
		 R_W_n => R_W_N,
		 CPU_FETCH => CPU_FETCH,
		 A => CPU_ADDR,
		 DO => CPU_DO);

antic1 : entity work.antic
GENERIC MAP(cycle_length => cycle_length)
PORT MAP(CLK => CLK,
		 WR_EN => ANTIC_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 ANTIC_ENABLE_179 => ANTIC_ENABLE_179,
		 PAL => '0',
		 lightpen => '0',
		 ADDR => PBI_ADDR_INT(3 DOWNTO 0),
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 MEMORY_DATA_IN => MEMORY_DATA(7 DOWNTO 0),
		 NMI_N_OUT => NMI_n,
		 ANTIC_READY => ANTIC_RDY,
		 COLOUR_CLOCK_ORIGINAL_OUT => ANTIC_ORIGINAL_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK_OUT => ANTIC_COLOUR_CLOCK_OUT,
		 HIGHRES_COLOUR_CLOCK_OUT => ANTIC_HIGHRES_COLOUR_CLOCK_OUT,
		 dma_fetch_out => ANTIC_FETCH,
		 hcount_out => hcount_temp,
		 vcount_out => vcount_temp,
		 refresh_out => ANTIC_REFRESH_CYCLE,
		 AN => ANTIC_AN,
		 DATA_OUT => ANTIC_DO,
		 dma_address_out => ANTIC_ADDR);

pokey_mixer : entity work.pokey_mixer_mux
PORT MAP(CLK => CLK,
		 GTIA_SOUND => '0',
		 CHANNEL_L_0 => POKEY1_CHANNEL0,
		 CHANNEL_L_1 => POKEY1_CHANNEL1,
		 CHANNEL_L_2 => POKEY1_CHANNEL2,
		 CHANNEL_L_3 => POKEY1_CHANNEL3,
		 COVOX_CHANNEL_L_0 => (others=>'0'),
		 COVOX_CHANNEL_L_1 => (others=>'0'),
		 CHANNEL_R_0 => POKEY1_CHANNEL0,
		 CHANNEL_R_1 => POKEY1_CHANNEL1,
		 CHANNEL_R_2 => POKEY1_CHANNEL2,
		 CHANNEL_R_3 => POKEY1_CHANNEL3,
		 COVOX_CHANNEL_R_0 => (others=>'0'),
		 COVOX_CHANNEL_R_1 => (others=>'0'),
		 VOLUME_OUT_L => AUDIO_L,
		 VOLUME_OUT_R => AUDIO_R);
		 
-- TODO, this is freddy, replace with 5200 equiv rather than generic
-- Also remove dma logic from here if possible
mmu1 : entity work.address_decoder
GENERIC MAP(low_memory => low_memory, system => 10)
PORT MAP(CLK => CLK,
		 CPU_FETCH => CPU_FETCH,
		 CPU_WRITE_N => R_W_N,
		 ANTIC_FETCH => ANTIC_FETCH,
		 DMA_FETCH => DMA_FETCH,
		 DMA_READ_ENABLE => DMA_READ_ENABLE,
		 DMA_32BIT_WRITE_ENABLE => DMA_32BIT_WRITE_ENABLE,
		 DMA_16BIT_WRITE_ENABLE => DMA_16BIT_WRITE_ENABLE,
		 DMA_8BIT_WRITE_ENABLE => DMA_8BIT_WRITE_ENABLE,
		 RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		 ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		 CART_REQUEST_COMPLETE => PBI_REQUEST_COMPLETE,
		 reset_n => RESET_N,
		 CART_RD4 => '0', -- TODO, which line does the 5200 use?
		 CART_RD5 => '0',
		 use_sdram => USE_SDRAM,
		 SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		 ANTIC_ADDR => ANTIC_ADDR,
		 ANTIC_DATA => ANTIC_DO,
		 CACHE_ANTIC_DATA => CACHE_ANTIC_DO,
		 CART_ROM_DATA => PBI_ROM_DO,
		 CPU_ADDR => CPU_ADDR,
		 CPU_WRITE_DATA => CPU_DO,
		 GTIA_DATA => GTIA_DO,
		 CACHE_GTIA_DATA => CACHE_GTIA_DO,
		 PIA_DATA => (others=>'0'),
		 POKEY2_DATA => (others=>'0'),
		 CACHE_POKEY2_DATA => (others=>'0'),
		 POKEY_DATA => POKEY_DO,
		 CACHE_POKEY_DATA => CACHE_POKEY_DO,
		 PORTB => (others=>'0'),
		 RAM_DATA => RAM_DO,
		 ram_select => "000",
		 ROM_DATA => ROM_DO,
		 SDRAM_DATA => SDRAM_DO,
		 DMA_ADDR => DMA_ADDR,
		 DMA_WRITE_DATA => DMA_WRITE_DATA,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 MEMORY_READY_DMA => MEMORY_READY_DMA,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 GTIA_WR_ENABLE => GTIA_WRITE_ENABLE,
		 POKEY_WR_ENABLE => POKEY_WRITE_ENABLE,
		 POKEY2_WR_ENABLE => open,
		 ANTIC_WR_ENABLE => ANTIC_WRITE_ENABLE,
		 PIA_WR_ENABLE => open,
		 PIA_RD_ENABLE => open,
		 RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		 PBI_WR_ENABLE => PBI_WRITE_ENABLE,
		 RAM_REQUEST => RAM_REQUEST,
		 ROM_REQUEST => ROM_REQUEST,
		 CART_REQUEST => PBI_REQUEST,
		 CART_S4_n => open,
		 CART_S5_n => open,
		 CART_CCTL_n => open,
		 WIDTH_8bit_ACCESS => WIDTH_8BIT_ACCESS,
		 WIDTH_16bit_ACCESS => WIDTH_16BIT_ACCESS,
		 WIDTH_32bit_ACCESS => WIDTH_32BIT_ACCESS,
		 SDRAM_READ_EN => SDRAM_READ_ENABLE,
		 SDRAM_WRITE_EN => SDRAM_WRITE_ENABLE,
		 SDRAM_REQUEST => SDRAM_REQUEST,
		 MEMORY_DATA => MEMORY_DATA,
		 PBI_ADDR => PBI_ADDR_INT,
		 RAM_ADDR => RAM_ADDR,
		 ROM_ADDR => ROM_ADDR,
		 SDRAM_ADDR => SDRAM_ADDR,
		 WRITE_DATA => WRITE_DATA,
		 d6_wr_enable => open,
		 cart_select => (others=>'0'),
		 rom_in_ram => ROM_IN_RAM,
		 freezer_enable => '0',
		 freezer_activate => '0');

pokey1 : entity work.pokey
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_179_MEMWAIT,
		 WR_EN => POKEY_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 SIO_IN1 => SIO_RXD,
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 ADDR => PBI_ADDR_INT(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 keyboard_response => KEYBOARD_RESPONSE,
		 POT_IN => POT_IN,
		 IRQ_N_OUT => POKEY_IRQ,
		 SIO_OUT1 => SIO_TXD,
		 SIO_OUT2 => open,
		 SIO_OUT3 => open,
		 POT_RESET => POT_RESET,
		 CHANNEL_0_OUT => POKEY1_CHANNEL0,
		 CHANNEL_1_OUT => POKEY1_CHANNEL1,
		 CHANNEL_2_OUT => POKEY1_CHANNEL2,
		 CHANNEL_3_OUT => POKEY1_CHANNEL3,
		 DATA_OUT => POKEY_DO,
		 keyboard_scan => KEYBOARD_SCAN);

		 	 
gtia1 : entity work.gtia
PORT MAP(CLK => CLK,
		 WR_EN => GTIA_WRITE_ENABLE,
		 ANTIC_FETCH => ANTIC_FETCH, -- for first pmg fetch
		 CPU_ENABLE_ORIGINAL => ENABLE_179_MEMWAIT, -- for subsequent pmg fetches
		 RESET_N => RESET_N,
		 PAL => '0',
		 COLOUR_CLOCK_ORIGINAL => ANTIC_ORIGINAL_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK => ANTIC_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK_HIGHRES => ANTIC_HIGHRES_COLOUR_CLOCK_OUT,
		 CONSOL_OUT => CONSOL_OUT,
		 CONSOL_IN => CONSOL_IN,
		 TRIG => GTIA_TRIG,
		 ADDR => PBI_ADDR_INT(4 DOWNTO 0),
		 AN => ANTIC_AN,
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 MEMORY_DATA_IN => MEMORY_DATA(7 DOWNTO 0),
		 VSYNC => VIDEO_VS,
		 HSYNC => VIDEO_HS,
		 CSYNC => VIDEO_CS,
		 BLANK => VIDEO_BLANK,
		 BURST => VIDEO_BURST,
		 START_OF_FIELD => VIDEO_START_OF_FIELD,
		 ODD_LINE => VIDEO_ODD_LINE,
		 COLOUR_out => COLOUR,
		 DATA_OUT => GTIA_DO);

	-- colour palette

gen_palette_none : if palette=0 generate
	VIDEO_B_WIDE <= COLOUR;
	VIDEO_R_WIDE <= (others => '0');
	VIDEO_G_WIDE <= (others => '0');
end generate;

gen_palette_on : if palette=1 generate
	palette4 : entity work.gtia_palette
		port map (PAL=>'0', ATARI_COLOUR=>COLOUR, R_next=>VIDEO_R_WIDE, G_next=>VIDEO_G_WIDE, B_next=>VIDEO_B_WIDE);		
end generate;

VIDEO_R(video_bits-1 downto 0) <= VIDEO_R_WIDE(7 downto 8-video_bits);
VIDEO_G(video_bits-1 downto 0) <= VIDEO_G_WIDE(7 downto 8-video_bits);
VIDEO_B(video_bits-1 downto 0) <= VIDEO_B_WIDE(7 downto 8-video_bits);

-- Combine irq - only one here!
IRQ_n <= POKEY_IRQ;
		 
-- TODO - generic ram infer?
pokey1_mirror : entity work.reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR_INT(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => POKEY_WRITE_ENABLE,
	DATA_OUT => CACHE_POKEY_DO
);	 

gtia_mirror : entity work.reg_file
generic map(BYTES=>32,WIDTH=>5)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR_INT(4 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => GTIA_WRITE_ENABLE,
	DATA_OUT => CACHE_GTIA_DO
);	

antic_mirror : entity work.reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR_INT(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => ANTIC_WRITE_ENABLE,
	DATA_OUT => CACHE_ANTIC_DO
);	

-- outputs
PBI_ADDR <= PBI_ADDR_INT;
ANTIC_REFRESH <= ANTIC_REFRESH_CYCLE;

END bdf_type;
