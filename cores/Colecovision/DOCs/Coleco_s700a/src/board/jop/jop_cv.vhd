-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: jop_cv.vhd,v 1.13 2006/02/28 22:30:21 arnim Exp $
--
-- Toplevel of the Cyclone port for JOP.design's cycore board.
--   http://jopdesign.com/
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

entity jop_cv is

  port (
    ext_clk_i     : in    std_logic;
    rgb_r_o       : out   std_logic_vector( 2 downto 0);
    rgb_g_o       : out   std_logic_vector( 2 downto 0);
    rgb_b_o       : out   std_logic_vector( 2 downto 0);
    comp_sync_n_o : out   std_logic;
    audio_l_o     : out   std_logic;
    audio_r_o     : out   std_logic;
    audio_o       : out   std_logic_vector( 7 downto 0);
    pad_clk_o     : out   std_logic;
    pad_latch_o   : out   std_logic;
    pad_data_i    : in    std_logic_vector( 1 downto 0);
    rxd_i         : in    std_logic;
    txd_o         : out   std_logic;
    cts_i         : in    std_logic;
    rts_o         : out   std_logic;
    rama_a_o      : out   std_logic_vector(17 downto 0);
    rama_d_b      : inout std_logic_vector(15 downto 0);
    rama_cs_n_o   : out   std_logic;
    rama_oe_n_o   : out   std_logic;
    rama_we_n_o   : out   std_logic;
    rama_lb_n_o   : out   std_logic;
    rama_ub_n_o   : out   std_logic;
    ramb_a_o      : out   std_logic_vector(17 downto 0);
    ramb_d_b      : inout std_logic_vector(15 downto 0);
    ramb_cs_n_o   : out   std_logic;
    ramb_oe_n_o   : out   std_logic;
    ramb_we_n_o   : out   std_logic;
    ramb_lb_n_o   : out   std_logic;
    ramb_ub_n_o   : out   std_logic;
    fl_a_o        : out   std_logic_vector(18 downto 0);
    fl_d_b        : inout std_logic_vector( 7 downto 0);
    fl_we_n_o     : out   std_logic;
    fl_oe_n_o     : out   std_logic;
    fl_cs_n_o     : out   std_logic;
    fl_cs2_n_o    : out   std_logic;
    fl_rdy_i      : in    std_logic
  );

end jop_cv;


library ieee;
use ieee.numeric_std.all;

use work.cv_console_comp_pack.cv_console;
use work.snespad_comp.snespad;
use work.board_misc_comp_pack.dac;
use work.cv_keys_pack.all;

architecture struct of jop_cv is

  component altpll
    generic (
      lpm_type               : STRING;
      inclk0_input_frequency : NATURAL;
      pll_type               : STRING;
      intended_device_family : STRING;
      operation_mode         : STRING;
      compensate_clock       : STRING;
      clk0_phase_shift       : STRING;
      clk0_multiply_by       : NATURAL;
      clk0_divide_by         : NATURAL;
      clk0_duty_cycle        : NATURAL;
      clk0_time_delay        : STRING
    );
    port (
      inclk : in  std_logic_vector(1 downto 0);
      clk   : out std_logic_vector(5 downto 0)
    );
  end component;

  component altsyncram
    generic (
      operation_mode : string;
      width_a        : natural;
      widthad_a      : natural;
      outdata_reg_a  : string;
      init_file      : string := "UNUSED"
    );
    port (
      wren_a         : in  std_logic;
      address_a      : in  std_logic_vector(widthad_a-1 downto 0);
      clock0         : in  std_logic;
      data_a         : in  std_logic_vector(width_a-1 downto 0);
      q_a            : out std_logic_vector(width_a-1 downto 0)
    );
  end component;

  signal pll_inclk_s         : std_logic_vector(1 downto 0);
  signal pll_clk_s           : std_logic_vector(5 downto 0);

  signal clk_s               : std_logic;
  signal clk_en_10m7_q       : std_logic;
  signal reset_n_s           : std_logic;
  signal por_n_s             : std_logic;

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

  signal cpu_ram_a_s         : std_logic_vector( 9 downto 0);
  signal cpu_ram_ce_n_s      : std_logic;
  signal cpu_ram_we_n_s      : std_logic;
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

  signal rgb_r_s,
         rgb_g_s,
         rgb_b_s             : std_logic_vector( 0 to 7);

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

  signal signed_audio_s      : signed(7 downto 0);
  signal dac_audio_s         : std_logic_vector( 7 downto 0);
  signal audio_s             : std_logic;

  signal gnd_8_s             : std_logic_vector( 7 downto 0);

