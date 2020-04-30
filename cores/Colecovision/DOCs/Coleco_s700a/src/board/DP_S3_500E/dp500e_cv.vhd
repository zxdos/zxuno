-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- Toplevel of the Spartan3e port for Embedded DP XC3S500E board.
--
-- Download Hex file at 38400,8,n,1 using DIP SW 1 at 'ON'
-- OFF DIP SW 1, Reset to Play
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.Vcomponents.all;

entity DP500e_CV is
  port (
    -- Zefant-DDR FPGA Module Peripherals -----------------------------------
    -- Clock oscillator
    CLK_50MHZ              : in   std_logic;
    ps2_clk						: in   std_logic;
	 ps2_data					: in   std_logic;
	SF_CE_N, SF_WE_N : out std_logic;
		----------------------------------------------------
		-- DDR2 SDRAM-Port-Pins
		----------------------------------------------------
		cntrl0_ddr2_a : out std_logic_vector(12 downto 0) := (others => '0');
		cntrl0_ddr2_ba : out std_logic_vector(1 downto 0) := (others => '0');
		cntrl0_ddr2_ck : out std_logic_vector(0 downto 0) := (others => '0');
		cntrl0_ddr2_ck_n : out std_logic_vector(0 downto 0) := (others => '0');
		cntrl0_ddr2_cke : out std_logic := '0';
		cntrl0_ddr2_cs_n : out std_logic := '0';
		cntrl0_ddr2_ras_n : out std_logic := '0';
		cntrl0_ddr2_cas_n : out std_logic := '0';
		cntrl0_ddr2_we_n : out std_logic := '0';
		cntrl0_ddr2_odt : out std_logic := '0';
		cntrl0_ddr2_dm : out std_logic_vector(1 downto 0) := (others => '0');
		cntrl0_ddr2_dqs_n : inout std_logic_vector(1 downto 0) := (others => '0');
		cntrl0_ddr2_dqs : inout std_logic_vector(1 downto 0) := (others => '0');
		cntrl0_ddr2_dq : inout std_logic_vector(15 downto 0) := (others => '0');
		cntrl0_rst_dqs_div_in : in std_logic;
		cntrl0_rst_dqs_div_out : out std_logic;	
		----------------------------------------------------		

  
    -- User Interface
    reset               : in    std_logic;
    leds                : out   std_logic_vector(7 downto 0) ;
	 LED_YELLOW_OUT		: out std_logic;	
--	 dev_sw						: in std_logic;
	 
	 
	   audio_l_o     : out   std_logic;
      audio_r_o     : out   std_logic;
	 

    vid_r                    : out   std_logic_vector(3 downto 0);
    vid_g                    : out   std_logic_vector(3 downto 0);
    vid_b                    : out   std_logic_vector(3 downto 0);
    vid_hsync                : out   std_logic;
    vid_vsync                : out   std_logic;
                                     

	   sclk  	:out std_logic;
		mosi  	:out std_logic;
		miso  	:in std_logic;
		cs_n    	:out std_logic;
		
	-- LCD
	lcd_rs : out std_logic; 
	lcd_rw : out std_logic; 
	lcd_e : out std_logic;
	lcd_0 : out std_logic; 
	lcd_1 : out std_logic; 
	lcd_2 : out std_logic; 
	lcd_3 : out std_logic; 
	lcd_4 : out std_logic; 
	lcd_5 : out std_logic; 
	lcd_6 : out std_logic; 
	lcd_7 : out std_logic;

    -- RS 232
    rs232_rxd                : in    std_logic;
    rs232_txd                : out   std_logic
  );
end DP500e_CV;


library ieee;
use ieee.numeric_std.all;

use work.cv_console_comp_pack.cv_console;
use work.tech_comp_pack.generic_ram;
use work.board_misc_comp_pack.pcm_sound;
use work.board_misc_comp_pack.dblscan;
use work.cv_keys_pack.all;
use work.vdp18_col_pack.all;

architecture struct of DP500e_CV is

component  lcd 
port(
	CLK    : in std_logic; 
	LCD_RS : out std_logic; 
	LCD_RW : out std_logic; 
	LCD_E : out std_logic;
	LCD_0 : out std_logic; 
	LCD_1 : out std_logic; 
	LCD_2 : out std_logic; 
	LCD_3 : out std_logic; 
	LCD_4 : out std_logic; 
	LCD_5 : out std_logic; 
	LCD_6 : out std_logic; 
	LCD_7 : out std_logic
);
end component lcd;



--component clk714m 
--   port ( CLKIN_IN   : in    std_logic; 
--          RST_IN     : in    std_logic; 
--          CLKFX_OUT  : out   std_logic; 
--          CLK0_OUT   : out   std_logic; 
--          LOCKED_OUT : out   std_logic);
--end component clk714m;

--  component cv_clk
--    port (
--      clkin_i    : in  std_logic;
--      locked_o   : out std_logic;
--      clk_21m3_o : out std_logic
--    );
--  end component;

