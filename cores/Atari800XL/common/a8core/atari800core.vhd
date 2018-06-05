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
ENTITY atari800core IS 
	GENERIC
	(
		cycle_length : integer := 32; -- or 32...
		video_bits : integer := 8;
		palette : integer :=0; -- 0:gtia colour on VIDEO_B, 1:on
		low_memory : integer := 2; -- 0:8MB memory map, 1:1MB memory map
		stereo : integer := 0;
		covox : integer := 0
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
		VIDEO_BLANK : out std_logic;
		VIDEO_BURST : out std_logic;
		VIDEO_START_OF_FIELD : out std_logic;
		VIDEO_ODD_LINE : out std_logic;

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L : OUT std_logic_vector(15 downto 0);
		AUDIO_R : OUT std_logic_vector(15 downto 0);

		-- PIA
		CA1_IN : IN STD_LOGIC; -- SIO Proceed
		CB1_IN : IN STD_LOGIC; -- SIO IRQ
		CA2_IN : IN STD_LOGIC; -- SIO Motor control
		CA2_OUT : OUT STD_LOGIC; 
		CA2_DIR_OUT: OUT STD_LOGIC; -- 1=output mode
		CB2_IN: IN STD_LOGIC;
		CB2_OUT : OUT STD_LOGIC; -- SIO Command
		CB2_DIR_OUT: OUT STD_LOGIC; -- 1=output mode
		PORTA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- For joystick
		PORTA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PORTA_DIR_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PORTB_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- For bank switching on XL/XE, for joystick on 800XL
		PORTB_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		PORTB_DIR_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		KEYBOARD_SCAN : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

		-- Pokey pots
		POT_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		POT_RESET : OUT STD_LOGIC;
		
		-- PBI
		ENABLE_179_EARLY : out std_logic; -- used for phi2 generation - 1 cycle before orig cpu runs
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

		-- CARTRIDGE ACCESS
		-- (R/W/DO on PBI)
		CART_RD4 : in STD_LOGIC;
		CART_RD5 : in STD_LOGIC;
		CART_S4_n : out STD_LOGIC;
		CART_S5_N : out STD_LOGIC;
		CART_CCTL_N : out std_logic;

		-- SIO
		SIO_RXD : in std_logic;
		SIO_TXD : out std_logic;
		SIO_CLOCKIN : in std_logic :='1';
		SIO_CLOCKOUT : out std_logic;
		-- SIO_COMMAND_TX - see PIA PB2
		-- TODO CLOCK IN/CLOCK OUT (unused almost everywhere...)

		-- GTIA consol
		CONSOL_OPTION : IN STD_LOGIC;
		CONSOL_SELECT : IN STD_LOGIC;
		CONSOL_START : IN STD_LOGIC;
		GTIA_TRIG : IN STD_LOGIC_VECTOR(3 downto 0);

		-- ANTIC lightpen
		ANTIC_LIGHTPEN : IN std_logic;
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
   		RAM_SELECT : in std_logic_vector(2 downto 0); -- 64K,128K,320KB Compy, 320KB Rambo, 576K Compy, 576K Rambo, 1088K, 4MB
		CART_EMULATION_SELECT : in std_logic_vector(5 downto 0);
		PAL :  in STD_LOGIC;
		USE_SDRAM :  in STD_LOGIC;
		ROM_IN_RAM : in std_logic;
		THROTTLE_COUNT_6502 : in STD_LOGIC_VECTOR(5 DOWNTO 0);
		HALT : in std_logic;
		freezer_enable: in std_logic;
		freezer_activate: in std_logic;
		freezer_state_out: out std_logic_vector(2 downto 0);
		pbi_enable: in std_logic := '0'
	);
END atari800core;

ARCHITECTURE bdf_type OF atari800core IS 

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
SIGNAL	BREAK_PRESSED :  STD_LOGIC;
signal hcount_temp : std_logic_vector(7 downto 0);
signal vcount_temp : std_logic_vector(8 downto 0);
signal ANTIC_REFRESH_CYCLE : STD_LOGIC;