begin

  gnd_8_s   <= (others => '0');

  reset_n_s <= but_tl_s(0) or but_tr_s(0);

  -----------------------------------------------------------------------------
  -- Process clk_en
  --
  -- Purpose:
  --   Clock enable for 10.7 MHz.
  --
  clk_en: process (clk_s, por_n_s)
  begin
    if por_n_s = '0' then
      clk_en_10m7_q <= '0';
    elsif clk_s'event and clk_s = '1' then
      clk_en_10m7_q <= not clk_en_10m7_q;
    end if;
  end process clk_en;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- The PLL
  -----------------------------------------------------------------------------
  pll_inclk_s(1) <= '0';
  pll_inclk_s(0) <= ext_clk_i;
  pll_b : altpll
    generic map (
      lpm_type               => "altpll",
      inclk0_input_frequency => 50000,  -- 20MHz = 50000ps
      pll_type               => "AUTO",
      intended_device_family => "Cyclone",
      operation_mode         => "NORMAL",
      compensate_clock       => "CLK0",
      clk0_duty_cycle        => 50,
      clk0_multiply_by       => 16,
      clk0_divide_by         => 15,
      clk0_time_delay        => "0",
      clk0_phase_shift       => "0"
    )
    port map (
      inclk => pll_inclk_s,
      clk   => pll_clk_s
    );
  clk_s <= pll_clk_s(0);


  -----------------------------------------------------------------------------
  -- The Colecovision console
  -----------------------------------------------------------------------------
  cv_console_b : cv_console
    generic map (
      is_pal_g        => 0,
      compat_rgb_g    => 1
    )
    port map (
      clk_i           => clk_s,
      clk_en_10m7_i   => clk_en_10m7_q,
      reset_n_i       => reset_n_s,
      por_n_o         => por_n_s,
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
      cpu_ram_a_o     => cpu_ram_a_s,
      cpu_ram_ce_n_o  => cpu_ram_ce_n_s,
      cpu_ram_we_n_o  => cpu_ram_we_n_s,
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
      col_o           => open,
      rgb_r_o         => rgb_r_s,
      rgb_g_o         => rgb_g_s,
      rgb_b_o         => rgb_b_s,
      hsync_n_o       => open,
      vsync_n_o       => open,
      comp_sync_n_o   => comp_sync_n_o,
      audio_o         => signed_audio_s
    );
  rgb_r_o <= rgb_r_s(0 to 2);
  rgb_g_o <= rgb_g_s(0 to 2);
  rgb_b_o <= rgb_b_s(0 to 2);


  -----------------------------------------------------------------------------
  -- BIOS ROM
  -----------------------------------------------------------------------------
  bios_b : altsyncram
    generic map (
      operation_mode => "SINGLE_PORT",
      width_a        => 8,
      widthad_a      => 13,
      outdata_reg_a  => "UNREGISTERED",
      init_file      => "coleco.hex"
    )
    port map (
      wren_a    => gnd_8_s(0),
      address_a => bios_rom_a_s,
      clock0    => clk_s,
      data_a    => gnd_8_s,
      q_a       => bios_rom_d_s
    );


  -----------------------------------------------------------------------------
  -- CPU RAM
  -----------------------------------------------------------------------------
  cpu_ram_we_s <= clk_en_10m7_q and
                  not (cpu_ram_we_n_s or cpu_ram_ce_n_s);
  cpu_ram_b : altsyncram
    generic map (
      operation_mode => "SINGLE_PORT",
      width_a        => 8,
      widthad_a      => 10,
      outdata_reg_a  => "UNREGISTERED",
      init_file      => "UNUSED"
    )
    port map (
      wren_a    => cpu_ram_we_s,
      address_a => cpu_ram_a_s,
      clock0    => clk_s,
      data_a    => cpu_ram_d_from_cv_s,
      q_a       => cpu_ram_d_to_cv_s
    );


  -----------------------------------------------------------------------------
  -- VRAM
  -----------------------------------------------------------------------------
  vram_b : altsyncram
    generic map (
      operation_mode => "SINGLE_PORT",
      width_a        => 8,
      widthad_a      => 14,
      outdata_reg_a  => "UNREGISTERED",
      init_file      => "UNUSED"
    )
    port map (
      wren_a    => vram_we_s,
      address_a => vram_a_s,
      clock0    => clk_s,
      data_a    => vram_d_from_cv_s,
      q_a       => vram_d_to_cv_s
    );


  -----------------------------------------------------------------------------
  -- Process cart_if
  --
  -- Purpose:
  --   Manages the cartridge interface.
  --
  cart_if: process (cart_a_s,
                    cart_en_80_n_s, cart_en_a0_n_s,
                    cart_en_c0_n_s, cart_en_e0_n_s,
                    rama_d_b)
  begin
    rama_we_n_o            <= '1';
    rama_oe_n_o            <= '0';
    rama_lb_n_o            <= '0';
    rama_ub_n_o            <= '0';
    rama_a_o(17 downto 14) <= (others => '0');
    rama_a_o(13 downto  0) <= cart_a_s(14 downto 1);

    if (cart_en_80_n_s and cart_en_a0_n_s and
        cart_en_c0_n_s and cart_en_e0_n_s) = '0' then
      rama_cs_n_o <= '0';
    else
      rama_cs_n_o <= '1';
    end if;

    if cart_a_s(0) = '0' then
      cart_d_s <= rama_d_b( 7 downto 0);
    else
      cart_d_s <= rama_d_b(15 downto 8);
    end if;

  end process cart_if;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- SNES Gamepads
  -----------------------------------------------------------------------------
  snespads_b : snespad
    generic map (
      num_pads_g       => 2,
      reset_level_g    => 0,
      button_level_g   => 0,
      clocks_per_6us_g => 128
    )
    port map (
      clk_i            => clk_s,
      reset_i          => por_n_s,
      pad_clk_o        => pad_clk_o,
      pad_latch_o      => pad_latch_o,
      pad_data_i       => pad_data_i,
      but_a_o          => but_a_s,
      but_b_o          => but_b_s,
      but_x_o          => but_x_s,
      but_y_o          => but_y_s,
      but_start_o      => but_start_s,
      but_sel_o        => but_sel_s,
      but_tl_o         => but_tl_s,
      but_tr_o         => but_tr_s,
      but_up_o         => but_up_s,
      but_down_o       => but_down_s,
      but_left_o       => but_left_s,
      but_right_o      => but_right_s
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

    for idx in 1 to 2 loop
      if    ctrl_p5_s(idx) = '0' and ctrl_p8_s(idx) = '1' then
        -- keys and right button enabled --------------------------------------
        -- keys not fully implemented

        key_v := cv_key_none_c;

        if but_tl_s(idx-1) = '0' then
          if    but_a_s(idx-1) = '0' then
            -- KEY 1
            key_v := cv_key_1_c;
          elsif but_b_s(idx-1) = '0' then
            -- KEY 2
            key_v := cv_key_2_c;
          elsif but_x_s(idx-1) = '0' then
            -- KEY 3
            key_v := cv_key_3_c;
          elsif but_y_s(idx-1) = '0' then
            -- KEY 4
            key_v := cv_key_4_c;
          elsif but_sel_s(idx-1) = '0' then
            -- KEY *
            key_v := cv_key_asterisk_c;
          elsif but_start_s(idx-1) = '0' then
            -- KEY #
            key_v := cv_key_number_c;
          end if;
        end if;

        ctrl_p1_s(idx) <= cv_keys_c(key_v)(1);
        ctrl_p2_s(idx) <= cv_keys_c(key_v)(2);
        ctrl_p3_s(idx) <= cv_keys_c(key_v)(3);
        ctrl_p4_s(idx) <= cv_keys_c(key_v)(4);

        if but_tl_s(idx-1) = '1' then
          ctrl_p6_s(idx) <= but_b_s(idx-1);
        else
          ctrl_p6_s(idx) <= '1';
        end if;

      elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
        -- joystick and left button enabled -----------------------------------
        ctrl_p1_s(idx) <= but_up_s(idx-1);
        ctrl_p2_s(idx) <= but_down_s(idx-1);
        ctrl_p3_s(idx) <= but_left_s(idx-1);
        ctrl_p4_s(idx) <= but_right_s(idx-1);
        ctrl_p6_s(idx) <= but_a_s(idx-1);

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
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Convert signed audio data of the console (range 127 to -128) to
  -- simple unsigned value.
  -----------------------------------------------------------------------------
  dac_audio_s <= std_logic_vector(unsigned(signed_audio_s + 128));

  dac_b : dac
    generic map (
      msbi_g => 7
    )
    port map (
      clk_i   => clk_s,
      res_n_i => por_n_s,
      dac_i   => dac_audio_s,
      dac_o   => audio_s
    );

  audio_r_o <= audio_s;
  audio_l_o <= audio_s;
  audio_o   <= dac_audio_s;


  -----------------------------------------------------------------------------
  -- JOP pin defaults
  -----------------------------------------------------------------------------
  -- UART
  txd_o       <= '1';
  rts_o       <= '1';
  -- RAMB
  ramb_a_o    <= (others => '0');
  ramb_cs_n_o <= '1';
  ramb_oe_n_o <= '1';
  ramb_we_n_o <= '1';
  ramb_lb_n_o <= '1';
  ramb_ub_n_o <= '1';
  -- Flash
  fl_a_o      <= (others => '0');
  fl_we_n_o   <= '1';
  fl_oe_n_o   <= '1';
  fl_cs_n_o   <= '1';
  fl_cs2_n_o  <= '1';

end struct;