component clk21m6 
   port ( CLKIN_IN   : in    std_logic; 
          RST_IN     : in    std_logic; 
          CLKFX_OUT  : out   std_logic; 
          CLK0_OUT   : out   std_logic; 
          LOCKED_OUT : out   std_logic);
end component clk21m6;



	COMPONENT Clock_VHDL is
	PORT (
		clk_in_133MHz : in std_logic;
		clk_out_1Hz : out std_logic
	);
	END COMPONENT Clock_VHDL;
	
component clk133m_dcm is
   port ( CLKIN_IN        : in    std_logic; 
          CLKFX_OUT       : out   std_logic; 
          CLKIN_IBUFG_OUT : out   std_logic; 
          CLK0_OUT        : out   std_logic; 
			 CLK2X_OUT       : out   std_logic; 
          LOCKED_OUT      : out   std_logic);
end component clk133m_dcm;


COMPONENT DDR2_Control_VHDL is
	PORT (
		reset_in : in std_logic;
		clk_in : in std_logic;
		clk90_in : in std_logic;
		
		maddr   : in std_logic_vector(15 downto 0);
		mdata_i : in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(7 downto 0);
		mwe	  : in std_logic;
		mrd    : in std_logic;
		
		init_done : in std_logic;
		command_register : out std_logic_vector(2 downto 0);
		input_adress : out std_logic_vector(24 downto 0);
		input_data : out std_logic_vector(31 downto 0);
		output_data : in std_logic_vector(31 downto 0);
		cmd_ack : in std_logic;
		data_valid : in std_logic;
		burst_done : out std_logic;
		auto_ref_req : in std_logic
	);
	END COMPONENT DDR2_Control_VHDL;



COMPONENT DDR2_Ram_Core is
	PORT (
		cntrl0_ddr2_dq : inout std_logic_vector(15 downto 0);
		cntrl0_ddr2_a : out std_logic_vector(12 downto 0);
		cntrl0_ddr2_ba : out std_logic_vector(1 downto 0);
		cntrl0_ddr2_cke : out std_logic;
		cntrl0_ddr2_cs_n : out std_logic;
		cntrl0_ddr2_ras_n : out std_logic;
		cntrl0_ddr2_cas_n : out std_logic;
		cntrl0_ddr2_we_n : out std_logic;
		cntrl0_ddr2_odt : out std_logic;
		cntrl0_ddr2_dm : out std_logic_vector(1 downto 0);
		cntrl0_rst_dqs_div_in : in std_logic;
		cntrl0_rst_dqs_div_out : out std_logic;		
		sys_clk_in : in std_logic;
		reset_in_n : in std_logic;
		cntrl0_burst_done : in std_logic;
		cntrl0_init_done : out std_logic;
		cntrl0_ar_done : out std_logic;
		cntrl0_user_data_valid : out std_logic;
		cntrl0_auto_ref_req : out std_logic;
		cntrl0_user_cmd_ack : out std_logic;
		cntrl0_user_command_register : in std_logic_vector(2 downto 0);
		cntrl0_clk_tb : out std_logic;
		cntrl0_clk90_tb : out std_logic;
		cntrl0_sys_rst_tb : out std_logic;
		cntrl0_sys_rst90_tb : out std_logic;
		cntrl0_sys_rst180_tb : out std_logic;
		cntrl0_user_output_data : out std_logic_vector(31 downto 0);
		cntrl0_user_input_data : in std_logic_vector(31 downto 0);
		cntrl0_user_data_mask : in std_logic_vector(3 downto 0);
		cntrl0_user_input_address : in std_logic_vector(24 downto 0);
		cntrl0_ddr2_dqs : inout std_logic_vector(1 downto 0);
		cntrl0_ddr2_dqs_n : inout std_logic_vector(1 downto 0);
		cntrl0_ddr2_ck : out std_logic_vector(0 downto 0);
		cntrl0_ddr2_ck_n : out std_logic_vector(0 downto 0)
	);
	END COMPONENT DDR2_Ram_Core;	