-- GTIA
SIGNAL	GTIA_SOUND :  STD_LOGIC;
SIGNAL	CONSOL_OUT :  STD_LOGIC_VECTOR(3 downto 0);
SIGNAL	CONSOL_IN :  STD_LOGIC_VECTOR(3 downto 0);
SIGNAL  GTIA_TRIG_MERGED : STD_LOGIC_VECTOR(3 downto 0);

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

SIGNAL	POKEY2_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_POKEY2_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POKEY2_WRITE_ENABLE :  STD_LOGIC;
signal POKEY2_CHANNEL0 : std_logic_vector(3 downto 0);
signal POKEY2_CHANNEL1 : std_logic_vector(3 downto 0);
signal POKEY2_CHANNEL2 : std_logic_vector(3 downto 0);
signal POKEY2_CHANNEL3 : std_logic_vector(3 downto 0);

-- COVOX (after market DAC)
signal covox_write_enable : std_logic;
signal covox_channel0 : std_logic_vector(7 downto 0);
signal covox_channel1 : std_logic_vector(7 downto 0);
signal covox_channel2 : std_logic_vector(7 downto 0);
signal covox_channel3 : std_logic_vector(7 downto 0);

-- MEMORY IS READY - input to all devices
SIGNAL	MEMORY_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MEMORY_READY_ANTIC :  STD_LOGIC;
SIGNAL	MEMORY_READY_CPU :  STD_LOGIC;

SIGNAL	WRITE_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL	WIDTH_16BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_32BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_8BIT_ACCESS :  STD_LOGIC;

-- PIA
SIGNAL	PIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	PIA_IRQA :  STD_LOGIC;
SIGNAL	PIA_IRQB :  STD_LOGIC;
SIGNAL	PIA_READ_ENABLE :  STD_LOGIC;
SIGNAL	PIA_WRITE_ENABLE :  STD_LOGIC;
SIGNAL PORTB_OUT_INT : STD_LOGIC_VECTOR(7 downto 0);

-- PBI
SIGNAL PBI_ADDR_INT : std_logic_vector(15 downto 0);

-- cart
signal cart_trig3_out: std_logic;

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
		 PAL => PAL,
		 lightpen => ANTIC_LIGHTPEN,
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

pokey_mixer_both : entity work.pokey_mixer_mux
PORT MAP(CLK => CLK,
		 GTIA_SOUND => GTIA_SOUND,
		 CHANNEL_L_0 => POKEY1_CHANNEL0,
		 CHANNEL_L_1 => POKEY1_CHANNEL1,
		 CHANNEL_L_2 => POKEY1_CHANNEL2,
		 CHANNEL_L_3 => POKEY1_CHANNEL3,
		 COVOX_CHANNEL_L_0 => covox_channel0,
		 COVOX_CHANNEL_L_1 => covox_channel1,
		 CHANNEL_R_0 => POKEY2_CHANNEL0,
		 CHANNEL_R_1 => POKEY2_CHANNEL1,
		 CHANNEL_R_2 => POKEY2_CHANNEL2,
		 CHANNEL_R_3 => POKEY2_CHANNEL3,
		 COVOX_CHANNEL_R_0 => covox_channel2,
		 COVOX_CHANNEL_R_1 => covox_channel3,
		 VOLUME_OUT_L => AUDIO_L,
		 VOLUME_OUT_R => AUDIO_R);
		 

gen_stereo : if stereo=1 generate
pokey2 : entity work.pokey
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_179_MEMWAIT,
		 WR_EN => POKEY2_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => PBI_ADDR_INT(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => POKEY2_CHANNEL0,
		 CHANNEL_1_OUT => POKEY2_CHANNEL1,
		 CHANNEL_2_OUT => POKEY2_CHANNEL2,
		 CHANNEL_3_OUT => POKEY2_CHANNEL3,
		 DATA_OUT => POKEY2_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 keyboard_response => "00",
		 pot_in=>"00000000");
end generate;

gen_mono : if stereo=0 generate
	POKEY2_CHANNEL0 <= POKEY1_CHANNEL0;
	POKEY2_CHANNEL1 <= POKEY1_CHANNEL1;
	POKEY2_CHANNEL2 <= POKEY1_CHANNEL2;
	POKEY2_CHANNEL3 <= POKEY1_CHANNEL3;
