-------------------------------------------------------------------------------
--
-- $Id: board_misc_comp_pack-p.vhd,v 1.3 2006/02/26 22:52:37 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package board_misc_comp_pack is

  component dac
    generic (
      msbi_g : integer := 7
    );
    port (
      clk_i   : in  std_logic;
      res_n_i : in  std_logic;
      dac_i   : in  std_logic_vector(msbi_g downto 0);
      dac_o   : out std_logic
    );
  end component;

  component dblscan
    port (
      COL_IN        : in  std_logic_vector(3 downto 0);
      HSYNC_IN      : in  std_logic;
      VSYNC_IN      : in  std_logic;
      COL_OUT       : out std_logic_vector(3 downto 0);
      HSYNC_OUT     : out std_logic;
      VSYNC_OUT     : out std_logic;
      BLANK_OUT     : out std_logic;
      --  NOTE CLOCKS MUST BE PHASE LOCKED !!
      CLK_6         : in  std_logic; -- input pixel clock (6MHz)
      CLK_EN_6M     : in  std_logic;
      CLK_12        : in  std_logic; -- output clock      (12MHz)
      CLK_EN_12M    : in  std_logic
    );
  end component;

  component pcm_sound
    port (
      clk_i              : in  std_logic;
      reset_n_i          : in  std_logic;
      pcm_left_i         : in  signed(8 downto 0);
      pcm_right_i        : in  signed(8 downto 0);
      bit_clk_pad_i      : in  std_logic;
      sync_pad_o         : out std_logic;
      sdata_pad_o        : out std_logic;
      sdata_pad_i        : in  std_logic;
      ac97_reset_pad_n_o : out std_logic;
      led_o              : out std_logic_vector(5 downto 0);
      dpy0_a_o           : out std_logic;
      dpy0_b_o           : out std_logic;
      dpy0_c_o           : out std_logic;
      dpy0_d_o           : out std_logic;
      dpy0_e_o           : out std_logic;
      dpy0_f_o           : out std_logic;
      dpy0_g_o           : out std_logic;
      dpy1_a_o           : out std_logic;
      dpy1_b_o           : out std_logic;
      dpy1_c_o           : out std_logic;
      dpy1_d_o           : out std_logic;
      dpy1_e_o           : out std_logic;
      dpy1_f_o           : out std_logic;
      dpy1_g_o           : out std_logic
    );
  end component;

end board_misc_comp_pack;