--  component coleco_bios
--    port (
--      Clk : in  std_logic;
--      A   : in  std_logic_vector(12 downto 0);
--      D   : out std_logic_vector( 7 downto 0)
--    );
--  end component;

  signal dcm_locked_s        : std_logic;
  signal clk_21m3_s          : std_logic;
  signal clk_cnt_q           : unsigned(1 downto 0);
  signal clk_en_10m7_q       : std_logic;
  signal clk_en_5m37_q       : std_logic;
  signal reset_sync_n_q      : std_logic_vector(1 downto 0);
  signal reset_n_s           : std_logic;

  signal but_a_s,
         but_b_s,
         but_x_s,
         but_y_s,
         but_start_s,
         but_sel_s,
         but_tl_s,
         but_tr_s            : std_logic_vector( 1 downto 0);
  signal but_up_s,
         but_down_s,
         but_left_s,
         but_right_s         : std_logic_vector( 1 downto 0);

  signal ctrl_p1_s,
         ctrl_p2_s,
         ctrl_p3_s,
         ctrl_p4_s,
         ctrl_p5_s,
         ctrl_p6_s,
         ctrl_p7_s,
         ctrl_p8_s,
         ctrl_p9_s           : std_logic_vector( 2 downto 1);

  signal bios_rom_a_s        : std_logic_vector(12 downto 0);
  signal bios_rom_ce_n_s     : std_logic;
  signal bios_rom_d_s        : std_logic_vector( 7 downto 0);

  --signal cpu_ram_a_s         : std_logic_vector( 10 downto 0);
  signal cpu_ram_a_s         : std_logic_vector( 13 downto 0);
  
  signal cpu_ram_ce_n_s      : std_logic;
  signal cpu_ram_we_n_s      : std_logic;
  signal cpu_ram_rd_n_s      : std_logic;
  signal cpu_ram_d_to_cv_s,
         cpu_ram_d_from_cv_s : std_logic_vector( 7 downto 0);
  signal cpu_ram_we_s        : std_logic;

  signal vram_a_s            : std_logic_vector(13 downto 0);
  signal vram_we_s           : std_logic;
  signal vram_d_to_cv_s,
         vram_d_from_cv_s    : std_logic_vector( 7 downto 0);

  signal cart_a_s            : std_logic_vector(14 downto 0);
  signal cart_d_s            : std_logic_vector( 7 downto 0);
  signal cart_en_80_n_s,
         cart_en_a0_n_s,
         cart_en_c0_n_s,
         cart_en_e0_n_s      : std_logic;

  signal rgb_col_s           : std_logic_vector( 3 downto 0);
  signal rgb_hsync_n_s,
         rgb_vsync_n_s       : std_logic;
  signal rgb_hsync_s,
         rgb_vsync_s         : std_logic;

  signal vga_col_s           : std_logic_vector( 3 downto 0);
  signal vga_hsync_s,
         vga_vsync_s         : std_logic;

  signal signed_audio_s      : signed(7 downto 0);
  signal dac_audio_s         : std_logic_vector( 7 downto 0);
  signal audio_s             : std_logic;

	signal ps2_kclk             : std_logic;
	signal ps2_kdat             : std_logic;
  
	signal ps2_keys_s			    : std_logic_vector(15 downto 0);
	signal ps2_joy_s			    : std_logic_vector(15 downto 0);
--	signal clk10             : std_logic;
  signal reset_n			: std_logic;

	signal rxd  : std_logic;
   signal txd :  std_logic;


signal boot_s     : std_logic;
signal boot_rom_d_s   : std_logic_vector(7 downto 0);
--signal out1_n_s      : std_logic;
signal soft_reset_n : std_logic:='1';


	signal mwe		: std_logic;
	signal mrd		: std_logic;


	signal mwe_delayed		: std_logic;
   signal mrd_delayed		: std_logic;
   signal we_rise		: std_logic;
   signal rd_rise		: std_logic;
	
	signal dreset		: std_logic;
	
	signal busy		: std_logic;
	signal cmd		: std_logic_vector(1 downto 0);
	signal cmd_valid		: std_logic;
	signal data_valid		: std_logic;
	signal data_req		: std_logic;
	
	---------------------------------------
	signal v_reset_n : std_logic;
	signal v_reset_p : std_logic;
	signal v_debounce : std_logic_vector(7 downto 0) := (others => '0');
	signal v_risingedge : std_logic_vector(3 downto 0) := (others => '0');
	
	-- DDR2 SDRAM-Leitungen -----------------------------------------
	signal clk_tb : std_logic;
	signal clk90_tb : std_logic;
	signal burst_done : std_logic;
	signal user_command_register : std_logic_vector(2 downto 0) := (others => '0');
	signal user_data_mask : std_logic_vector(3 downto 0):= (others => '0');
	signal user_input_data : std_logic_vector(31 downto 0);
	signal user_input_address : std_logic_vector(24 downto 0);
	signal v_init_done : std_logic;
	signal ar_done : std_logic;
	signal auto_ref_req : std_logic;
	signal user_cmd_ack : std_logic;
	signal user_data_valid : std_logic;
	signal user_output_data	: std_logic_vector(31 downto 0);
	
	signal CLK_130M : std_logic;
	signal CLKB_130M : std_logic;
   signal CLK50M : std_logic;
 signal clk3m58 : std_logic;
 
	signal SDRAM_DO: std_logic_vector(7 downto 0);
	signal cart_d_o: std_logic_vector(7 downto 0);
	signal cart_rom_we_s  : std_logic;
	signal cart_rom_we_n_s  : std_logic;
	
	signal cart_rom_ce_n_s : std_logic;
	signal maddr: std_logic_vector(15 downto 0);
	 signal clk7m : std_logic;
	
	
