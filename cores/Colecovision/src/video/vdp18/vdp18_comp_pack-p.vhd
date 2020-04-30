-------------------------------------------------------------------------------
--
-- $Id: vdp18_comp_pack-p.vhd,v 1.23 2006/02/28 22:30:41 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.vdp18_pack.opmode_t;
use work.vdp18_pack.hv_t;
use work.vdp18_pack.access_t;

package vdp18_comp_pack is

  component vdp18_clk_gen
    port (
      clock_i       : in  std_logic;
      clk_en_10m7_i : in  std_logic;
      reset_i       : in  boolean;
      clk_en_5m37_o : out boolean;
      clk_en_3m58_o : out boolean;
      clk_en_2m68_o : out boolean
    );
  end component;

	component vdp18_hor_vert
	port (
		clock_i       : in  std_logic;
		clk_en_5m37_i : in  boolean;
		reset_i       : in  boolean;
		opmode_i      : in  opmode_t;
		ntsc_pal_i		: in  std_logic;
		num_pix_o     : out hv_t;
		num_line_o    : out hv_t;
		vert_inc_o    : out boolean;
		hsync_n_o     : out std_logic;
		vsync_n_o     : out std_logic;
		blank_o       : out boolean;
		cnt_hor_o		: out std_logic_vector(8 downto 0);
		cnt_ver_o		: out std_logic_vector(7 downto 0)
	);
	end component;

  component vdp18_ctrl
    port (
      clock_i       : in  std_logic;
      clk_en_5m37_i : in  boolean;
      reset_i       : in  boolean;
      opmode_i      : in  opmode_t;
		vram_read_i		: in  boolean;
		vram_write_i	: in  boolean;
		vram_ce_o		: out std_logic;
		vram_oe_o		: out std_logic;
      num_pix_i     : in  hv_t;
      num_line_i    : in  hv_t;
      vert_inc_i    : in  boolean;
      reg_blank_i   : in  boolean;
      reg_size1_i   : in  boolean;
      stop_sprite_i : in  boolean;
      clk_en_acc_o  : out boolean;
      access_type_o : out access_t;
      vert_active_o : out boolean;
      hor_active_o  : out boolean;
      irq_o         : out boolean
    );
  end component;

  component vdp18_cpuio
    port (
      clock_i       : in  std_logic;
      clk_en_10m7_i : in  boolean;
      clk_en_acc_i  : in  boolean;
      reset_i       : in  boolean;
      rd_i          : in  boolean;
      wr_i          : in  boolean;
      mode_i        : in  std_logic;
      cd_i          : in  std_logic_vector(0 to  7);
      cd_o          : out std_logic_vector(0 to  7);
      cd_oe_o       : out std_logic;
      access_type_i : in  access_t;
      opmode_o      : out opmode_t;
		vram_read_o		: out boolean;
		vram_write_o	: out boolean;
      vram_we_o     : out std_logic;
      vram_a_o      : out std_logic_vector(0 to 13);
      vram_d_o      : out std_logic_vector(0 to  7);
      vram_d_i      : in  std_logic_vector(0 to  7);
      spr_coll_i    : in  boolean;
      spr_5th_i     : in  boolean;
      spr_5th_num_i : in  std_logic_vector(0 to  4);
      reg_ev_o      : out boolean;
      reg_16k_o     : out boolean;
      reg_blank_o   : out boolean;
      reg_size1_o   : out boolean;
      reg_mag1_o    : out boolean;
      reg_ntb_o     : out std_logic_vector(0 to  3);
      reg_ctb_o     : out std_logic_vector(0 to  7);
      reg_pgb_o     : out std_logic_vector(0 to  2);
      reg_satb_o    : out std_logic_vector(0 to  6);
      reg_spgb_o    : out std_logic_vector(0 to  2);
      reg_col1_o    : out std_logic_vector(0 to  3);
      reg_col0_o    : out std_logic_vector(0 to  3);
      irq_i         : in  boolean;
      int_n_o       : out std_logic
    );
  end component;

  component vdp18_addr_mux
    port (
      access_type_i : in  access_t;
      opmode_i      : in  opmode_t;
      num_line_i    : in  hv_t;
      reg_ntb_i     : in  std_logic_vector(0 to  3);
      reg_ctb_i     : in  std_logic_vector(0 to  7);
      reg_pgb_i     : in  std_logic_vector(0 to  2);
      reg_satb_i    : in  std_logic_vector(0 to  6);
      reg_spgb_i    : in  std_logic_vector(0 to  2);
      reg_size1_i   : in  boolean;
      cpu_vram_a_i  : in  std_logic_vector(0 to 13);
      pat_table_i   : in  std_logic_vector(0 to  9);
      pat_name_i    : in  std_logic_vector(0 to  7);
      spr_num_i     : in  std_logic_vector(0 to  4);
      spr_line_i    : in  std_logic_vector(0 to  3);
      spr_name_i    : in  std_logic_vector(0 to  7);
      vram_a_o      : out std_logic_vector(0 to 13)
    );
  end component;

  component vdp18_pattern
    port (
      clock_i       : in  std_logic;
      clk_en_5m37_i : in  boolean;
      clk_en_acc_i  : in  boolean;
      reset_i       : in  boolean;
      opmode_i      : in  opmode_t;
      access_type_i : in  access_t;
      num_line_i    : in  hv_t;
      vram_d_i      : in  std_logic_vector(0 to 7);
      vert_inc_i    : in  boolean;
      vsync_n_i     : in  std_logic;
      reg_col1_i    : in  std_logic_vector(0 to 3);
      reg_col0_i    : in  std_logic_vector(0 to 3);
      pat_table_o   : out std_logic_vector(0 to 9);
      pat_name_o    : out std_logic_vector(0 to 7);
      pat_col_o     : out std_logic_vector(0 to 3)
    );
  end component;

  component vdp18_sprite
    port (
      clock_i       : in  std_logic;
      clk_en_5m37_i : in  boolean;
      clk_en_acc_i  : in  boolean;
      reset_i       : in  boolean;
      access_type_i : in  access_t;
      num_pix_i     : in  hv_t;
      num_line_i    : in  hv_t;
      vram_d_i      : in  std_logic_vector(0 to 7);
      vert_inc_i    : in  boolean;
      reg_size1_i   : in  boolean;
      reg_mag1_i    : in  boolean;
      spr_5th_o     : out boolean;
      spr_5th_num_o : out std_logic_vector(0 to 4);
      stop_sprite_o : out boolean;
      spr_coll_o    : out boolean;
      spr_num_o     : out std_logic_vector(0 to 4);
      spr_line_o    : out std_logic_vector(0 to 3);
      spr_name_o    : out std_logic_vector(0 to 7);
      spr0_col_o    : out std_logic_vector(0 to 3);
      spr1_col_o    : out std_logic_vector(0 to 3);
      spr2_col_o    : out std_logic_vector(0 to 3);
      spr3_col_o    : out std_logic_vector(0 to 3)
    );
  end component;

  component vdp18_col_mux
    generic (
      compat_rgb_g  : integer := 0
    );
    port (
      clock_i       : in  std_logic;
      clk_en_5m37_i : in  boolean;
      reset_i       : in  boolean;
      vert_active_i : in  boolean;
      hor_active_i  : in  boolean;
      blank_i       : in  boolean;
      reg_col0_i    : in  std_logic_vector(0 to 3);
      pat_col_i     : in  std_logic_vector(0 to 3);
      spr0_col_i    : in  std_logic_vector(0 to 3);
      spr1_col_i    : in  std_logic_vector(0 to 3);
      spr2_col_i    : in  std_logic_vector(0 to 3);
      spr3_col_i    : in  std_logic_vector(0 to 3);
      col_o         : out std_logic_vector(0 to 3);
      rgb_r_o       : out std_logic_vector(0 to 7);
      rgb_g_o       : out std_logic_vector(0 to 7);
      rgb_b_o       : out std_logic_vector(0 to 7)
    );
  end component;

end vdp18_comp_pack;