end generate;

pia1 : entity work.pia
PORT MAP(CLK => CLK,
		 EN => PIA_READ_ENABLE,
		 WR_EN => PIA_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 CA1 => CA1_IN,
		 CB1 => CB1_IN,
		 CA2_DIR_OUT => CA2_DIR_OUT,
		 CA2_IN => CA2_IN,
		 CA2_OUT => CA2_OUT,
		 CB2_DIR_OUT => CB2_DIR_OUT,
		 CB2_IN => CB2_IN,
		 CB2_OUT => CB2_OUT,
		 ADDR => PBI_ADDR_INT(1 DOWNTO 0),
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 IRQA_N => PIA_IRQA,
		 IRQB_N => PIA_IRQB,
		 DATA_OUT => PIA_DO,
		 PORTA_IN => PORTA_IN,
		 PORTA_DIR_OUT => PORTA_DIR_OUT,
		 PORTA_OUT => PORTA_OUT,
		 PORTB_IN => PORTB_IN,
		 PORTB_DIR_OUT => PORTB_DIR_OUT,
		 PORTB_OUT => PORTB_OUT_INT);

mmu1 : entity work.address_decoder
GENERIC MAP(low_memory => low_memory, stereo => stereo)
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
		 CART_RD4 => CART_RD4,
		 CART_RD5 => CART_RD5,
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
		 PIA_DATA => PIA_DO,
		 POKEY2_DATA => POKEY2_DO,
		 CACHE_POKEY2_DATA => CACHE_POKEY2_DO,
		 POKEY_DATA => POKEY_DO,
		 CACHE_POKEY_DATA => CACHE_POKEY_DO,
		 PORTB => PORTB_OUT_INT,
		 RAM_DATA => RAM_DO,
		 ram_select => RAM_SELECT(2 downto 0),
		 ROM_DATA => ROM_DO,
		 SDRAM_DATA => SDRAM_DO,
		 DMA_ADDR => DMA_ADDR,
		 DMA_WRITE_DATA => DMA_WRITE_DATA,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 MEMORY_READY_DMA => MEMORY_READY_DMA,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 GTIA_WR_ENABLE => GTIA_WRITE_ENABLE,
		 POKEY_WR_ENABLE => POKEY_WRITE_ENABLE,
		 POKEY2_WR_ENABLE => POKEY2_WRITE_ENABLE,
		 ANTIC_WR_ENABLE => ANTIC_WRITE_ENABLE,
		 PIA_WR_ENABLE => PIA_WRITE_ENABLE,
		 PIA_RD_ENABLE => PIA_READ_ENABLE,
		 RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		 PBI_WR_ENABLE => PBI_WRITE_ENABLE,
		 RAM_REQUEST => RAM_REQUEST,
		 ROM_REQUEST => ROM_REQUEST,
		 CART_REQUEST => PBI_REQUEST,
		 CART_S4_n => CART_S4_n,
		 CART_S5_n => CART_S5_N,
		 CART_CCTL_n => CART_CCTL_N,
		 CART_TRIG3_OUT => cart_trig3_out,
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
		 d6_wr_enable => covox_write_enable,
		 cart_select => CART_EMULATION_SELECT,
		 rom_in_ram => ROM_IN_RAM,
		 freezer_enable => freezer_enable,
		 freezer_activate => freezer_activate,
		 freezer_state_out => freezer_state_out,
		 pbi_enable => pbi_enable);

pokey1 : entity work.pokey
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_179_MEMWAIT,
		 WR_EN => POKEY_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 SIO_IN1 => SIO_RXD,
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 SIO_CLOCKIN => SIO_CLOCKIN,
		 ADDR => PBI_ADDR_INT(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 keyboard_response => KEYBOARD_RESPONSE,
		 POT_IN => POT_IN,
		 IRQ_N_OUT => POKEY_IRQ,
		 SIO_OUT1 => SIO_TXD,
		 SIO_OUT2 => open,
		 SIO_OUT3 => open,
		 SIO_CLOCKOUT => SIO_CLOCKOUT,
		 POT_RESET => POT_RESET,
		 CHANNEL_0_OUT => POKEY1_CHANNEL0,
		 CHANNEL_1_OUT => POKEY1_CHANNEL1,
		 CHANNEL_2_OUT => POKEY1_CHANNEL2,
		 CHANNEL_3_OUT => POKEY1_CHANNEL3,
		 DATA_OUT => POKEY_DO,
		 keyboard_scan => KEYBOARD_SCAN);