begin

SF_WE_N <= '1';
SF_CE_N <= '1';

  reset_n <= not reset;
  ps2_kclk <= ps2_clk;
  ps2_kdat <= ps2_data;
  
  leds(4 downto 1) <= "0000";
  leds(6 downto 5) <= "00";
  leds(0) <= boot_s;
  --rs232_txd <= txd;
  --rxd <= rs232_rxd;
  
 -- May ned to add constraints to the UCF IOSTANDARD=LVCMOS33 to avoid error ..lak
	clk133 : clk133m_dcm
   port map( CLKIN_IN    => CLK_50MHZ, 
          CLKFX_OUT      => CLK_130M, --160MHZ OUT
          CLKIN_IBUFG_OUT => open, 
          CLK0_OUT        => clk50m, 
			 CLK2X_OUT       => open,
          LOCKED_OUT      => open);
			 
	 clk_obuf : OBUF port map ( I => CLK_130M, O => CLKB_130M ); 

  
  -----------------------------------------------------------------------------
  -- Clock Generator
  -----------------------------------------------------------------------------
--  DP500e_clk : cv_clk
--    port map (
--      clkin_i    => CLK_50MHZ,
--      locked_o   => dcm_locked_s,
--      clk_21m3_o => clk_21m3_s
--    );

--u_clk7m : clk714m
--  port map ( CLKIN_IN  => clk50m, --clk_tb, --CLK_130M, 
--          RST_IN     => RESET, 
--          CLKFX_OUT  => clk7m, 
--          CLK0_OUT  => open,
--          LOCKED_OUT => open);


lcd16x2 : lcd
  port map (
	CLK    => clk50m,
	LCD_RS => lcd_rs,
	LCD_RW => lcd_rw,
	LCD_E => lcd_e,
	LCD_0 => lcd_0,
	LCD_1 => lcd_1,
	LCD_2 => lcd_2,
	LCD_3 => lcd_3,
	LCD_4 => lcd_4,
	LCD_5 => lcd_5,
	LCD_6 => lcd_6,
	LCD_7 => lcd_7
	);
	
	
