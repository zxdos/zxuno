-------------------------------------------------------------------------------
--
-- $Id: vdp18_core_comp_pack-p.vhd,v 1.10 2006/02/28 22:30:41 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package vdp18_core_comp_pack is

  component vdp18_core
    generic (
      is_pal_g      : integer := 0;
      compat_rgb_g  : integer := 0
    );
    port (
      clk_i         : in  std_logic;
      clk_en_10m7_i : in  std_logic;
      reset_n_i     : in  std_logic;
      csr_n_i       : in  std_logic;
      csw_n_i       : in  std_logic;
      mode_i        : in  std_logic;
      int_n_o       : out std_logic;
      cd_i          : in  std_logic_vector(0 to  7);
      cd_o          : out std_logic_vector(0 to  7);
      vram_we_o     : out std_logic;
      vram_a_o      : out std_logic_vector(0 to 13);
      vram_d_o      : out std_logic_vector(0 to  7);
      vram_d_i      : in  std_logic_vector(0 to  7);
      col_o         : out std_logic_vector(0 to  3);
      rgb_r_o       : out std_logic_vector(0 to  7);
      rgb_g_o       : out std_logic_vector(0 to  7);
      rgb_b_o       : out std_logic_vector(0 to  7);
      hsync_n_o     : out std_logic;
      vsync_n_o     : out std_logic;
      comp_sync_n_o : out std_logic
    );
  end component;

end vdp18_core_comp_pack;
