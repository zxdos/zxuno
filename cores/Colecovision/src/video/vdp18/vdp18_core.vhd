-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
--
-- $Id: vdp18_core.vhd,v 1.28 2006/06/18 10:47:01 arnim Exp $
--
-- Core Toplevel
--
-- Notes:
--   This core implements a simple VRAM interface which is suitable for a
--   synchronous SRAM component. There is currently no support of the
--   original DRAM interface.
--
--   Please be aware that the colors might me slightly different from the
--   original TMS9918. It is assumed that the simplified conversion to RGB
--   encoding is equivalent to the compatability mode of the V9938.
--   Implementing a 100% correct color encoding for RGB would require
--   significantly more logic and 8-bit wide RGB DACs.
--
-- References:
--
--   * TI Data book TMS9918.pdf
--     http://www.bitsavers.org/pdf/ti/_dataBooks/TMS9918.pdf
--
--   * Sean Young's tech article:
--     http://bifi.msxnet.org/msxnet/tech/tms9918a.txt
--
--   * Paul Urbanus' discussion of the timing details
--     http://bifi.msxnet.org/msxnet/tech/tmsposting.txt
--
--   * Richard F. Drushel's article series
--     "This Week With My Coleco ADAM"
--     http://junior.apk.net/~drushel/pub/coleco/twwmca/index.html
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity vdp18_core is
  generic (
    compat_rgb_g  : integer := 0
  );
  port (
    -- Global Interface -------------------------------------------------------
    clock_i       : in  std_logic;
    clk_en_10m7_i : in  std_logic;
	 clk_en_5m37_i	: in  std_logic;
    reset_n_i     : in  std_logic;
    -- CPU Interface ----------------------------------------------------------
    csr_n_i       : in  std_logic;
    csw_n_i       : in  std_logic;
    mode_i        : in  std_logic;
    int_n_o       : out std_logic;
    cd_i          : in  std_logic_vector(0 to  7);
    cd_o          : out std_logic_vector(0 to  7);
    -- VRAM Interface ---------------------------------------------------------
	 vram_ce_o		: out std_logic;
	 vram_oe_o		: out std_logic;
    vram_we_o     : out std_logic;
    vram_a_o      : out std_logic_vector(0 to 13);
    vram_d_o      : out std_logic_vector(0 to  7);
    vram_d_i      : in  std_logic_vector(0 to  7);
    -- Video Interface --------------------------------------------------------
    col_o         : out std_logic_vector(0 to 3);
	 cnt_hor_o		: out std_logic_vector(8 downto 0);
	 cnt_ver_o		: out std_logic_vector(7 downto 0);
    rgb_r_o       : out std_logic_vector(0 to 7);
    rgb_g_o       : out std_logic_vector(0 to 7);
    rgb_b_o       : out std_logic_vector(0 to 7);
    hsync_n_o     : out std_logic;
    vsync_n_o     : out std_logic;
    comp_sync_n_o : out std_logic
  );

end vdp18_core;


use work.vdp18_comp_pack.all;
use work.vdp18_pack.opmode_t;
use work.vdp18_pack.hv_t;
use work.vdp18_pack.access_t;
use work.vdp18_pack.to_boolean_f;

architecture struct of vdp18_core is

  signal reset_s          : boolean;

  signal clk_en_10m7_s,
         clk_en_5m37_s,
         clk_en_acc_s     : boolean;

  signal opmode_s         : opmode_t;

  signal access_type_s    : access_t;

  signal num_pix_s,
         num_line_s       : hv_t;
  signal hsync_n_s,
         vsync_n_s        : std_logic;
  signal blank_s          : boolean;

  signal vert_inc_s       : boolean;

  signal reg_blank_s,
         reg_size1_s,
         reg_mag1_s       : boolean;

  signal spr_5th_s        : boolean;
  signal spr_5th_num_s    : std_logic_vector(0 to 4);

  signal stop_sprite_s    : boolean;
  signal vert_active_s,
         hor_active_s     : boolean;

  signal rd_s,
         wr_s             : boolean;

  signal reg_ntb_s        : std_logic_vector(0 to  3);
  signal reg_ctb_s        : std_logic_vector(0 to  7);
  signal reg_pgb_s        : std_logic_vector(0 to  2);
  signal reg_satb_s       : std_logic_vector(0 to  6);
  signal reg_spgb_s       : std_logic_vector(0 to  2);
  signal reg_col1_s,
         reg_col0_s       : std_logic_vector(0 to  3);
  signal cpu_vram_a_s     : std_logic_vector(0 to 13);

  signal pat_table_s      : std_logic_vector(0 to  9);
  signal pat_name_s       : std_logic_vector(0 to  7);
  signal pat_col_s        : std_logic_vector(0 to  3);

  signal spr_num_s        : std_logic_vector(0 to  4);
  signal spr_line_s       : std_logic_vector(0 to  3);
  signal spr_name_s       : std_logic_vector(0 to  7);
  signal spr0_col_s,
         spr1_col_s,
         spr2_col_s,
         spr3_col_s       : std_logic_vector(0 to  3);
  signal spr_coll_s       : boolean;

  signal irq_s            : boolean;