cv_clk : clk21m6
  port map ( CLKIN_IN  => clk50m, --clk_tb, --CLK_130M, 
          RST_IN     => RESET, 
          CLKFX_OUT  => clk_21m3_s, 
          CLK0_OUT  => open,
          LOCKED_OUT => dcm_locked_s);


	INST_Clock_VHDL : Clock_VHDL
	PORT MAP (	
		clk_in_133MHz => clk_tb,		
		clk_out_1Hz => LED_YELLOW_OUT
	);

  -----------------------------------------------------------------------------
  -- Process reset_sync
  --
  -- Purpose:
  --   Synchronizes the dcm_locked signal for generating the external reset.
  --
  reset_sync: process (clk_21m3_s, dcm_locked_s, reset_n)
  begin
    if dcm_locked_s = '0' or reset_n = '0' then
      reset_sync_n_q <= (others => '0');
    elsif clk_21m3_s'event and clk_21m3_s = '1' then
      reset_sync_n_q(0) <= '1';
      reset_sync_n_q(1) <= reset_sync_n_q(0);
    end if;
  end process reset_sync;
  --
  --reset_n_s <= reset_sync_n_q(1);
  reset_n_s <= reset_sync_n_q(1) and soft_reset_n;

  -----------------------------------------------------------------------------
  -- Process clk_cnt
  --
  -- Purpose:
  --   Counts the base clock and derives the clock enables.
  --
  clk_cnt: process (clk_21m3_s, reset_n_s)
  begin
    if reset_n_s = '0' then
      clk_cnt_q     <= (others => '0');
      clk_en_10m7_q <= '0';
      clk_en_5m37_q <= '0';

    elsif clk_21m3_s'event and clk_21m3_s = '1' then
	 
	-- clk10<=not clk_21m3_s;
      -- Clock counter --------------------------------------------------------
      if clk_cnt_q = 3 then
        clk_cnt_q <= (others => '0');
      else
        clk_cnt_q <= clk_cnt_q + 1;
      end if;

      -- 10.7 MHz clock enable ------------------------------------------------
      case clk_cnt_q is
        when "01" | "11" =>
          clk_en_10m7_q <= '1';
        when others =>
          clk_en_10m7_q <= '0';
      end case;

      -- 5.37 MHz clock enable ------------------------------------------------
      case clk_cnt_q is
        when "11" =>
          clk_en_5m37_q <= '1';
        when others =>
          clk_en_5m37_q <= '0';
      end case;

    end if;
  end process clk_cnt;
  

  -----------------------------------------------------------------------------
  -- The Colecovision console
  -----------------------------------------------------------------------------
  cv_console_b : cv_console
    generic map (
      is_pal_g        => 0,
      compat_rgb_g    => 0
    )
    port map (
      clk_i           => clk_21m3_s,
      clk_en_10m7_i   => clk_en_10m7_q,
		clk_cpu   		=> clk3m58,
		
      reset_n_i       => reset_n_s,
      por_n_o         => open,
      ctrl_p1_i       => ctrl_p1_s,
      ctrl_p2_i       => ctrl_p2_s,
      ctrl_p3_i       => ctrl_p3_s,
      ctrl_p4_i       => ctrl_p4_s,
      ctrl_p5_o       => ctrl_p5_s,
      ctrl_p6_i       => ctrl_p6_s,
      ctrl_p7_i       => ctrl_p7_s,
      ctrl_p8_o       => ctrl_p8_s,
      ctrl_p9_i       => ctrl_p9_s,
      bios_rom_a_o    => bios_rom_a_s,
      bios_rom_ce_n_o => bios_rom_ce_n_s,
      bios_rom_d_i    => bios_rom_d_s,
		
		boot_rom_d_i    => boot_rom_d_s,
      
		cpu_ram_a_o     => cpu_ram_a_s,    
		cpu_ram_ce_n_o  => cpu_ram_ce_n_s,
      cpu_ram_we_n_o  => cpu_ram_we_n_s, 
		cpu_ram_rd_n_o  => cpu_ram_rd_n_s, 
		cpu_ram_d_i     => cpu_ram_d_to_cv_s,
      cpu_ram_d_o     => cpu_ram_d_from_cv_s,
      vram_a_o        => vram_a_s,
      vram_we_o       => vram_we_s,
      vram_d_o        => vram_d_from_cv_s,
      vram_d_i        => vram_d_to_cv_s,
      cart_a_o        => cart_a_s,
      cart_en_80_n_o  => cart_en_80_n_s,
      cart_en_a0_n_o  => cart_en_a0_n_s,
      cart_en_c0_n_o  => cart_en_c0_n_s,
      cart_en_e0_n_o  => cart_en_e0_n_s,
      cart_d_i        => cart_d_s,
      col_o           => rgb_col_s,
      rgb_r_o         => open,
      rgb_g_o         => open,
      rgb_b_o         => open,
      hsync_n_o       => rgb_hsync_n_s,
      vsync_n_o       => rgb_vsync_n_s,
      comp_sync_n_o   => open,
		blink_led       => leds(7),
--		dev_sw      => dev_sw,
     boot_o			 	=>  boot_s,
	   cs_n			    => cs_n,
	   sclk			    => sclk,
	   mosi			    => mosi,
	   miso			    => miso,
		rs232_rxd       =>rs232_rxd,
		rs232_txd       =>rs232_txd,
      audio_o         => signed_audio_s(7 downto 0)
    );

  rgb_hsync_s <= not rgb_hsync_n_s;
  rgb_vsync_s <= not rgb_vsync_n_s;
  --audio_s(0)  <= '0';


  -----------------------------------------------------------------------------
  -- BIOS ROM
  -----------------------------------------------------------------------------
-- Block Ram
  coleco_bios_b : ENTITY coleco_bios
    port map (
      Clk => clk_21m3_s,
      ADDR   => bios_rom_a_s,
      DATA   => bios_rom_d_s
	
    );

	bootrom_b : ENTITY boot_rom
    port map (
      Clk => clk_21m3_s,
		ENA => boot_s,
      ADDR   => cart_a_s(12 downto 0),
      DATA   => boot_rom_d_s
	
    );



--- Distributed Rom
--coleco_bios_b : ENTITY coleco_bios
--    port map (
--      Clk => clk_21m3_s,
--      A   => bios_rom_a_s,
--      D   => bios_rom_d_s
--    );
  -----------------------------------------------------------------------------
  -- CPU RAM  
  -----------------------------------------------------------------------------
  	
--  cpu_ram_we_s <= clk_en_10m7_q and
--                  not (cpu_ram_we_n_s or cpu_ram_ce_n_s);
						
  cpu_ram_we_s <= not (cpu_ram_we_n_s or cpu_ram_ce_n_s);
						
	cpu_ram_b : entity generic_ram
    generic map (
      addr_width_g => 10, --1K 
      data_width_g => 8
    )
    port map (
      clk_i => clk_21m3_s,
      a_i   => cpu_ram_a_s(9 downto 0),
      we_i  => cpu_ram_we_s,
      d_i   => cpu_ram_d_from_cv_s,
      d_o   => cpu_ram_d_to_cv_s
    );
  -----------------------------------------------------------------------------
  -- VRAM
  -----------------------------------------------------------------------------
  vram_b : generic_ram
    generic map (
      addr_width_g => 14,
      data_width_g => 8
    )
    port map (
      clk_i => clk_21m3_s,
      a_i   => vram_a_s,
      we_i  => vram_we_s,
      d_i   => vram_d_from_cv_s,
      d_o   => vram_d_to_cv_s
    );


