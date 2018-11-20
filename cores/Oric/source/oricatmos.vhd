--
-- ORIC ATMOS top level module
--
--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;
-- component chip_6502 port (
--   port (
--     clk: in std_logic;
--     phi: in std_logic;
--     res: in std_logic;
--     so:  in std_logic;
--     rdy: in std_logic;
--     nmi: in std_logic;
--     irq: in std_logic;
--     dbi : in std_logic_vector(7 downto 0);
--     dbo : out std_logic_vector(7 downto 0);
--     rw : out std_logic;
--     sync: out std_logic;
--     ab: out std_loogic_vector(15 downto 0);
--     );
  
entity ORIC is
  port (

    -- Keyboard
    PS2CLK1              : in    std_logic;
    PS2DAT1              : in    std_logic;

    -- Audio out
    AUDIO_OUT           : out   std_logic;
    -- Audio out 2
    AUDIO_OUT2           : out   std_logic;

    -- VGA out
    O_VIDEO_R           : out   std_logic_vector(2 downto 0); --Q
    O_VIDEO_G           : out   std_logic_vector(2 downto 0); --Q
    O_VIDEO_B           : out   std_logic_vector(2 downto 0); --Q
    O_HSYNC             : out   std_logic;
    O_VSYNC             : out   std_logic;

    --D_VIDEO_R           : out   std_logic_vector(2 downto 0); --Q
    --D_VIDEO_G           : out   std_logic_vector(2 downto 0); --Q
    --D_VIDEO_B           : out   std_logic_vector(2 downto 0); --Q
    --D_HSYNC             : out   std_logic;
    --D_VSYNC             : out   std_logic;

    VIDEO_SYNC          : out   std_logic;

    -- K7 connector
    K7_TAPEIN         : in    std_logic;
    K7_TAPEOUT        : out   std_logic;

--	K7_REMOTE         : out   std_logic;
--	K7_AUDIOOUT       : out   std_logic;

    I_RESET              : in    std_logic;
    I_NMI             : in    std_logic;
    led :out std_logic;
    -- PRINTER
--	PRT_DATA          : inout std_logic_vector(7 downto 0);
--	PRT_STR           : out   std_logic;  -- strobe
--	PRT_ACK           : in    std_logic;  -- ack

--	IRQn              : in    std_logic;
    ---
--	CLK_EXT           : out   std_logic;  -- 1 MHZ
--	RW                : out   std_logic;
--	IO                : out   std_logic;
--	IOCONTROL         : in    std_logic;

    O_NTSC              : out   std_logic; --Q
    O_PAL               : out   std_logic; --Q

    -- SRAM
    
    SRAM_DQ : inout std_logic_vector(7 downto 0);         -- Data bus 8 Bits
    SRAM_ADDR : out std_logic_vector(20 downto 0);        -- Address bus 20 Bits
    SRAM_WE_N : out std_logic;                    -- Write Enable
    SRAM_CS_N : out std_logic;

  --sd card controller
  SD_DAT : in std_logic;      -- SD Card Data      SD pin 7 "DAT 0/DataOut" //misoP117
  SD_DAT3 : out std_logic;    -- SD Card Data 3    SD pin 1 "DAT 3/nCS"  cs P121
  SD_CMD : out std_logic;     -- SD Card Command   SD pin 2 "CMD/DataIn"mosiP119
  SD_CLK : out std_logic;     -- SD Card Clock     SD pin 5 "CLK" //sckP115
  SD_CD : in std_logic; -- card detect
  SD_WP : in std_logic; -- card write protect

  -- disk_a_on : out std_logic; -- 0 when disk is active else 1
  -- track_ok  : out std_logic; -- 0 when disk is active else 1
  -- out_MAPn  : out std_logic;  
    -- Clk master
  CLK_50              : in    std_logic  -- MASTER CLK

  -- 7 segment led  indicators
    -- segment   : out std_logic_vector( 7 downto 0);
    -- position   : out std_logic_vector( 7 downto 0)

    );
end;

architecture RTL of ORIC is

  -- Resets
  signal loc_reset_n        : std_logic; --active low
  signal I_RESET_db        : std_logic; --debounsed reset
  signal I_NMI_db        : std_logic; -- debounsed reset
  signal loc_reset_sig        : std_logic; --active low
  signal loc_reset_p1        : std_logic; 
  signal loc_reset_p2        : std_logic; 
  signal cpu_reset_n        : std_logic; --active low
  signal cpu_reset        : std_logic; --active low
  -- Internal clocks
  signal CLKFB              : std_logic := '0';
  signal clk24              : std_logic := '0';
  signal clk12              : std_logic := '0';
  signal clk6               : std_logic := '0';
  signal clk_aud            : std_logic := '0';
  signal clkout0            : std_logic := '0';
  signal clkout1            : std_logic := '0';
  signal clkout2            : std_logic := '0';
  signal clkout3            : std_logic := '0';
  signal clkout4            : std_logic := '0';
  signal clkout5            : std_logic := '0';
  signal pll_locked         : std_logic := '0';

  -- cpu
  signal CPU_ADDR           : std_logic_vector(23 downto 0);
  signal CPU_ADDR_latch           : std_logic_vector(15 downto 0);
  signal CPU_DI             : std_logic_vector( 7 downto 0);
  signal CPU_DO             : std_logic_vector( 7 downto 0);
  signal CPU_ADDRun           : ieee.numeric_std.unsigned(15 downto 0);
  signal CPU_DIun             : ieee.numeric_std.unsigned(7 downto 0);
  signal CPU_DOun             : ieee.numeric_std.unsigned(7 downto 0);
--  signal DATA_BUS_OUT:std_logic_vector(7 downto 0);
    signal cpu_rw             : std_logic;
  signal cpu_irq            : std_logic;
  signal ad                 : std_logic_vector(15 downto 0);
  signal NMI_INT :std_logic;
  signal RESET_INT:std_logic;
  signal cpu_sync:std_logic; -- active high write enable
  signal display_enable:std_logic;
  signal display_value: std_logic_vector(7 downto 0);
  signal display_value_latch: std_logic_vector(7 downto 0);
  
  -- VIA
  signal via_pa_out_oe      : std_logic_vector( 7 downto 0);
  signal via_pa_in          : std_logic_vector( 7 downto 0);
  signal via_pa_in_from_psg : std_logic_vector( 7 downto 0);
  signal via_pa_out         : std_logic_vector( 7 downto 0);
--	signal via_ca2_out        : std_logic;
--	signal via_ca2_oe_l       : std_logic;
--	signal via_cb1_in         : std_logic;
  signal via_cb1_out        : std_logic;
  signal via_cb1_oe_l       : std_logic;
  signal via_cb2_out        : std_logic;
  signal via_cb2_oe_l       : std_logic;
  signal via_in             : std_logic_vector( 7 downto 0);
  signal via_out            : std_logic_vector( 7 downto 0);
  signal via_oe_l           : std_logic_vector( 7 downto 0);
  signal VIA_DO             : std_logic_vector( 7 downto 0);

  -- Keyboard
  signal KEY_ROW            : std_logic_vector( 7 downto 0);

  -- PSG
  signal psg_bdir           : std_logic; -- PSG read/write
  signal PSG_OUT            : std_logic_vector( 7 downto 0);
  signal  vaudio_out : std_logic_vector(7 downto 0);
    
  signal audio_out_tmp  : std_logic := '0';

  signal ym_o_ioa :std_logic_vector (7 downto 0);
  
  -- ULA
  signal ula_phi2           : std_logic;
  signal ula_CSIOn          : std_logic;
  signal ula_CSIO           : std_logic;
  signal ula_CSROMn         : std_logic;
--	signal ula_CSRAMn         : std_logic;
  signal SRAM_DO            : std_logic_vector( 7 downto 0);
  signal ula_AD_SRAM        : std_logic_vector(15 downto 0);
  signal ula_CE_SRAM        : std_logic;
  signal ula_OE_SRAM        : std_logic;
  signal ula_WE_SRAM        : std_logic;
  signal ula_LE_SRAM        : std_logic;
  signal ula_VIDEO_R        : std_logic;
  signal ula_VIDEO_G        : std_logic;
  signal ula_VIDEO_B        : std_logic;
  signal ula_SYNC           : std_logic;

  signal ROM_DO             : std_logic_vector( 7 downto 0);

  -- VIDEO
  signal HSync              : std_logic;
  signal VSync              : std_logic;
  signal hs_int             : std_logic;
  signal vs_int             : std_logic;
  signal dummy              : std_logic_vector( 3 downto 0) := (others => '0');
  signal s_cmpblk_n_out     : std_logic;

  signal VideoR             : std_logic_vector(3 downto 0);
  signal VideoG             : std_logic_vector(3 downto 0);
  signal VideoB             : std_logic_vector(3 downto 0);

  signal red_s              : std_logic;
  signal grn_s              : std_logic;
  signal blu_s              : std_logic;

  signal clk_s              : std_logic;
  signal s_blank            : std_logic;
    -- led display

  signal led_signals_save :  std_logic_vector(31 downto 0);
  signal led_signal_update : std_logic;
  signal led_mutiplex_clk : std_logic;

  signal image : unsigned(9 downto 0);

    -- 8dos controler
  signal cont_MAPn              :     std_logic;
  signal cont_ROMDISn           :     std_logic;
  signal cont_D_OUT : std_logic_vector(7 downto 0);
  signal cont_IOCONTROLn     : std_logic;

  signal  disk_cur_TRACK: std_logic_vector(5 downto 0);  -- Current track (0-34)

  signal IMAGE_NUMBER_out  : std_logic_vector(9 downto 0);
  signal disk_track_addr: std_logic_vector(13 downto 0);
  
 -- previous were ports
  signal disk_a_on :  std_logic; -- 0 when disk is active else 1
  signal track_ok :  std_logic; -- 0 when disk is active else 1

  signal key_scroll : std_logic;
  signal key_scroll_old : std_logic;
  signal video_vga :std_logic;
  signal key_home : std_logic;
  signal key_end : std_logic;
  signal key_pg_up : std_logic;
  signal key_pg_down:std_logic;
function to_HexChar(Value : std_logic_vector(3 downto 0) ) return std_logic_vector  is
  constant HEX : STRING := "0123456789ABCDEF!";
begin
    return std_logic_vector(ieee.numeric_std.to_unsigned(128+character'pos(HEX(1+ieee.numeric_std.to_integer(ieee.numeric_std.unsigned(Value)))),8));
end function;

begin
  -----------------------------------------------
  -- generate all the system clocks required
  -----------------------------------------------

  NMI_INT <= I_NMI_db and not key_end;
  RESET_INT <= not I_RESET_db;
  
  inst_pll_base : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED"
      COMPENSATION       => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRNOUS", "SOURCE_SYNCHRNOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
      CLKIN_PERIOD       => 20.00, -- Clock period (ns) of input clock on CLKIN
      -- 1/12 || 2/25
      DIVCLK_DIVIDE      => 1,     -- Division factor for all clocks (1 to 52)
      CLKFBOUT_MULT      => 12,    -- Multiplication factor for all output clocks (1 to 64)
      CLKFBOUT_PHASE     => 0.0,   -- Phase shift (degrees) of all output clocks
      REF_JITTER         => 0.100, -- Input reference jitter (0.000 to 0.999 UI%)
      -- 120Mhz positive
      CLKOUT0_DIVIDE     => 5,     -- Division factor for CLKOUT0 (1 to 128)
      CLKOUT0_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT0 (0.01 to 0.99)
      CLKOUT0_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
      -- 120Mhz negative
      CLKOUT1_DIVIDE     => 5,     -- Division factor for CLKOUT1 (1 to 128)
      CLKOUT1_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT1 (0.01 to 0.99)
      CLKOUT1_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
      -- 24Mhz
      CLKOUT2_DIVIDE     => 25,    -- Division factor for CLKOUT2 (1 to 128)
      CLKOUT2_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT2 (0.01 to 0.99)
      CLKOUT2_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
      -- 24Mhz
      CLKOUT3_DIVIDE     => 25,    -- Division factor for CLKOUT3 (1 to 128)
      CLKOUT3_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT3 (0.01 to 0.99)
      CLKOUT3_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
      -- 12Mhz
      CLKOUT4_DIVIDE     => 50,    -- Division factor for CLKOUT4 (1 to 128)
      CLKOUT4_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT4 (0.01 to 0.99)
      CLKOUT4_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
      -- 6MHz
      CLKOUT5_DIVIDE     => 100,   -- Division factor for CLKOUT5 (1 to 128)
      CLKOUT5_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT5 (0.01 to 0.99)
      CLKOUT5_PHASE      => 0.0    -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
      )
    port map (
      CLKFBOUT => CLKFB,      -- General output feedback signal
      CLKOUT0  => clkout0,
      CLKOUT1  => clkout1,
      CLKOUT2  => clkout2,
      CLKOUT3  => clkout3,
      CLKOUT4  => clkout4,
      CLKOUT5  => clkout5,
      LOCKED   => pll_locked, -- Active high PLL lock signal
      CLKFBIN  => CLKFB,      -- Clock feedback input
      CLKIN    => CLK_50,     -- Clock input
      RST      => '0' --RESET_INT     -- Asynchronous PLL reset
      );


  inst_buf3 : BUFG port map (I => clkout3, O => clk24);
  inst_buf4 : BUFG port map (I => clkout4, O => clk12);
  clk6 <= clkout5;

  ------------------------------------------------
  inst_debounce_reset : entity work.debounce
    port map (
      clk => clk6,
      button => I_RESET,
      result => I_RESET_db
      );
  inst_debounce_nmi : entity work.debounce
    port map (
      clk => clk6,
      button => I_NMI,
      result => I_NMI_db
      );

--	CLK_EXT <= ula_phi2;
  loc_reset_sig <= I_RESET_db and pll_locked and  not (key_home and key_end) ;
  reset_pr_1: process (clk6)
  begin
    if (rising_edge(clk6)) then
      loc_reset_p1 <= loc_reset_sig;
      loc_reset_p2 <= loc_reset_p1;
    end if;
  end process;
  
      
  -- Reset
  loc_reset_n <= loc_reset_p2 and loc_reset_sig ;
  -- real mos needs running clock we start clock with loc_reset
  -- and then dealy the cpu reset clock
  cpu_delay_reset:process(clk6)
    variable a:integer;
  begin
    if (rising_edge(clk6))then
      if (loc_reset_n = '0') then
        a:= 0;
        cpu_reset_n <= '0';
      elsif(a <6000*50) then
        a:= a + 1;
        cpu_reset_n <= '0';
      else
        cpu_reset_n <= '1';
      end if;          
    end if;
  end process;
    
  --  cpu_reset_n <= loc_reset_n;-- and not key_home;
  cpu_reset   <= not cpu_reset_n;
  ------------------------------------------------------------
  -- CPU 6502
  ------------------------------------------------------------
  -- inst_cpu : entity work.T65
  --   port map (
  --     Mode    => "00",
  --     Res_n   => cpu_reset_n,
  --     Enable  => '1',
  --     Clk     => ula_phi2,
  --     Rdy     => '1',
  --     Abort_n => '1',
  --     IRQ_n   => cpu_irq,
  --     NMI_n   => NMI_INT,
  --     SO_n    => '1',
  --     R_W_n   => cpu_rw,
  --     Sync    => cpu_sync,
  --     EF      => open,
  --     MF      => open,
  --     XF      => open,
  --     ML_n    => open,
  --     VP_n    => open,
  --     VDA     => open,
  --     VPA     => open,
  --     A       => CPU_ADDR,
  --     DI      => CPU_DI,
  --     DO      => CPU_DO
  --     );


  -- ---cpu65x try
  -- inst_cpu : entity work.cpu65xx
  --   generic map (
  --     pipelineOpcode => false,
  --     pipelineAluMux => false,
  --     pipelineAluOut => false)
  --   port map (
  --     di             => CPU_DIun,
  --     clk            => ula_phi2,
  --     enable         => '1',
  --     reset          => cpu_reset, active high signal
  --     nmi_n          => NMI_INT,
  --     irq_n          => cpu_irq,
  --     do             => CPU_DOun,
  --     addr           => CPU_ADDRun,
  --     we             => we
  --     debugPc     => pcDebugOut,
  --     debugOpcode => opcodeDebugOut
  --     );
  -- cpu_rw <= not we;
  -- CPU_DIun <= ieee.numeric_std.unsigned(CPU_DI);
  -- CPU_DO <= std_logic_vector(CPU_DOun);
  -- CPU_ADDR <= std_logic_vector(CPU_ADDRun);

  inst_cpu: entity work.chip_6502
    port map(
    clk => clk24,
    phi => ULA_PHI2,
    res => cpu_reset_n,
    so => '1',
    rdy => '1',
    nmi => NMI_INT,
    irq => cpu_irq,
    dbi => CPU_DI,
    dbo => CPU_DO,
    rw  => cpu_rw,
    sync => cpu_sync, -- not used
    ab => CPU_ADDR(15 downto 0)
      );

  inst_rom : entity work.rom_oa
    port map (
      clk  => clk24,
      ADDR => CPU_ADDR(13 downto 0),
      DATA => ROM_DO
      );

  ------------------------------------------------------------
  -- STATIC RAM
  ------------------------------------------------------------
  ad(15 downto 0)  <= ula_AD_SRAM when ula_phi2 = '0' else CPU_ADDR(15 downto 0);
--	ad(17 downto 16) <= "00";

  
  SRAM_DQ(7 downto 0) <= (others => '0') when cpu_reset_n = '0' else CPU_DO when ula_WE_SRAM = '1' else (others => 'Z'); --added Data part of SRAM init when reset to jump disk boot code.
  SRAM_ADDR(15 downto 0) <= ad(15 downto 0);
  SRAM_ADDR(20 downto 16) <= (others => '1');
  SRAM_WE_N <= '1' when cpu_reset_n = '0' else not ula_WE_SRAM;
  SRAM_CS_N <= '1' when cpu_reset_n = '0' else not ula_CE_SRAM;

  display_enable <= '1' when (key_home = '1') and ula_WE_SRAM = '0' and ula_CE_SRAM = '1' and ula_ad_sram >=x"BFD0" and ula_ad_sram <=x"BFD7"  and ula_PHI2='0'
                    else '0';

  display_value <= to_HexChar("00" & disk_cur_track(5 downto 4)) when ula_ad_sram = x"BFD0" else
                   to_HexChar(disk_cur_track(3 downto 0)) when ula_ad_sram = x"BFD1" else
                   to_HexChar(IMAGE_NUMBER_out(7 downto 4)) when ula_ad_sram = x"BFD2" else
                   to_HexChar(IMAGE_NUMBER_out(3 downto 0)) when ula_ad_sram = x"BFD3" else
                   to_HexChar(cpu_addr_latch(15 downto 12)) when ula_ad_sram = x"BFD4" else
                   to_HexChar(cpu_addr_latch(11 downto 8)) when ula_ad_sram = x"BFD5" else
                   to_HexChar(cpu_addr_latch(7 downto 4)) when ula_ad_sram = x"BFD6" else
                   to_HexChar(cpu_addr_latch(3 downto 0));

  cpu_latch1:process(CLK24)
  begin
    if (rising_edge(CLK24)) then
      if key_pg_down = '1' and cpu_sync='1' and ula_PHI2='1'       then
        cpu_addr_latch <= cpu_addr(15 downto 0);
      end if;
    end if;
  end process;
                     

  SRAM_DO <= display_value when display_enable = '1' and ula_PHI2='0' else
    SRAM_DQ when ula_CE_SRAM = '1' and  ula_WE_SRAM = '0' else (others => '0');
  -- inst_ram : entity work.ram48k
  --   port map(
  --     clk  => clk24,
  --     cs   => ula_CE_SRAM,
  --     oe   => ula_OE_SRAM,
  --     we   => ula_WE_SRAM,
  --     addr => ad,
  --     di   => CPU_DO,
  --     do   => SRAM_DO
  --     );

  ------------------------------------------------------------
  -- ULA
  ------------------------------------------------------------
  inst_ula : entity work.ULA
    port map (
      RESETn     => loc_reset_n,
      CLK        => clk24,

      RW         => cpu_rw,
      ADDR       => CPU_ADDR(15 downto 0),
--		MAPn       => MAPn,
      MAPn       =>  cont_MAPn,
      DB         => SRAM_DO,

      -- DRAM
--		AD_RAM     => open,
--		RASn       => open,
--		CASn       => open,
--		MUX        => open,
--		RW_RAM     => open,

      -- Address decoding
--		CSRAMn     => ula_CSRAMn,
      CSROMn     => ula_CSROMn,
      CSIOn      => ula_CSIOn,

      -- RAM
      SRAM_AD    => ula_AD_SRAM,
      SRAM_OE    => ula_OE_SRAM,
      SRAM_CE    => ula_CE_SRAM,
      SRAM_WE    => ula_WE_SRAM,
      LATCH_SRAM => ula_LE_SRAM,

      -- CPU Clock
      PHI2       => ula_PHI2,

      -- Video
      video_vga  => video_vga,
      R          => ULA_VIDEO_R,
      G          => ULA_VIDEO_G,
      B          => ULA_VIDEO_B,
      SYNC       => ULA_SYNC,
      HSYNC      => hs_int,
      VSYNC      => vs_int
      );
  

  -----------------------------------------------------------------
  -- video scan converter required to display video on VGA hardware
  -----------------------------------------------------------------
  -- total resolution 354x312, active resolution 240x224, H 15625 Hz, V 50.08 Hz
  -- take note: the values below are relative to the CLK period not standard VGA clock period
  inst_scan_conv : entity work.VGA_SCANCONV
    generic map (
      -- mark active area of input video
      cstart      =>  65,  -- composite sync start
      clength     => 240,  -- composite sync length

      -- 381
      -- output video timing
      hA          =>  10, -- 7.62 11,	-- h front porch
      hB          =>  46, -- 45,759682224	-- h sync
      hC          =>  24,-- 22,879841112-- h back porch
      hD          => 240,	-- visible video
 --- total 381.33 
      vA          =>  40,	-- v front porch (not used)
      vB          =>   2,	-- v sync
      vC          =>  16,	-- v back porch
      vD          => 240,	-- visible video

      hpad        =>  32,	-- H black border
      vpad        =>  0  	-- V black border
      )
    port map (
      I_VIDEO(15 downto 12) => "0000",

      -- only 3 bit color
      I_VIDEO(11)           => ULA_VIDEO_R,
      I_VIDEO(10)           => ULA_VIDEO_R,
      I_VIDEO(9)            => ULA_VIDEO_R,
      I_VIDEO(8)            => ULA_VIDEO_R,

      I_VIDEO(7)            => ULA_VIDEO_G,
      I_VIDEO(6)            => ULA_VIDEO_G,
      I_VIDEO(5)            => ULA_VIDEO_G,
      I_VIDEO(4)            => ULA_VIDEO_G,

      I_VIDEO(3)            => ULA_VIDEO_B,
      I_VIDEO(2)            => ULA_VIDEO_B,
      I_VIDEO(1)            => ULA_VIDEO_B,
      I_VIDEO(0)            => ULA_VIDEO_B,
      I_HSYNC               => hs_int,
      I_VSYNC               => vs_int,

      -- for VGA output, feed these signals to VGA monitor
      O_VIDEO(15 downto 12)=> dummy,
      O_VIDEO(11 downto 8) => VideoR,
      O_VIDEO( 7 downto 4) => VideoG,
      O_VIDEO( 3 downto 0) => VideoB,
      O_HSYNC					=> HSync,
      O_VSYNC					=> VSync,
      O_CMPBLK_N				=> s_cmpblk_n_out,

      --
      CLK                   => clk6,
      CLK_x2                => clk12
      );


  -- select vga or rgb
  -- vido_vga = '1' - vga, = '0' - rgb
  video_select :process (clk24, cpu_reset_n)
  begin
    if cpu_reset_n = '0' then
      video_vga <= '1';
      key_scroll_old <= '1';
    else
      if rising_edge(clk24) then
        key_scroll_old <= key_scroll;
        if (key_scroll = '1' and key_scroll_old = '0') then
          video_vga <= not video_vga;
        end if;
      end if;
    end if;
  end process;
    


  -- video output
  O_VIDEO_R <= VideoR(0) & VideoR(1) & VideoR(2) when video_vga = '1' else
               ULA_VIDEO_R & ULA_VIDEO_R & ULA_VIDEO_R;
  O_VIDEO_G <= VideoG(0) & VideoG(1) & VideoG(2) when video_vga = '1' else
               ULA_VIDEO_G & ULA_VIDEO_G & ULA_VIDEO_G;
  O_VIDEO_B <= VideoB(0) & VideoB(1) & VideoB(2) when video_vga = '1' else
               ULA_VIDEO_B & ULA_VIDEO_B & ULA_VIDEO_B;
  O_HSYNC   <= HSync when video_vga = '1' else
               ULA_SYNC;
  O_VSYNC   <= VSync when video_vga = '1' else
               vs_int;
  -- rgb output
  O_NTSC <= '0';
  O_PAL <= '1';
  ------------------------------------------------------------
  -- VIA
  ------------------------------------------------------------

  inst_via : entity work.M6522
    port map (
      I_RS          => CPU_ADDR(3 downto 0),
      I_DATA        => CPU_DO(7 downto 0),
      O_DATA        => VIA_DO,
      O_DATA_OE_L   => open,

      I_RW_L        => cpu_rw,
      I_CS1         => cont_IOCONTROLn,
      I_CS2_L       => ula_CSIOn,

      O_IRQ_L       => cpu_irq,   -- note, not open drain

      -- PORT A
      I_CA1         => '1',       -- PRT_ACK
      I_CA2         => '1',       -- psg_bdir
      O_CA2         => psg_bdir,  -- via_ca2_out
      O_CA2_OE_L    => open,

      I_PA          => via_pa_in,
      O_PA          => via_pa_out,
      O_PA_OE_L     => via_pa_out_oe,

      -- PORT B
      I_CB1         => K7_TAPEIN,
--		I_CB1         => '0',
      O_CB1         => via_cb1_out,
      O_CB1_OE_L    => via_cb1_oe_l,

      I_CB2         => '1',
      O_CB2         => via_cb2_out,
      O_CB2_OE_L    => via_cb2_oe_l,

      I_PB          => via_in,
      O_PB          => via_out,
      O_PB_OE_L     => via_oe_l,

      --
      RESET_L       => cpu_reset_n,
      I_P2_H        => ula_phi2,
      ENA_4         => '1',
      CLK           => CLK24 
      );

  ------------------------------------------------------------
  -- KEYBOARD
  ------------------------------------------------------------
  inst_key : entity work.keyboard
    port map(
      CLK		=> clk24,
      RESETn	=> pll_locked, -- active high reset

      PS2CLK	=> PS2CLK1,
      PS2DATA	=> PS2DAT1,

      COL		=> via_out(2 downto 0),
      ROWbit	=> KEY_ROW,

      KEY_PG_UP  => key_pg_up,
      KEY_PG_DOWN => key_pg_down,
      KEY_S_LOCK => key_scroll,
      KEY_HOME => key_home,
      KEY_END => key_end

      );

  -- Keyboard
  via_pa_in <= (via_pa_out and not via_pa_out_oe) or (via_pa_in_from_psg and via_pa_out_oe);
  via_in(2 downto 0) <= via_out(2 downto 0);
  via_in(3) <= '0' when ( (KEY_ROW and  not ym_o_ioa)) /= x"00"
               else  '1';
  via_in(7 downto 4) <= x"b"; --via_out(7 downto 4);

--  via_in <= x"F7" when (KEY_ROW or VIA_PA_OUT) = x"FF" else x"FF";


  ------------------------------------------------------------
  -- PSG AY-3-8192
  ------------------------------------------------------------
  inst_psg : entity work.YM2149
    port map (
      I_DA       => via_pa_out,
      O_DA       => via_pa_in_from_psg,
      O_DA_OE_L  => open,
      -- control
      I_A9_L     => '0',
      I_A8       => '1',
      I_BDIR     => via_cb2_out,
      I_BC2      => '1',
      I_BC1      => psg_bdir,
      I_SEL_L    => '1',

      O_AUDIO    => PSG_OUT,
      -- port a
--		I_IOA      => x"00",
      O_IOA      => ym_o_ioa,
--		O_IOA_OE_L => open,
      -- port b
--		I_IOB      => x"00",
--		O_IOB      => open,
--		O_IOB_OE_L => open,

      RESET_L    => cpu_reset_n,
      ENA        => '1',
      CLK        => ula_PHI2
      );

  ------------------------------------------------------------
  -- Sigma Delta DAC
  
  inst_dac : entity work.DAC
    port map (
      clk_i  => clk24,
      resetn => cpu_reset_n,
      dac_i  => PSG_OUT,
      dac_o  => audio_out_tmp
      );

  AUDIO_OUT <= audio_out_tmp;
  AUDIO_OUT2 <= audio_out_tmp;
--         this is my piezo output
  -- onebit : entity work.XSP6X9_onebit
  --   generic map (k => 21)
  --   port map (
  --     nreset => cpu_reset_n,
  --     clk => clk24,
  --     input => PSG_OUT,
  --     output => AUDIO_OUT,
  --     voutput => vaudio_out
  --     );
--   inst_clock_div :entity work.clkdiv
--     generic map (
--       DIVRATIO => 1000000
--       )
--     port map (
--       nreset => cpu_reset_n,
--       clk =>clk6,
--       clkout => led_signal_update
--       );
--   inst_clock_div_multiplex :entity work.clkdiv
--     generic map (
--       DIVRATIO => 3750 -- 200Hz whole refresh
--       )
--     port map (
--       nreset => cpu_reset_n,
--       clk =>clk6,
--       clkout => led_mutiplex_clk
--       );

--   update_led :process(led_signal_update)
--   begin
--     if (rising_edge(led_signal_update))        then
--       -- led_signals_save(15 downto 0) <= CPU_ADDR(15 downto 0);
--       -- --led_signals_save(11 downto  8) <= X"e";
--       -- --led_signals_save(15 downto 12) <= X"f";
--       -- --led_signals_save(19 downto 16) <= X"a";
--       led_signals_save(15 downto 0) <= CPU_ADDR(15 downto 0);
-- --      led_signals_save(13 downto 0)  <= disk_track_addr;
-- --      led_signals_save(15 downto 14) <= (others => '0');
--       led_signals_save(23 downto 16) <= IMAGE_NUMBER_out(7 downto 0);
--       led_signals_save(27 downto 24) <= disk_cur_TRACK(3 downto 0);
--       led_signals_save(29 downto 28) <= disk_cur_TRACK(5 downto 4);
--       led_signals_save(31 downto 30) <= (others => '0');
--     end if;     
--   end process;
      
        
--   led_display : entity work.XSP6X9_Led_Output
--     port map (
--       clk => clk6, --led_mutiplex_clk,
--       inputs (31 downto 0) => led_signals_save,
--       segment => segment,
--       position => position
--       );

--  out_MAPn <= cont_MAPn;
  controller8dos : entity work.controller_8dos
    port map
    (
      CLK_24 => clk24,
      PHI_2 => ula_phi2,
      RW => cpu_rw,
      IO_SELECTn => ULA_CSIOn,
      IO_CONTROLn => cont_IOCONTROLn,
      RESETn => cpu_reset_n,
      O_ROMDISn => cont_ROMDISn,
      O_MAPn => cont_MAPn,
      A => CPU_ADDR(15 downto 0),
      D_IN => CPU_DO,
      D_OUT => cont_D_OUT,
      -- indicator
      disk_a_on => disk_a_on,
      disk_cur_track => disk_cur_track,
      disk_track_addr => disk_track_addr,

      track_ok => track_ok,
      IMAGE_UP => key_pg_up,
      IMAGE_DOWN => key_pg_down,
      IMAGE_NUMBER_out => IMAGE_NUMBER_out,
      
      -- sd card
      SD_DAT => SD_DAT,
      SD_DAT3 => SD_DAT3,
      SD_CMD => SD_CMD,
      SD_CLK => SD_CLK
      );

  led <= disk_a_on;
  ------------------------------------------------------------
  -- Multiplex CPU , RAM/VIA , ROM
  ------------------------------------------------------------

  process
  begin
    wait until rising_edge(clk24);

    -- expansion port
    if    cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn  = '0' and cont_IOCONTROLn = '0' then
      CPU_DI <= cont_D_OUT;
    -- Via
    elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn  = '0' and cont_IOCONTROLn = '1' then
      CPU_DI <= VIA_DO;
    -- ROM
    elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '1' and ula_CSROMn = '0' and cont_ROMDISn = '1' then
      CPU_DI <= ROM_DO;
    -- Read data
    elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '1' and ula_LE_SRAM = '0' then
      CPU_DI <= SRAM_DO;
    end if;
  end process;
  
  -- process -- figure out ram
  -- begin
  --   wait until rising_edge(clk24);
  --   if (cpu_rw = '1')then
  --     DATA_BUS_OUT <= CPU_DI;
  --   else
  --     DATA_BUS_OUT <= CPU_DO;
  --   end if;
  -- end process;

  ------------------------------------------------------------
  -- K7 PORT
  ------------------------------------------------------------
--  K7_TAPEOUT  <= via_out(7);
--	K7_REMOTE   <= via_out(6);
--	K7_AUDIOOUT <= AUDIO_OUT;

------------------------------------------------------------
-- PRINTER PORT
------------------------------------------------------------
--	PRT_DATA    <= via_pa_out;
--	PRT_STR     <= via_out(4);

end RTL;
