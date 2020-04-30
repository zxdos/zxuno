--
--	This file is a *derivative* work of the source cited below.
--	The original source can be downloaded from <http://www.fpgaarcade.com>
--

-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: cv_console.vhd,v 1.13 2006/02/28 22:29:55 arnim Exp $
--
-- Toplevel of the Colecovision console
--
-- References:
--
--   * Dan Boris' schematics of the Colecovision board
--     http://www.atarihq.com/danb/files/colecovision.pdf
--
--   * Schematics of the Colecovision controller, same source
--     http://www.atarihq.com/danb/files/ColecoController.pdf
--
--   * Technical information, same source
--     http://www.atarihq.com/danb/files/CV-Tech.txt
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.sdram_pkg.all;
use work.kbd_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;
use work.target_pkg.all;
use work.platform_pkg.all;
use work.project_pkg.all;
use work.cv_keys_pack.all;
use work.vdp18_col_pack.all;

entity PACE is
  port
  (
  	-- clocks and resets
    clk_i           : in std_logic_vector(0 to 3);
    reset_i         : in std_logic;

    -- misc I/O
    buttons_i       : in from_BUTTONS_t;
    switches_i      : in from_SWITCHES_t;
    leds_o          : out to_LEDS_t;

    -- controller inputs
    inputs_i        : in from_INPUTS_t;

    -- external ROM/RAM
    flash_i         : in from_FLASH_t;
    flash_o         : out to_flash_t;
    sram_i       		: in from_SRAM_t;
		sram_o					: out to_SRAM_t;
    sdram_i         : in from_SDRAM_t;
    sdram_o         : out to_SDRAM_t;
    
    -- video
    video_i         : in from_VIDEO_t;
    video_o         : out to_VIDEO_t;

    -- audio
    audio_i         : in from_AUDIO_t;
    audio_o         : out to_AUDIO_t;
    
    -- SPI (flash)
    spi_i           : in from_SPI_t;
    spi_o           : out to_SPI_t;

    -- serial
    ser_i           : in from_SERIAL_t;
    ser_o           : out to_SERIAL_t;
    
    -- custom i/o
    project_i       : in from_PROJECT_IO_t;
    project_o       : out to_PROJECT_IO_t;
    platform_i      : in from_PLATFORM_IO_t;
    platform_o      : out to_PLATFORM_IO_t;
    target_i        : in from_TARGET_IO_t;
    target_o        : out to_TARGET_IO_t
  );
end entity PACE;

architecture SYN of PACE is

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

	signal clk32			: std_logic;
	signal vid				: std_logic_vector(15 downto 0);
	signal video_out	: std_logic_vector(15 downto 0);
	signal pixclkena	: std_logic;
	signal vga_hsync	: std_logic;
	signal vga_vsync	: std_logic;
	signal cvbs				: unsigned(4 downto 0);

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

  --signal rgb_r_s,
  --       rgb_g_s,
  --       rgb_b_s             : std_logic_vector( 0 to 7);

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

	-- changes for PACE
	alias clk_20M							  : std_logic is clk_i(1);
  alias ext_clk_i             : std_logic is clk_i(0);
  signal clk_cnt_q            : unsigned(1 downto 0);
	signal clk_en_5m37_q			  : std_logic;
	alias clk_21m3_s					  : std_logic is clk_s;

  signal rgb_col_s            : std_logic_vector(3 downto 0);
  signal rgb_hsync_n_s,
         rgb_vsync_n_s        : std_logic;
  signal rgb_hsync_s,
         rgb_vsync_s          : std_logic;

  signal vga_col_s            : std_logic_vector(3 downto 0);
  signal vga_hsync_s,
         vga_vsync_s          : std_logic;

	alias vid_hsync						  : std_logic is video_o.hsync;
	alias vid_vsync						  : std_logic is video_o.vsync;
	
	signal vid_r,
				 vid_g,
				 vid_b							  : std_logic_vector(7 downto 0);

  signal ps2_kclk             : std_logic;
  signal ps2_kdat             : std_logic;
  
	signal ps2_keys_s				    : std_logic_vector(15 downto 0);
	signal ps2_joy_s				    : std_logic_vector(15 downto 0);
	