--sram_lb_n <= cart_a_s(0);
--sram_ub_n <= not cart_a_s(0);
--sram_oe_n <= '0';
--sram_ce_n <= cart_rom_ce_n_s;
--
-- sram_a(17 downto 14) <= "0000";  --(others => '0');
-- sram_a(13 downto 0) <= cart_a_s(14 downto 1);
--
--cart_rom_we_s <=  not (cpu_ram_we_n_s) and boot_s;
--cart_rom_ce_n_s <= cart_en_80_n_s and cart_en_a0_n_s and cart_en_c0_n_s and cart_en_e0_n_s;
--sram_we_n <= not cart_rom_we_s;
--
--sram_d( 7 downto 0) <= cpu_ram_d_from_cv_s when (cart_rom_we_s='1' and cart_rom_ce_n_s='0' and cart_a_s(0)='0')
--   else "ZZZZZZZZ";
--
--sram_d( 15 downto 8) <= cpu_ram_d_from_cv_s when (cart_rom_we_s='1' and cart_rom_ce_n_s='0' and cart_a_s(0)='1')
--   else "ZZZZZZZZ";
--	
--cart_d_s <=   sram_d(7 downto 0)  when (cart_rom_ce_n_s='0' and cart_a_s(0)='0')
--         else sram_d(15 downto 8) when (cart_rom_ce_n_s='0' and cart_a_s(0)='1')
--         else "ZZZZZZZZ";	
--  
	
	-- PS/2 keyboard interface
	ps2if_inst : entity work.colecoKeyboard
		port map
		(
		clk   => clk_21m3_s,
		reset	=> not reset_n_s,

		-- inputs from PS/2 port
		ps2_clk 	=> ps2_kclk,
		ps2_data => ps2_kdat,

		-- user outputs
		keys	=> ps2_keys_s,
		joy	=> ps2_joy_s
	);

-----------------------------------------------------------------------------
  -- Process pad_ctrl
  --
  -- Purpose:
  --   Maps the gamepad signals to the controller buses of the console.
  --
  pad_ctrl: process (ctrl_p5_s, ctrl_p8_s,
                     but_a_s, but_b_s,
                     but_up_s, but_down_s, but_left_s, but_right_s,
                     but_x_s, but_y_s,
                     but_sel_s, but_start_s,
                     but_tl_s, but_tr_s)
    variable key_v : natural range cv_keys_t'range;
	 
	 
  begin
    -- quadrature device not implemented
    ctrl_p7_s          <= "11";
    ctrl_p9_s          <= "11";

    for idx in 1 to 2 loop -- was 2
      if    ctrl_p5_s(idx) = '0' and ctrl_p8_s(idx) = '1' then
        -- keys and right button enabled --------------------------------------
        -- keys not fully implemented

        key_v := cv_key_none_c;

        --if but_tl_s(idx-1) = '0' then
          if ps2_keys_s(13) = '1' then
            -- KEY 1
            key_v := cv_key_1_c;
          elsif ps2_keys_s(7) = '1' then
            -- KEY 2
            key_v := cv_key_2_c;
          elsif ps2_keys_s(12) = '1' then
            -- KEY 3
            key_v := cv_key_3_c;
          elsif ps2_keys_s(2) = '1' then
            -- KEY 4
            key_v := cv_key_4_c;
				
				
			 elsif ps2_keys_s(3) = '1' then
            -- KEY 5
            key_v := cv_key_5_c;	
			 elsif ps2_keys_s(14) = '1' then
            -- KEY 6
            key_v := cv_key_6_c;
          elsif ps2_keys_s(5) = '1' then
            -- KEY 7
            key_v := cv_key_7_c;				
			 elsif ps2_keys_s(1) = '1' then
            -- KEY 8
            key_v := cv_key_8_c;				
			 elsif ps2_keys_s(11) = '1' then
            -- KEY 9
            key_v := cv_key_9_c;
			 elsif ps2_keys_s(10) = '1' then
            -- KEY 0
            key_v := cv_key_0_c;
				
          elsif ps2_keys_s(6) = '1' then
            -- KEY *
            key_v := cv_key_asterisk_c;
          elsif ps2_keys_s(9) = '1' then
            -- KEY #
            key_v := cv_key_number_c;
          end if;
        --end if;

        ctrl_p1_s(idx) <= cv_keys_c(key_v)(1);
        ctrl_p2_s(idx) <= cv_keys_c(key_v)(2);
        ctrl_p3_s(idx) <= cv_keys_c(key_v)(3);
        ctrl_p4_s(idx) <= cv_keys_c(key_v)(4);

        if (idx = 1) then
          ctrl_p6_s(idx) <= not ps2_keys_s(0); -- button right (0)
        else
          ctrl_p6_s(idx) <= not ps2_joy_s(4);
        end if;
		  