CONSOL_IN <= '1'&CONSOL_OPTION&CONSOL_SELECT&CONSOL_START;
GTIA_TRIG_MERGED <= cart_trig3_out & GTIA_TRIG(2 downto 0); -- NOTE, inputs ignored, careful when adding 4 joystick support
		 	 
gtia1 : entity work.gtia
PORT MAP(CLK => CLK,
		 WR_EN => GTIA_WRITE_ENABLE,
		 ANTIC_FETCH => ANTIC_FETCH, -- for first pmg fetch
		 CPU_ENABLE_ORIGINAL => ENABLE_179_MEMWAIT, -- for subsequent pmg fetches
		 RESET_N => RESET_N,
		 PAL => PAL,
		 COLOUR_CLOCK_ORIGINAL => ANTIC_ORIGINAL_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK => ANTIC_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK_HIGHRES => ANTIC_HIGHRES_COLOUR_CLOCK_OUT,
		 CONSOL_OUT => CONSOL_OUT,
		 CONSOL_IN => CONSOL_IN,
		 TRIG => GTIA_TRIG_MERGED,
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

GTIA_SOUND <= CONSOL_OUT(3);

	-- colour palette

gen_palette_none : if palette=0 generate
	VIDEO_B_WIDE <= COLOUR;
	VIDEO_R_WIDE <= (others => '0');
	VIDEO_G_WIDE <= (others => '0');
end generate;

gen_palette_on : if palette=1 generate
	palette4 : entity work.gtia_palette
		port map (PAL=>PAL, ATARI_COLOUR=>COLOUR, R_next=>VIDEO_R_WIDE, G_next=>VIDEO_G_WIDE, B_next=>VIDEO_B_WIDE);		
end generate;

VIDEO_R(video_bits-1 downto 0) <= VIDEO_R_WIDE(7 downto 8-video_bits);
VIDEO_G(video_bits-1 downto 0) <= VIDEO_G_WIDE(7 downto 8-video_bits);
VIDEO_B(video_bits-1 downto 0) <= VIDEO_B_WIDE(7 downto 8-video_bits);

irq_glue1 : entity work.irq_glue
PORT MAP(pokey_irq => POKEY_IRQ,
		 pia_irqa => PIA_IRQA,
		 pia_irqb => PIA_IRQB,
		 combined_irq => IRQ_n);
		 
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

pokey2_mirror : entity work.reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR_INT(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => POKEY2_WRITE_ENABLE,
	DATA_OUT => CACHE_POKEY2_DO
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

gen_covox_off : if covox=0 generate
	COVOX_CHANNEL0 <= (others=>'0');
	COVOX_CHANNEL1 <= (others=>'0');
	COVOX_CHANNEL2 <= (others=>'0');
	COVOX_CHANNEL3 <= (others=>'0');
end generate;

gen_covox_on : if covox=1 generate
covox1 : entity work.covox
	PORT map
	( 
		clk => clk,
		addr => pbi_addr_int(1 downto 0),
		data_in => WRITE_DATA(7 DOWNTO 0),
		wr_en => covox_write_enable,
		covox_channel0 => covox_channel0,
		covox_channel1 => covox_channel1,
		covox_channel2 => covox_channel2,
		covox_channel3 => covox_channel3
	);
end generate;

-- outputs
PBI_ADDR <= PBI_ADDR_INT;
ENABLE_179_EARLY <= ANTIC_ENABLE_179;
PORTB_OUT <= PORTB_OUT_INT;
ANTIC_REFRESH <= ANTIC_REFRESH_CYCLE;

END bdf_type;