--  signal false_s          : boolean;
 
	signal vram_read_s		: boolean;
	signal vram_write_s		: boolean;

begin

  -- temporary defaults
 -- false_s       <= false;

  clk_en_10m7_s <= to_boolean_f(clk_en_10m7_i);
  clk_en_5m37_s <= to_boolean_f(clk_en_5m37_i);
  rd_s          <= not to_boolean_f(csr_n_i);
  wr_s          <= not to_boolean_f(csw_n_i);

  reset_s <= reset_n_i = '0';

  -----------------------------------------------------------------------------
  -- Horizontal and Vertical Timing Generator
  -----------------------------------------------------------------------------
  hor_vert_b : vdp18_hor_vert
    port map (
      clock_i       => clock_i,
      clk_en_5m37_i => clk_en_5m37_s,
      reset_i       => reset_s,
      opmode_i      => opmode_s,
		ntsc_pal_i		=> '0',			-- NTSC
      num_pix_o     => num_pix_s,
      num_line_o    => num_line_s,
      vert_inc_o    => vert_inc_s,
      hsync_n_o     => hsync_n_s,
      vsync_n_o     => vsync_n_s,
      blank_o       => blank_s,
		cnt_hor_o		=> cnt_hor_o,
		cnt_ver_o		=> cnt_ver_o
    );

  hsync_n_o     <= hsync_n_s;
  vsync_n_o     <= vsync_n_s;
  comp_sync_n_o <= not (hsync_n_s xor vsync_n_s);


  -----------------------------------------------------------------------------
  -- Control Module
  -----------------------------------------------------------------------------
  ctrl_b : vdp18_ctrl
    port map (
      clock_i         => clock_i,
      clk_en_5m37_i => clk_en_5m37_s,
      reset_i       => reset_s,
      opmode_i      => opmode_s,
      vram_read_i   => vram_read_s,
      vram_write_i  => vram_write_s,
		vram_ce_o		=> vram_ce_o,
		vram_oe_o		=> vram_oe_o,
      num_pix_i     => num_pix_s,
      num_line_i    => num_line_s,
      vert_inc_i    => vert_inc_s,
      reg_blank_i   => reg_blank_s,
      reg_size1_i   => reg_size1_s,
      stop_sprite_i => stop_sprite_s,
      clk_en_acc_o  => clk_en_acc_s,
      access_type_o => access_type_s,
      vert_active_o => vert_active_s,
      hor_active_o  => hor_active_s,
      irq_o         => irq_s
    );


  -----------------------------------------------------------------------------
  -- CPU I/O Module
  -----------------------------------------------------------------------------
  cpu_io_b : vdp18_cpuio
    port map (
      clock_i         => clock_i,
      clk_en_10m7_i => clk_en_10m7_s,
      clk_en_acc_i  => clk_en_acc_s,
      reset_i       => reset_s,
      rd_i          => rd_s,
      wr_i          => wr_s,
      mode_i        => mode_i,
      cd_i          => cd_i,
      cd_o          => cd_o,
      cd_oe_o       => open,
      access_type_i => access_type_s,
      opmode_o      => opmode_s,
		vram_read_o   => vram_read_s,
		vram_write_o  => vram_write_s,
      vram_we_o     => vram_we_o,
      vram_a_o      => cpu_vram_a_s,
      vram_d_o      => vram_d_o,
      vram_d_i      => vram_d_i,
      spr_coll_i    => spr_coll_s,
      spr_5th_i     => spr_5th_s,
      spr_5th_num_i => spr_5th_num_s,
      reg_ev_o      => open,
      reg_16k_o     => open,
      reg_blank_o   => reg_blank_s,
      reg_size1_o   => reg_size1_s,
      reg_mag1_o    => reg_mag1_s,
      reg_ntb_o     => reg_ntb_s,
      reg_ctb_o     => reg_ctb_s,
      reg_pgb_o     => reg_pgb_s,
      reg_satb_o    => reg_satb_s,
      reg_spgb_o    => reg_spgb_s,
      reg_col1_o    => reg_col1_s,
      reg_col0_o    => reg_col0_s,
      irq_i         => irq_s,
      int_n_o       => int_n_o
    );


  -----------------------------------------------------------------------------
  -- VRAM Address Multiplexer
  -----------------------------------------------------------------------------
  addr_mux_b : vdp18_addr_mux
    port map (
      access_type_i => access_type_s,
      opmode_i      => opmode_s,
      num_line_i    => num_line_s,
      reg_ntb_i     => reg_ntb_s,
      reg_ctb_i     => reg_ctb_s,
      reg_pgb_i     => reg_pgb_s,
      reg_satb_i    => reg_satb_s,
      reg_spgb_i    => reg_spgb_s,
      reg_size1_i   => reg_size1_s,
      cpu_vram_a_i  => cpu_vram_a_s,
      pat_table_i   => pat_table_s,
      pat_name_i    => pat_name_s,
      spr_num_i     => spr_num_s,
      spr_line_i    => spr_line_s,
      spr_name_i    => spr_name_s,
      vram_a_o      => vram_a_o
    );


  -----------------------------------------------------------------------------
  -- Pattern Generator
  -----------------------------------------------------------------------------
  pattern_b : vdp18_pattern
    port map (
      clock_i         => clock_i,
      clk_en_5m37_i => clk_en_5m37_s,
      clk_en_acc_i  => clk_en_acc_s,
      reset_i       => reset_s,
      opmode_i      => opmode_s,
      access_type_i => access_type_s,
      num_line_i    => num_line_s,
      vram_d_i      => vram_d_i,
      vert_inc_i    => vert_inc_s,
      vsync_n_i     => vsync_n_s,
      reg_col1_i    => reg_col1_s,
      reg_col0_i    => reg_col0_s,
      pat_table_o   => pat_table_s,
      pat_name_o    => pat_name_s,
      pat_col_o     => pat_col_s
    );


  -----------------------------------------------------------------------------
  -- Sprite Generator
  -----------------------------------------------------------------------------
  sprite_b : vdp18_sprite
    port map (
      clock_i         => clock_i,
      clk_en_5m37_i => clk_en_5m37_s,
      clk_en_acc_i  => clk_en_acc_s,
      reset_i       => reset_s,
      access_type_i => access_type_s,
      num_pix_i     => num_pix_s,
      num_line_i    => num_line_s,
      vram_d_i      => vram_d_i,
      vert_inc_i    => vert_inc_s,
      reg_size1_i   => reg_size1_s,
      reg_mag1_i    => reg_mag1_s,
      spr_5th_o     => spr_5th_s,
      spr_5th_num_o => spr_5th_num_s,
      stop_sprite_o => stop_sprite_s,
      spr_coll_o    => spr_coll_s,
      spr_num_o     => spr_num_s,
      spr_line_o    => spr_line_s,
      spr_name_o    => spr_name_s,
      spr0_col_o    => spr0_col_s,
      spr1_col_o    => spr1_col_s,
      spr2_col_o    => spr2_col_s,
      spr3_col_o    => spr3_col_s
    );


  -----------------------------------------------------------------------------
  -- Color Multiplexer
  -----------------------------------------------------------------------------
  col_mux_b : vdp18_col_mux
    generic map (
      compat_rgb_g  => compat_rgb_g
    )
    port map (
      clock_i         => clock_i,
      clk_en_5m37_i => clk_en_5m37_s,
      reset_i       => reset_s,
      vert_active_i => vert_active_s,
      hor_active_i  => hor_active_s,
      blank_i       => blank_s,
      reg_col0_i    => reg_col0_s,
      pat_col_i     => pat_col_s,
      spr0_col_i    => spr0_col_s,
      spr1_col_i    => spr1_col_s,
      spr2_col_i    => spr2_col_s,
      spr3_col_i    => spr3_col_s,
      col_o         => col_o,
      rgb_r_o       => rgb_r_o,
      rgb_g_o       => rgb_g_o,
      rgb_b_o       => rgb_b_o
    );

end struct;