--------------------------------------------------------------------
-- soft reset to get to cart menu : use ps2 ESC key in keys(8)
		   if ps2_keys_s(8) ='1' then
		      soft_reset_n <= '0';
			else
				soft_reset_n <= '1';
			end if;

------------------------------------------------------------------------

      elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
        -- joystick and left button enabled -----------------------------------
        ctrl_p1_s(idx) <= not ps2_joy_s(0);	-- up
        ctrl_p2_s(idx) <= not ps2_joy_s(1); -- down
        ctrl_p3_s(idx) <= not ps2_joy_s(2); -- left
        ctrl_p4_s(idx) <= not ps2_joy_s(3); -- right
		  
		 if (idx = 1) then
			 ctrl_p6_s(idx) <= not ps2_joy_s(4); -- button left (4)
		 else
			 ctrl_p6_s(idx) <= not ps2_keys_s(0); -- button right(0)
		  end if;
			
      else
        -- nothing active -----------------------------------------------------
        ctrl_p1_s(idx) <= '1';
        ctrl_p2_s(idx) <= '1';
        ctrl_p3_s(idx) <= '1';
        ctrl_p4_s(idx) <= '1';
        ctrl_p6_s(idx) <= '1';
        ctrl_p7_s(idx) <= '1';
      end if;
    end loop;
  end process pad_ctrl;	 
 
 
  -----------------------------------------------------------------------------
  -- VGA Scan Doubler
  -----------------------------------------------------------------------------
  dblscan_b : dblscan
    port map (
      COL_IN     => rgb_col_s,
      HSYNC_IN   => rgb_hsync_s,
      VSYNC_IN   => rgb_vsync_s,
      COL_OUT    => vga_col_s,
      HSYNC_OUT  => vga_hsync_s,
      VSYNC_OUT  => vga_vsync_s,
      BLANK_OUT  => open,
      CLK_6      => clk_21m3_s,
      CLK_EN_6M  => clk_en_5m37_q,
      CLK_12     => clk_21m3_s,
      CLK_EN_12M => clk_en_10m7_q
    );

  -----------------------------------------------------------------------------
  -- Convert signed audio data of the console (range 127 to -128) to
  -- simple unsigned value. 
  -----------------------------------------------------------------------------
  dac_audio_s <= std_logic_vector(unsigned(signed_audio_s + 128));

  dac_b : entity work.dac
    generic map (
      msbi_g => 7
    )
    port map (
      clk_i   => clk_21m3_s,
      res_n_i => reset_n_s,
      dac_i   => dac_audio_s,
      dac_o   => audio_s
    );

  audio_r_o <= audio_s;
  audio_l_o <= audio_s;

--R_inst : PULLUP
--port map (
--O => vid_r
--);
--
--G_inst : PULLUP
--port map (
--O => vid_g
--);
--
--B_inst : PULLUP
--port map (
--O => vid_b
--);


  -----------------------------------------------------------------------------
  -- VGA Output
  -----------------------------------------------------------------------------
  -- Process vga_col
  --
  -- Purpose:
  --   Converts the color information (doubled to VGA scan) to RGB values.
  --
  vga_col: process (clk_21m3_s, reset_n_s)
    variable vga_col_v : natural range 0 to 15;
    variable vga_r_v,
             vga_g_v,
             vga_b_v   : rgb_val_t;
  begin
    if reset_n_s = '0' then
      vid_r <= (others => '0');
      vid_g <= (others => '0');
      vid_b <= (others => '0');
	
    elsif clk_21m3_s'event and clk_21m3_s = '1' then
      if clk_en_10m7_q = '1' then
        vga_col_v := to_integer(unsigned(vga_col_s));
        vga_r_v   := full_rgb_table_c(vga_col_v)(r_c);
        vga_g_v   := full_rgb_table_c(vga_col_v)(g_c);
        vga_b_v   := full_rgb_table_c(vga_col_v)(b_c); 
		  
        vid_r     <= std_logic_vector(to_unsigned(vga_r_v, 8)/16);
        vid_g     <= std_logic_vector(to_unsigned(vga_g_v, 8)/16);
        vid_b     <= std_logic_vector(to_unsigned(vga_b_v, 8)/16);
		  
      end if;

    end if;
  end process vga_col;
  --
  vid_hsync         <= not vga_hsync_s;
  vid_vsync         <= not vga_vsync_s;
  
  
  
--cart_rom_we_s <=  (not cpu_ram_we_n_s) and boot_s;
--
--mrd <= ( not cart_rom_ce_n_s ) and cpu_ram_we_n_s; 

 cart_rom_ce_n_s <= cart_en_80_n_s and cart_en_a0_n_s and cart_en_c0_n_s and cart_en_e0_n_s;
 mrd <= '1' when (cart_rom_ce_n_s = '0' and cpu_ram_rd_n_s='0') else '0';
 mwe <= '1' when (cart_rom_ce_n_s = '0' and cpu_ram_we_n_s='0' and boot_s='1') else '0'; 

