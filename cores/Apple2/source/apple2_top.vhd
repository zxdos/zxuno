-------------------------------------------------------------------------------
-- 
-- Papilio DUO with Classic computing shield  top-level module for the Apple ][
--
-- VLA
--
-- Based on DE2 top-level by Stephen A. Edwards, Columbia University, sedwards@cs.columbia.edu
--
-- From an original by Terasic Technology, Inc.
-- (DE2_TOP.v, part of the DE2 system board CD supplied by Altera)
--
-- 2015 Ported and modified to ZX-UNO board by Quest
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity APPLE2_TOP is

  port (
    -- Clocks
    
    CLOCK50 : in std_logic;
  	 LED : out std_logic; 		 
	
    -- SRAM
    
    SRAM_DQ : inout unsigned(7 downto 0);         -- Data bus 8 Bits
    SRAM_ADDR : out unsigned(18 downto 0);        -- Address bus 20 Bits
    SRAM_WE_N : out std_logic;                    -- Write Enable

    -- SD card interface
    
    SD_DAT : in std_logic;      -- SD Card Data      SD pin 7 "DAT 0/DataOut"
    SD_DAT3 : out std_logic;    -- SD Card Data 3    SD pin 1 "DAT 3/nCS"
    SD_CMD : out std_logic;     -- SD Card Command   SD pin 2 "CMD/DataIn"
    SD_CLK : out std_logic;     -- SD Card Clock     SD pin 5 "CLK"
    
    -- PS/2 port

    PS2_DAT,                    -- Data
    PS2_CLK : in std_logic;     -- Clock

    -- VGA output
    
    VGA_HS,                                        -- H_SYNC
    VGA_VS : inout std_logic;                      -- V_SYNC
    VGA_R,                                         -- Red[2:0]
    VGA_G,                                         -- Green[2:0]
    VGA_B : inout unsigned(2 downto 0);            -- Blue[2:0]

    dVGA_HS,                                       -- H_SYNC
    dVGA_VS : out std_logic;                       -- V_SYNC
    dVGA_R,                                        -- Red[2:0]
    dVGA_G,                                        -- Green[2:0]
    dVGA_B : out unsigned(2 downto 0);             -- Blue[2:0]

    -- Audio OUT
    
    O_AUDIO_L : out std_logic;                          -- ADC Data
	 O_AUDIO_R : out std_logic;                          -- ADC Data
    
	 BTN2 : in std_logic;
	 JOYSTICK1 : in std_logic_vector(4 downto 0)
    );
  
end APPLE2_TOP;

architecture datapath of APPLE2_TOP is

  signal CLK_28M, CLK_14M, CLK_2M, PRE_PHASE_ZERO : std_logic;
  signal IO_SELECT, DEVICE_SELECT : std_logic_vector(7 downto 0);
  signal ADDR : unsigned(15 downto 0);
  signal D, PD : unsigned(7 downto 0);

  signal ram_we : std_logic;
  signal VIDEO, HBL, VBL, LD194 : std_logic;
  signal COLOR_LINE : std_logic;
  signal COLOR_LINE_CONTROL : std_logic;
  signal GAMEPORT : std_logic_vector(7 downto 0);
  signal cpu_pc : unsigned(15 downto 0);

  signal K : unsigned(7 downto 0);
  signal read_key : std_logic;

  signal flash_clk : unsigned(22 downto 0) := (others => '0');
  signal power_on_reset : std_logic := '1';
  signal reset : std_logic;

  signal speaker : std_logic;
  signal audio_bit : std_logic;

  signal track : unsigned(5 downto 0);
  signal image : unsigned(9 downto 0);
--  signal trackmsb : unsigned(3 downto 0);
  signal D1_ACTIVE, D2_ACTIVE : std_logic;
  signal track_addr : unsigned(13 downto 0);
  signal TRACK_RAM_ADDR : unsigned(13 downto 0);
  signal tra : unsigned(15 downto 0);
  signal TRACK_RAM_DI : unsigned(7 downto 0);
  signal TRACK_RAM_WE : std_logic;
  signal R_10 : unsigned(9 downto 0);
  signal G_10 : unsigned(9 downto 0);
  signal B_10 : unsigned(9 downto 0);

  signal CS_N, MOSI, MISO, SCLK : std_logic;
  
  signal PDL_STROBE : std_logic;
  signal joy1_x, joy1_y : std_logic;
  signal csjudlr1 : std_logic_vector(6 downto 0);
  signal BTN3 : std_logic;
  
  signal resetKey : std_logic;
  signal imageCount : unsigned(7 downto 0) := (others => '0');
  
  signal manualreset : std_logic := '0';
  
  signal scanSW		:	std_logic_vector(3 downto 0);
  signal AReset : std_logic;

begin

    dVGA_R <= VGA_R;
    dVGA_G <= VGA_G;
    dVGA_B <= VGA_B;
    dVGA_VS <= VGA_VS;
    dVGA_HS <= VGA_HS;

  reset <=  manualreset or power_on_reset;
  
  resetKey <= '1' when AReset = '1' else '0'; --F12 reset

  power_on : process(CLK_14M)
  begin
    if rising_edge(CLK_14M) then
     if flash_clk(22) = '1'  then
        power_on_reset <= '0';
     end if;
    end if;
  end process;

  -- In the Apple ][, this was a 555 timer
  flash_clkgen : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
	   if resetKey = '0' then
       flash_clk <= flash_clk + 1;
		 if flash_clk(22) = '1'  then
		  manualreset <= '0';
		 end if;
		else
		  flash_clk <= "00000000000000000000000";
		  manualreset <= '1';
		end if;
    end if;     
  end process;

  --  50 MHz down to 28 MHz and 14 MHz

	dcm : entity work.CLOCKGEN port map (
		I_CLK			=> CLOCK50,
		I_RST 		=> '0',
		O_CLK_28M	=> CLK_28M,
		O_CLK_14M	=> CLK_14M
		);
		
  BTN3 <= '1';
	
  -- joystick inputs, these should probably be debounced first
  csjudlr1 <= "00" & JOYSTICK1;	

  -- Paddle buttons
  -- GAMEPORT input bits:
  --  7    6    5    4    3   2   1    0
  -- pdl3 pdl2 pdl1 pdl0 pb3 pb2 pb1 casette
  --            y    x   bt3 bt2 bt1
  
  -- Paddle buttons
  GAMEPORT <=  "00" & joy1_y & joy1_x & not BTN3 & not BTN2 & not csjudlr1(4) & '0'; --"0000" & "0000"; -- (not KEY(2 downto 0)) & "0";
  
  -- fake analog joystick... 
  -- PDL_STROBE starts the counter 
  -- middle value for the joy pots is 127 * 11us ~ 2800 cycles (2M clock instead of 1 so we multiply by 2)
  -- http://www.umich.edu/~archive/apple2/technotes/tn/aiie/TN.AIIE.006
  
  an_fake: process (CLK_2M, PDL_STROBE, joystick1)
    variable xaxis : integer range 0 to 5700 := 0; -- 5700 is over 255 * 11us which should guarantee far end of joystick pot 
	 variable yaxis : integer range 0 to 5700 := 0;
  begin
    if rising_edge(CLK_2M) then
	   if PDL_STROBE = '1' then
		  case (csjudlr1(1 downto 0)) is -- left and right
		    when "10" => xaxis := 5700; -- computing shield has pullups 
		    when "01" => xaxis := 10;
          when others => xaxis := 2800;
		  end case;
		
		  case (csjudlr1(3 downto 2)) is  -- up and down
		    when "10" => yaxis := 5700; -- computing shield has pullups
		    when "01" => yaxis := 10;
          when others => yaxis := 2800;
		  end case;
	  else --counting down
	    if xaxis > 0 then
		  xaxis := xaxis - 1;
		  joy1_x <= '1';
		else
		  joy1_x <= '0';
		end if;
		
		if yaxis > 0 then
		  yaxis := yaxis -1;
		  joy1_y <= '1';
		else 
		  joy1_y <= '0';
		end if;
	end if;
	end if;
  end process;
  
  COLOR_LINE_CONTROL <= COLOR_LINE and not scanSW(3); -- Color or B&W mode (* numpad switch)
  
  core : entity work.apple2 port map (
    CLK_14M        => CLK_14M,
    CLK_2M         => CLK_2M,
    PRE_PHASE_ZERO => PRE_PHASE_ZERO,
    FLASH_CLK      => flash_clk(22),
    reset          => reset,
    ADDR           => ADDR,
    ram_addr       => SRAM_ADDR(17 downto 0),
    D              => D,
    ram_do         => SRAM_DQ(7 downto 0),
    PD             => PD,
    ram_we         => ram_we,
    VIDEO          => VIDEO,
    COLOR_LINE     => COLOR_LINE,
    HBL            => HBL,
    VBL            => VBL,
    LD194          => LD194,
    K              => K,
    read_key       => read_key,
    AN             => open, 
    GAMEPORT       => GAMEPORT,
    IO_SELECT      => IO_SELECT,
    DEVICE_SELECT  => DEVICE_SELECT,
    pcDebugOut     => cpu_pc,
    speaker        => speaker,
	PDL_STROBE     => PDL_STROBE
    );

  vga : entity work.vga_controller port map (
    CLK_28M    => CLK_28M, 
	 CLK_14M		=> CLK_14M,
    VIDEO      => VIDEO,
    COLOR_LINE => COLOR_LINE_CONTROL,
    HBL        => HBL,
    VBL        => VBL,
    LD194      => LD194,
    VGA_HS     => VGA_HS,
    VGA_VS     => VGA_VS,
    VGA_R      => R_10,
    VGA_G      => G_10,
    VGA_B      => B_10
	 ,SCANL 		=> scanSW(2)
    );

  VGA_R <= R_10(9 downto 7); 
  VGA_G <= G_10(9 downto 7);
  VGA_B <= B_10(9 downto 7);

  keyboard : entity work.keyboard port map (
    PS2_Clk  => PS2_CLK,
    PS2_Data => PS2_DAT,
    clk  	 => CLK_14M,
    rst_n    => '1',
    readd    => read_key,
    K        => K
	 ,scanSW  => scanSW
	,imagecount => imagecount
	,AReset   => AReset
    );
	 
  disk : entity work.disk_ii port map (
    CLK_14M        => CLK_14M,
    CLK_2M         => CLK_2M,
    PRE_PHASE_ZERO => PRE_PHASE_ZERO,
    IO_SELECT      => IO_SELECT(6),
    DEVICE_SELECT  => DEVICE_SELECT(6),
    RESET          => reset,
    A              => ADDR,
    D_IN           => D,
    D_OUT          => PD,
    TRACK          => TRACK,
    TRACK_ADDR     => TRACK_ADDR,
    D1_ACTIVE      => D1_ACTIVE,
    D2_ACTIVE      => D2_ACTIVE,
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE
    );

  sdcard_interface : entity work.spi_controller port map (
    CLK_14M        => CLK_14M,
    RESET          => RESET,

    CS_N           => CS_N,
    MOSI           => MOSI,
    MISO           => MISO,
    SCLK           => SCLK,
    
    track          => TRACK,
    image          => image,
    
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE
    );

  image <= "00" & imageCount; --disk image selection 
  
  SD_DAT3 <= CS_N;
  SD_CMD  <= MOSI;
  MISO    <= SD_DAT;
  SD_CLK  <= SCLK;

  audio_output : entity work.dac port map (
   clk_i 		=> CLK_14M,
	res_n_i		=> not reset,
	dac_i			=> speaker & "0000000",
	dac_o			=> audio_bit
	);
	
	O_AUDIO_L <= audio_bit;
	O_AUDIO_R <= audio_bit;
	
  -- Current disk track on right two digits 
  --  trackmsb <= "00" & track(5 downto 4);
  
  SRAM_DQ(7 downto 0) <= (others => '0') when reset = '1' else D when ram_we = '1' else (others => 'Z'); --added Data part of SRAM init when reset to jump disk boot code.
  SRAM_ADDR(18) <= '0';
  SRAM_WE_N <= '0' when reset = '1' else not ram_we;

  LED <= not CS_N; --Led SD
--  LED2 <= '1' when imageCount = "0000000001" else '0'; --Led ext3

------------multiboot---------------

	multiboot: entity work.multiboot
	port map(
		clk_icap		      => CLK_14M,
		REBOOT				=> scanSW(0)
	);
	
end datapath;
