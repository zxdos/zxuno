---------------------------------------------------------------------------
-- Port to ZX-UNO by Quest 2016
--
-- (c) 2013-2015 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY Atari800 IS 
	GENERIC
	(
		internal_rom : integer := 1 ;
		internal_ram : integer := 0
	);
	PORT
	(
		CLK_IN :  IN  STD_LOGIC; 

		PS2_CLK1 	: IN  STD_LOGIC;
		PS2_DAT1 	: IN  STD_LOGIC;

		VGA_VSYNC 	: INOUT  STD_LOGIC;
		VGA_HSYNC 	: INOUT  STD_LOGIC;
		VGA_BLUE 	: INOUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_GREEN 	: INOUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_RED 	   : INOUT  STD_LOGIC_VECTOR(2 DOWNTO 0);

		dVGA_VSYNC 	: OUT  STD_LOGIC;
		dVGA_HSYNC 	: OUT  STD_LOGIC;
		dVGA_BLUE 	: OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		dVGA_GREEN 	: OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		dVGA_RED 	   : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		
		JOYSTICK1_1 : IN STD_LOGIC;
		JOYSTICK1_2 : IN STD_LOGIC;
		JOYSTICK1_3 : IN STD_LOGIC;
		JOYSTICK1_4 : IN STD_LOGIC;
--		JOYSTICK1_5 : IN STD_LOGIC;
		JOYSTICK1_6 : IN STD_LOGIC;
--		JOYSTICK1_7 : IN STD_LOGIC;
--		JOYSTICK1_9 : IN STD_LOGIC;
--
		AUDIO1_LEFT  : OUT std_logic;
		AUDIO1_RIGHT : OUT std_logic;

		SD_MISO 		 : IN  STD_LOGIC;
		SD_SCK 		 : OUT  STD_LOGIC;
		SD_MOSI 		 : OUT  STD_LOGIC;
		SD_nCS 		 : OUT  STD_LOGIC;

		SRAM_DATA 	 : INOUT  STD_LOGIC_VECTOR(7 downto 0);
		SRAM_ADDR 	 : OUT  STD_LOGIC_VECTOR(18 downto 0);
		SRAM_WE 		 : OUT  STD_LOGIC;

      O_NTSC       : out   std_logic;
      O_PAL        : out   std_logic;		

		LED :  OUT  STD_LOGIC
	
	);
END Atari800;

ARCHITECTURE vhdl OF Atari800 IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

	signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
	signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

	signal AUDIO_OUT : std_logic;
	
	signal VIDEO_VS : std_logic;
	signal VIDEO_HS : std_logic;
	signal VIDEO_CS : std_logic;
	signal VIDEO_R : std_logic_vector(7 downto 0);
	signal VIDEO_G : std_logic_vector(7 downto 0);
	signal VIDEO_B : std_logic_vector(7 downto 0);

	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;

	signal PAL : std_logic;
	
	signal JOY1_IN_n : std_logic_vector(4 downto 0);
--	signal JOY2_IN_n : std_logic_vector(4 downto 0);

	signal PLL1_LOCKED : std_logic;
	signal CLK_PLL1 : std_logic;
	
	signal RESET_n : std_logic;
	signal PLL_LOCKED : std_logic;
	signal CLK : std_logic;
	signal CLK_SDRAM : std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal scanlines_reg : std_logic;
	signal scanlines_next : std_logic;
 	SIGNAL COMPOSITE_ON_HSYNC : std_logic := '1';
 	SIGNAL VGA : std_logic := '0';

	-- dma/virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal DMA_MEMORY_DATA : std_logic_vector(31 downto 0);

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA :  std_logic_vector(31 downto 0);

	signal ZPU_OUT1 : std_logic_vector(31 downto 0);
	signal ZPU_OUT2 : std_logic_vector(31 downto 0);
	signal ZPU_OUT3 : std_logic_vector(31 downto 0);
	signal ZPU_OUT4 : std_logic_vector(31 downto 0);
	signal ZPU_OUT5 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- sram
	signal ram_request : std_logic;
	signal ram_request_complete : std_logic;
	signal ram_read_enable : std_logic;
	signal ram_write_enable : std_logic;
	signal ram_addr : std_logic_vector(22 downto 0);
	signal ram_do : std_logic_vector(31 downto 0);
	signal ram_di : std_logic_vector(31 downto 0);
	signal ram_width32bit : std_logic;
	
	signal VIDEOSW : std_logic := '0';
	signal SCANL : std_logic := '0';
	signal VIDEOSTD : std_logic :='0';
	signal tv : std_logic :='0';
	signal REBOOT : std_logic := '0';
	signal CLK_MULTIBOOT : std_logic;
	
