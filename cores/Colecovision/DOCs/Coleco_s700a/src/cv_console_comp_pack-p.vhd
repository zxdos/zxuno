-------------------------------------------------------------------------------
--
-- $Id: cv_console_comp_pack-p.vhd,v 1.3 2006/02/28 22:29:55 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cv_console_comp_pack is

  component cv_console
    generic (
      is_pal_g        : integer := 0;
      compat_rgb_g    : integer := 0
    );
    port (
      clk_i           : in  std_logic;
      clk_en_10m7_i   : in  std_logic;
	   clk_cpu   : out  std_logic;
      reset_n_i       : in  std_logic;
      por_n_o         : out std_logic;
      ctrl_p1_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p2_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p3_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p4_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p5_o       : out std_logic_vector( 1 downto 0);
      ctrl_p6_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p7_i       : in  std_logic_vector( 1 downto 0);
      ctrl_p8_o       : out std_logic_vector( 1 downto 0);
      ctrl_p9_i       : in  std_logic_vector( 1 downto 0);
      bios_rom_a_o    : out std_logic_vector(12 downto 0);
      bios_rom_ce_n_o : out std_logic;
      bios_rom_d_i    : in  std_logic_vector( 7 downto 0);
		
	   boot_rom_d_i    : in  std_logic_vector( 7 downto 0);
		
  --    cpu_ram_a_o     : out std_logic_vector( 10 downto 0);
		cpu_ram_a_o     : out std_logic_vector( 13 downto 0);
		
      cpu_ram_ce_n_o  : out std_logic;
      cpu_ram_we_n_o  : out std_logic;
		cpu_ram_rd_n_o  : out std_logic;
      cpu_ram_d_i     : in  std_logic_vector( 7 downto 0);
		
      cpu_ram_d_o     : out std_logic_vector( 7 downto 0);
      vram_a_o        : out std_logic_vector(13 downto 0);
      vram_we_o       : out std_logic;
      vram_d_o        : out std_logic_vector( 7 downto 0);
      vram_d_i        : in  std_logic_vector( 7 downto 0);
      cart_a_o        : out std_logic_vector(14 downto 0);
      cart_en_80_n_o  : out std_logic;
      cart_en_a0_n_o  : out std_logic;
      cart_en_c0_n_o  : out std_logic;
      cart_en_e0_n_o  : out std_logic;
      cart_d_i        : in  std_logic_vector( 7 downto 0);
      col_o           : out std_logic_vector( 3 downto 0);
      rgb_r_o         : out std_logic_vector( 7 downto 0);
      rgb_g_o         : out std_logic_vector( 7 downto 0);
      rgb_b_o         : out std_logic_vector( 7 downto 0);
      hsync_n_o       : out std_logic;
      vsync_n_o       : out std_logic;
      comp_sync_n_o   : out std_logic;
		blink_led    : out std_logic;
--		dev_sw       : in std_logic;
		boot_o		: out std_logic;
	   cs_n			: out std_logic;
	   sclk			: out std_logic;
	   mosi			: out std_logic;
	   miso			: in std_logic;
		rs232_rxd   : in std_logic;
		rs232_txd   : out std_logic;
		
      audio_o         : out signed(7 downto 0)
    );
  end component;

end cv_console_comp_pack;