begin

	-- map inputs
  ps2_kclk <= inputs_i.ps2_kclk;
  ps2_kdat <= inputs_i.ps2_kdat;
  
  flash_o <= NULL_TO_FLASH;
  spi_o <= NULL_TO_SPI;
  ser_o <= NULL_TO_SERIAL;
	leds_o <= (others => '0');

  -- assign PACE outputs
  video_o.rgb.r <= vid_r & "00";
  video_o.rgb.g <= vid_g & "00";
  video_o.rgb.b <= vid_b & "00";

	-- produce a 5MHz clock for the audio DAC
	process (clk_20M)
		variable count : std_logic_vector(1 downto 0);
	begin
		if rising_edge(clk_20M) then
			count := count + 1;
			audio_o.clk <= count(1);
		end if;
	end process;

  gnd_8_s   <= (others => '0');

	reset_n_s <= not reset_i;

  -----------------------------------------------------------------------------
  -- The PLL	24MHz -> 21.333MHz
  -----------------------------------------------------------------------------
  pll_inclk_s(1) <= '0';
  pll_inclk_s(0) <= ext_clk_i;
  pll_b : entity work.cv_pll
    port map 
    (
      inclk0  => pll_inclk_s(0),
      c0      => pll_clk_s(0)
    );
  clk_s <= pll_clk_s(0);

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
  --

  -----------------------------------------------------------------------------
  -- The Colecovision console
  -----------------------------------------------------------------------------
  cv_console_b : entity work.cv_console
    generic map (
      is_pal_g        => 0,
      compat_rgb_g    => 0
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
      col_o           => rgb_col_s,
      rgb_r_o         => open,
      rgb_g_o         => open,
      rgb_b_o         => open,
      hsync_n_o       => rgb_hsync_n_s,
      vsync_n_o       => rgb_vsync_n_s,
      comp_sync_n_o   => open,
      audio_o         => signed_audio_s
    );

  rgb_hsync_s <= not rgb_hsync_n_s;
  rgb_vsync_s <= not rgb_vsync_n_s;

  -----------------------------------------------------------------------------
  -- BIOS ROM
  -----------------------------------------------------------------------------
  bios_b : entity work.sprom
    generic map
		(
			numwords_a		=> 8192,
      widthad_a     => 13,
			init_file			=> "../../../../src/platform/colecovision/roms/bios.hex"
    )
    port map 
		(
      clock    			=> clk_s,
      address 			=> bios_rom_a_s,
      q       			=> bios_rom_d_s
    );

  -----------------------------------------------------------------------------
  -- CPU RAM
  -----------------------------------------------------------------------------
  cpu_ram_we_s <= clk_en_10m7_q and
                  not (cpu_ram_we_n_s or cpu_ram_ce_n_s);
  cpu_ram_b : entity work.spram
    generic map 
		(
			numwords_a		=> 1024,
      widthad_a     => 10
    )
    port map
		(
      clock    			=> clk_s,
      address 			=> cpu_ram_a_s,
      wren    			=> cpu_ram_we_s,
      data    			=> cpu_ram_d_from_cv_s,
      q       			=> cpu_ram_d_to_cv_s
    );

  -----------------------------------------------------------------------------
  -- VRAM
  -----------------------------------------------------------------------------
  --vram_b : altsyncram
  --  generic map (
  --    operation_mode => "SINGLE_PORT",
  --    width_a        => 8,
  --    widthad_a      => 14,
  --    outdata_reg_a  => "UNREGISTERED",
  --    init_file      => "UNUSED"
  --  )
  --  port map (
  --    wren_a    => vram_we_s,
  --    address_a => vram_a_s,
  --    clock0    => clk_s,
  --    data_a    => vram_d_from_cv_s,
  --    q_a       => vram_d_to_cv_s
  --  );

	-- use external SRAM for video ram
	sram_o.we <= vram_we_s;
	sram_o.a <= std_logic_vector(resize(unsigned(vram_a_s), sram_o.a'length));
	sram_o.d <= std_logic_vector(resize(unsigned(vram_d_from_cv_s), sram_o.d'length)) when vram_we_s = '1' else (others => 'Z');
	vram_d_to_cv_s <= sram_i.d(vram_d_to_cv_s'range);
	sram_o.be <= std_logic_vector(to_unsigned(1, sram_o.be'length));
	sram_o.oe <= not vram_we_s;
	sram_o.cs <= '1';

  -----------------------------------------------------------------------------
  -- Process cart_if
  --
  -- Purpose:
  --   Manages the cartridge interface.
  --
  --cart_if: process (cart_a_s,
  --                  cart_en_80_n_s, cart_en_a0_n_s,
  --                  cart_en_c0_n_s, cart_en_e0_n_s,
  --                  rama_d_b)
  --begin
    --rama_we_n_o            <= '1';
    --rama_oe_n_o            <= '0';
    --rama_lb_n_o            <= '0';
    --rama_ub_n_o            <= '0';
    --rama_a_o(17 downto 14) <= (others => '0');
    --rama_a_o(13 downto  0) <= cart_a_s(14 downto 1);

    --if (cart_en_80_n_s and cart_en_a0_n_s and
    --    cart_en_c0_n_s and cart_en_e0_n_s) = '0' then
    --  rama_cs_n_o <= '0';
    --else
    --  rama_cs_n_o <= '1';
    --end if;

    --if cart_a_s(0) = '0' then
    --  cart_d_s <= rama_d_b( 7 downto 0);
    --else
    --  cart_d_s <= rama_d_b(15 downto 8);
    --end if;
  --
  --end process cart_if;

  -----------------------------------------------------------------------------
  -- CART ROM (16K)
  -----------------------------------------------------------------------------
  cart_rom : entity work.sprom
    generic map
		(
			numwords_a		=> 16384,
      widthad_a     => 14,
			init_file			=> "../../../../src/platform/colecovision/roms/carts/" & CV_CART_NAME
    )
    port map 
		(
      clock    			=> clk_s,
      address 			=> cart_a_s(13 downto 0),
      q       			=> cart_d_s
    );
  --

	-- PS/2 keyboard interface
	ps2if_inst : entity work.colecoKeyboard
	port map
	(
    clk       	=> clk_20M,
    reset     	=> reset_i,

		-- inputs from PS/2 port
    ps2_clk  		=> ps2_kclk,
    ps2_data 		=> ps2_kdat,

    -- user outputs
		keys				=> ps2_keys_s,
		joy					=> ps2_joy_s
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

    for idx in 1 to 1 loop -- was 2
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
          elsif ps2_keys_s(9) = '1' then
            -- KEY *
            key_v := cv_key_asterisk_c;
          elsif ps2_keys_s(6) = '1' then
            -- KEY #
            key_v := cv_key_number_c;
          end if;
        --end if;

        ctrl_p1_s(idx) <= cv_keys_c(key_v)(1);
        ctrl_p2_s(idx) <= cv_keys_c(key_v)(2);
        ctrl_p3_s(idx) <= cv_keys_c(key_v)(3);
        ctrl_p4_s(idx) <= cv_keys_c(key_v)(4);

        --if but_tl_s(idx-1) = '1' then
          ctrl_p6_s(idx) <= not ps2_keys_s(0);
        --else
        --  ctrl_p6_s(idx) <= '1';
        --end if;

      elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
        -- joystick and left button enabled -----------------------------------
        ctrl_p1_s(idx) <= not ps2_joy_s(0);	-- up
        ctrl_p2_s(idx) <= not ps2_joy_s(1); -- down
        ctrl_p3_s(idx) <= not ps2_joy_s(2); -- left
        ctrl_p4_s(idx) <= not ps2_joy_s(3); -- right
        ctrl_p6_s(idx) <= not ps2_joy_s(4); -- button

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
  -- VGA Scan Doubler
  -----------------------------------------------------------------------------
  dblscan_b : entity work.dblscan
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
        --
        vid_r     <= std_logic_vector(to_unsigned(vga_r_v, 8));
        vid_g     <= std_logic_vector(to_unsigned(vga_g_v, 8));
        vid_b     <= std_logic_vector(to_unsigned(vga_b_v, 8));
      end if;

    end if;
  end process vga_col;
  --
  vid_hsync         <= not vga_hsync_s;
  vid_vsync         <= not vga_vsync_s;
  --vid_blank         <= '1';
  --vid_clk           <= clk_en_10m7_q;
  --
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Convert signed audio data of the console (range 127 to -128) to
  -- simple unsigned value.
  -----------------------------------------------------------------------------
  dac_audio_s <= std_logic_vector(unsigned(signed_audio_s + 128));
  audio_o.ldata(15 downto 8) <= dac_audio_s;
  audio_o.ldata(7 downto 0) <= (others => '0');
  audio_o.rdata(15 downto 8) <= dac_audio_s;
  audio_o.rdata(7 downto 0) <= (others => '0');
	
end SYN;