--	signal poweron_reset:	unsigned(7 downto 0) := "00000000";
	signal scandoubler_ctrl: std_logic;
--	signal ram_we_n: std_logic;
--	signal ram_a:	std_logic_vector(18 downto 0);	
	
BEGIN 

    dVGA_RED <= VGA_RED;
    dVGA_GREEN <= VGA_GREEN;
    dVGA_BLUE <= VGA_BLUE;
    dVGA_VSYNC <= VGA_VSYNC;
    dVGA_HSYNC <= VGA_HSYNC;

dac : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_PCM&"0000",
  dac_out => audio_out
);

audio1_left <= audio_out;
audio1_right <= audio_out;

		pll : entity work.pll_m
		port map (
		   CLK_IN1                    => CLK_IN,
		   CLK_OUT1                   => CLK,
		   CLK_OUT2                   => CLK_MULTIBOOT,
		   RESET                      => '0',
		   LOCKED                     => PLL_LOCKED );

reset_n <= PLL_LOCKED;

JOY1_IN_N <=  (JOYSTICK1_6 xnor not (ps2_keys(16#171#) or ps2_keys(16#70#))) --real joy & numpad joy emulation.
				& (JOYSTICK1_4 xnor not ps2_keys(16#74#)) 
				& (JOYSTICK1_3 xnor not ps2_keys(16#6b#)) 
				& (JOYSTICK1_2 xnor not (ps2_keys(16#72#) or ps2_keys(16#73#))) 
				& (JOYSTICK1_1 xnor not ps2_keys(16#75#));
--JOY1_IN_N <= JOYSTICK1_6&JOYSTICK1_4&JOYSTICK1_3&JOYSTICK1_2&JOYSTICK1_1;
--JOY2_IN_N <= JOYSTICK2_6&JOYSTICK2_4&JOYSTICK2_3&JOYSTICK2_2&JOYSTICK2_1;

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	GENERIC MAP
	(
		ps2_enable => 1,
		direct_enable => 1
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => PS2_CLK1,
		PS2_DAT => PS2_DAT1,

		INPUT => zpu_out4,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
		,MRESET => REBOOT
	);

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,
		internal_rom => internal_rom,
		internal_ram => internal_ram,
		video_bits   => 8,
		palette      => 0,
		low_memory   => 2,
      STEREO       => 0,
      COVOX        => 0
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and not(RESET_ATARI),

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK =>VIDEO_BLANK,
		VIDEO_BURST =>VIDEO_BURST,
		VIDEO_START_OF_FIELD =>VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE =>VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n,
--		JOY2_n => JOY2_IN_n,
		JOY2_n => "11111",

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

-- TODO, connect to SRAM! Handle 32-bit in multiple cycles. How fast is the sram.
		SDRAM_REQUEST => ram_request,
		SDRAM_REQUEST_COMPLETE => ram_request_complete,
		SDRAM_READ_ENABLE => ram_read_enable,
		SDRAM_WRITE_ENABLE => ram_write_enable,
		SDRAM_ADDR => ram_addr,
		SDRAM_DO => ram_do,
		SDRAM_DI => ram_di,
		SDRAM_32BIT_WRITE_ENABLE => ram_width32bit,
		SDRAM_16BIT_WRITE_ENABLE => open,
		SDRAM_8BIT_WRITE_ENABLE => open,
		SDRAM_REFRESH => open,

		DMA_FETCH => dma_fetch,
		DMA_READ_ENABLE => dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		DMA_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		DMA_ADDR => dma_addr_fetch,
		DMA_WRITE_DATA => dma_write_data,
		MEMORY_READY_DMA => dma_memory_ready,
		DMA_MEMORY_DATA => dma_memory_data, 

   	RAM_SELECT => ram_select,
		PAL => PAL,
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502,
		emulated_cartridge_select => emulated_cartridge_select,
--		freezer_enable => freezer_enable,
--		freezer_activate => freezer_activate
		freezer_enable => '0',
		freezer_activate => '0'
	);

-- Video options
	PAL <= not VIDEOSTD;
	
	O_NTSC <= not PAL;
	O_PAL  <= PAL;
	
	-- Key combos for zxuno
	process (clk) 
	begin
	if (clk'event and clk='1') then
		-- scrolLock RGB/VGA
		if (VIDEOSW = '0' and (not(ps2_keys(16#7e#)) and ps2_keys_next(16#7e#)) = '1'  ) then
			vga <= '1';
			composite_on_hsync <= '0';
			VIDEOSW <= '1';
		elsif (VIDEOSW = '1' and (not(ps2_keys(16#7e#)) and ps2_keys_next(16#7e#)) = '1') then
			vga <= '0';
			composite_on_hsync <= '1';
			VIDEOSW <= '0';
		end if;	
		
		-- "*" PAL / NTSC
		if (VIDEOSTD = '0' and (not(ps2_keys(16#7c#)) and ps2_keys_next(16#7c#)) = '1'  ) then
			VIDEOSTD <= '1';
		elsif (VIDEOSTD = '1' and (not(ps2_keys(16#7c#)) and ps2_keys_next(16#7c#)) = '1') then
			VIDEOSTD <= '0';
		end if;					
	 end if; 
	end process;

	process(clk,RESET_N,reset_atari)
	begin
		if ((RESET_N and not(reset_atari))='0') then
			half_scandouble_enable_reg <= '0';
			scanlines_reg <= '0';
		elsif (clk'event and clk='1') then
			half_scandouble_enable_reg <= half_scandouble_enable_next;
			scanlines_reg <= scanlines_next;
		end if;
	end process;

	half_scandouble_enable_next <= not(half_scandouble_enable_reg);
	
	scanlines_next <= scanlines_reg xor (not(ps2_keys(16#7b#)) and ps2_keys_next(16#7b#)); -- left alt

	scandoubler1: entity work.scandoubler
	PORT MAP
	( 
		CLK => CLK,
	   RESET_N => reset_n,
		
		VGA => scandoubler_ctrl xor vga,
		COMPOSITE_ON_HSYNC => scandoubler_ctrl xor composite_on_hsync,

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => scanlines_reg,
		
		-- GTIA interface
		pal => PAL,
		colour_in => VIDEO_B,
		vsync_in => VIDEO_VS,
		hsync_in => VIDEO_HS,
		csync_in => VIDEO_CS,
		
		-- TO TV...
		R => VGA_RED,
		G => VGA_GREEN,
		B => VGA_BLUE,
		
		VSYNC => VGA_VSYNC,
		HSYNC => VGA_HSYNC
	);


zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 2, -- 28MHz/2. Max for SD cards is 25MHz...
		usb => 0
	)
	PORT MAP
	(
		-- standard...
		CLK => CLK,
		RESET_N => RESET_N,

		-- dma bus master (with many waitstates...)
		ZPU_ADDR_FETCH => dma_addr_fetch,
		ZPU_DATA_OUT => dma_write_data,
		ZPU_FETCH => dma_fetch,
		ZPU_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		ZPU_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		ZPU_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		ZPU_READ_ENABLE => dma_read_enable,
		ZPU_MEMORY_READY => dma_memory_ready,
		ZPU_MEMORY_DATA => dma_memory_data, 

		-- rom bus master
		-- data on next cycle after addr
		ZPU_ADDR_ROM => zpu_addr_rom,
		ZPU_ROM_DATA => zpu_rom_data,

		-- spi master
		-- Too painful to bit bang spi from zpu, so we have a hardware master in here
		ZPU_SD_DAT0 => SD_MISO,
		ZPU_SD_CLK => SD_SCK,
		ZPU_SD_CMD => SD_MOSI,
		ZPU_SD_DAT3 => SD_nCS,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"000"&
			"00"&ps2_keys(16#76#)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => X"00000000",
		ZPU_IN4 => X"00000000",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2, --joy0
		ZPU_OUT3 => zpu_out3, --joy1
		ZPU_OUT4 => zpu_out4, --keyboard
		ZPU_OUT5 => zpu_out5  --analog stick (not supported without USB)
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	emulated_cartridge_select <= zpu_out1(22 downto 17);
	freezer_enable <= zpu_out1(25);

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(13 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);


ram : entity work.sram
	PORT MAP
	( 
		ADDRESS => ram_addr(18 downto 0),
		DIN => ram_di,
		WREN => ram_write_enable,
		
		clk => clk,
		reset_n => reset_n,
		
		request => ram_request,

		width32bit => ram_width32bit,
		
		-- SRAM interface
		SRAM_ADDR => sram_addr,
		SRAM_WE_N => sram_we,
	
		SRAM_DQ => sram_data,
		
		-- Provide data to system
		DOUT => ram_do,
		complete => ram_request_complete,
		scandc => scandoubler_ctrl
	);
	
LED <= not(zpu_sio_command);	

-----------multiboot---------------

	multiboot: entity work.multiboot
	port map(
		clk_icap		      => CLK_MULTIBOOT,
		REBOOT				=> REBOOT
	);

END vhdl;