--mwe <= ( not cart_rom_ce_n_s ) and cart_rom_we_s ;


--cart_d_o <= cpu_ram_d_from_cv_s when cart_rom_we_s='1' and cart_rom_ce_n_s='0'
--   else "ZZZZZZZZ";
--
cart_d_s <= SDRAM_DO when mrd='1' --cart_rom_ce_n_s='0'
   else "ZZZZZZZZ";	 
  
  
-----------------------------------------------------------------------

--	 mrd  <= '1' when ( sdramcs_n='0' and T80_RD_n='0' ) else '0';
--	 mwe  <= '1' when ( sdramcs_n='0' and T80_WR_n='0' ) else '0';	  
-----------------------------------------------------------------------	
---- mrd and mwe delayed by 1T

delay: 	process(mrd, mwe,  clk3m58)
		begin
			if rising_edge( clk3m58) then
				mrd_delayed <= mrd;
				mwe_delayed <= mwe;
			end if;
		end process delay;
	
rising_edge_flags: process (mwe, mwe_delayed, mrd, mrd_delayed) is
		begin
		
			rd_rise <= mrd and not mrd_delayed;
			we_rise <= mwe and not mwe_delayed;
		
end process rising_edge_flags;

maddr <= '0' & cart_a_s(14 downto 0);
 	--------------------------------------------------
	-- Create and connect Instantz a resolved part
	--Order to control the VHDL DDR2 -
	--------------------------------------------------
	INST_DDR2_Control_VHDL : DDR2_Control_VHDL
	PORT MAP (
		reset_in => Reset,
		clk_in => clk_tb,
		clk90_in => clk90_tb,
  
		maddr   => maddr, --'0' & cart_a_s(14 downto 0)
		mdata_i => cpu_ram_d_from_cv_s,
		data_out => SDRAM_DO, --cart_d_s,	-- to host
		mwe	  => we_rise,
		mrd     => rd_rise,
		
	-- ddr2	
	   init_done => v_init_done, --in
		command_register => user_command_register, --out
		input_adress => user_input_address, --out
		input_data => user_input_data, --out 
		output_data => user_output_data, --in
		cmd_ack => user_cmd_ack, --in
		data_valid => user_data_valid, --in
		burst_done => burst_done, --out
		auto_ref_req => auto_ref_req --in
	
	);
		  
--------------------------------------------------
	-- Instantz einer Componente erzeugen und verbinden
	-- DDR2_RAM_Modul (vom MIG generiert)
	--------------------------------------------------
	INST_DDR2_RAM_CORE : DDR2_Ram_Core
	PORT MAP (
		sys_clk_in => CLKB_130M, --CLK_50MHZ,--CLK_AUX_IN,
		reset_in_n => Reset_n,
		cntrl0_burst_done => burst_done,
		cntrl0_user_command_register => user_command_register,
		cntrl0_user_data_mask => user_data_mask,
		cntrl0_user_input_data => user_input_data,
		cntrl0_user_input_address => user_input_address,
		cntrl0_init_done => v_init_done,
		cntrl0_ar_done => ar_done,
		cntrl0_auto_ref_req => auto_ref_req,
		cntrl0_user_cmd_ack => user_cmd_ack,
		cntrl0_clk_tb => clk_tb,
		cntrl0_clk90_tb => clk90_tb,
		cntrl0_sys_rst_tb => open,
		cntrl0_sys_rst90_tb => open,
		cntrl0_sys_rst180_tb => open,
		cntrl0_user_data_valid => user_data_valid,
		cntrl0_user_output_data => user_output_data,			
		cntrl0_ddr2_ras_n => cntrl0_ddr2_ras_n,
		cntrl0_ddr2_cas_n => cntrl0_ddr2_cas_n,
		cntrl0_ddr2_we_n => cntrl0_ddr2_we_n,
		cntrl0_ddr2_cs_n => cntrl0_ddr2_cs_n,
		cntrl0_ddr2_cke => cntrl0_ddr2_cke,
		cntrl0_ddr2_dm => cntrl0_ddr2_dm,
		cntrl0_ddr2_ba => cntrl0_ddr2_ba,
		cntrl0_ddr2_a => cntrl0_ddr2_a,
		cntrl0_ddr2_ck => cntrl0_ddr2_ck,
		cntrl0_ddr2_ck_n => cntrl0_ddr2_ck_n,
		cntrl0_ddr2_dqs => cntrl0_ddr2_dqs,
		cntrl0_ddr2_dqs_n => cntrl0_ddr2_dqs_n,
		cntrl0_ddr2_dq => cntrl0_ddr2_dq,
		cntrl0_ddr2_odt => cntrl0_ddr2_odt,		
		cntrl0_rst_dqs_div_in => cntrl0_rst_dqs_div_in,
		cntrl0_rst_dqs_div_out => cntrl0_rst_dqs_div_out);	 

end struct;
