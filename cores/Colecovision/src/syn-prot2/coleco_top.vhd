-------------------------------------------------------------------------------
--
-- Copyright (c) 2016, Fabio Belavenuto (belavenuto@gmail.com)
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
use ieee.numeric_std.all;

-- Prototype 2 - with SRAM and SNES controller - WORKING!
-- Para a placa EP2C5 chinesa

entity coleco_top is
	port (
		-- Clock
		clock_50_i			: in    std_logic;

		-- Botões
		btn_reset_n_i		: in    std_logic;
		btn_dblscan_i		: in    std_logic;
		btn_scanlines_i	: in    std_logic;

		-- VGA
		vga_rgb_r_o			: out   std_logic_vector(3 downto 0)	:= "0000";
		vga_rgb_g_o			: out   std_logic_vector(3 downto 0)	:= "0000";
		vga_rgb_b_o			: out   std_logic_vector(3 downto 0)	:= "0000";
		vga_hsync_n_o		: out   std_logic								:= '1';
		vga_vsync_n_o		: out   std_logic								:= '1';

		-- Audio
		audio_dac_o			: out   std_logic;

		-- SRAM CY7C1019CV33-12VC
		sram_addr_o			: out   std_logic_vector(16 downto 0)	:= (others => '0');
		sram_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram_ce_n_o			: out   std_logic								:= '1';
		sram_oe_n_o			: out   std_logic								:= '1';
		sram_we_n_o			: out   std_logic								:= '1';

		-- SD Card
		spi_cs_n_o			: out   std_logic								:= '1';
		spi_sclk_o			: out   std_logic								:= '0';
		spi_miso_i			: in    std_logic;
		spi_mosi_o			: out   std_logic								:= '0';

		-- Joystick SNES
		pad_clk_o			: out   std_logic								:= '0';
		pad_latch_o			: out   std_logic								:= '0';
		pad_data_i			: in    std_logic_vector( 1 downto 0)

	);
end entity;

use work.vdp18_col_pack.all;
use work.cv_keys_pack.all;

architecture behavior of coleco_top is

	-- Resets
	signal pll_locked_s		: std_logic;
	signal reset_s				: std_logic;
	signal soft_reset_s		: std_logic;
	signal por_n_s				: std_logic;

	-- Clocks
	signal clock_master_s	: std_logic;
	signal clock_mem_s		: std_logic;
	signal clock_vdp_en_s	: std_logic;
	signal clock_5m_en_s		: std_logic;
	signal clock_3m_en_s		: std_logic;

	-- RAM memory
	signal ram_addr_s			: std_logic_vector(16 downto 0);		-- 128K
	signal d_from_ram_s		: std_logic_vector(7 downto 0);
	signal d_to_ram_s			: std_logic_vector(7 downto 0);
	signal ram_ce_s			: std_logic;
	signal ram_oe_s			: std_logic;
	signal ram_we_s			: std_logic;

	-- VRAM memory
	signal vram_addr_s		: std_logic_vector(13 downto 0);		-- 16K
	signal vram_do_s			: std_logic_vector(7 downto 0);
	signal vram_di_s			: std_logic_vector(7 downto 0);
	signal vram_ce_s			: std_logic;
	signal vram_oe_s			: std_logic;
	signal vram_we_s			: std_logic;

	-- SD
	signal spi_cs_n_s			: std_logic;
	signal spi_data_in_s		: std_logic_vector(7 downto 0);
	signal spi_data_out_s	: std_logic_vector(7 downto 0);

	-- Audio
	signal audio_signed_s	: signed(7 downto 0);
	signal audio_s				: std_logic_vector(7 downto 0);

	-- Video
	signal btn_dblscan_s		: std_logic;
	signal btn_scanlines_s	: std_logic;
	signal dblscan_en_s		: std_logic;
	signal scanlines_en_s	: std_logic;
	signal rgb_col_s			: std_logic_vector( 3 downto 0);		-- 15KHz
	signal rgb_hsync_n_s		: std_logic;								-- 15KHz
	signal rgb_vsync_n_s		: std_logic;								-- 15KHz
	signal vga_col_s			: std_logic_vector( 3 downto 0);		-- 31KHz
	signal oddline_s			: std_logic;
	signal vga_hsync_n_s		: std_logic;								-- 31KHz
	signal vga_vsync_n_s		: std_logic;								-- 31KHz

	-- Controle
	signal ctrl_p1_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p2_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p3_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p4_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p5_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p6_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p7_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p8_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p9_s			: std_logic_vector( 2 downto 1)	:= "00";

	-- SNES
	signal but_a_s				: std_logic_vector( 1 downto 0);
	signal but_b_s				: std_logic_vector( 1 downto 0);
	signal but_x_s				: std_logic_vector( 1 downto 0);
	signal but_y_s				: std_logic_vector( 1 downto 0);
	signal but_start_s		: std_logic_vector( 1 downto 0);
	signal but_sel_s			: std_logic_vector( 1 downto 0);
	signal but_tl_s			: std_logic_vector( 1 downto 0);
	signal but_tr_s			: std_logic_vector( 1 downto 0);
	signal but_up_s			: std_logic_vector( 1 downto 0);
	signal but_down_s			: std_logic_vector( 1 downto 0);
	signal but_left_s			: std_logic_vector( 1 downto 0);
	signal but_right_s		: std_logic_vector( 1 downto 0);
	signal autofire_cnt_q	: unsigned(19 downto 0);

begin

	-- PLL
	pll: entity work.pll1
	port map (
		inclk0	=> clock_50_i,
		c0			=> clock_master_s,		-- 21.428571
		c1			=> clock_mem_s,			-- 42.857143
		locked	=> pll_locked_s
	);

	-- Clocks
	clks: entity work.clocks
	port map (
		clock_i			=> clock_master_s,
		por_i				=> not por_n_s,
		clock_vdp_en_o	=> clock_vdp_en_s,
		clock_5m_en_o	=> clock_5m_en_s,
		clock_3m_en_o	=> clock_3m_en_s
	);

	-- The Colecovision
	vg: entity work.colecovision
	generic map (
		num_maq_g		=> 4,
		compat_rgb_g	=> 0
	)
	port map (
		clock_i				=> clock_master_s,
		clk_en_10m7_i		=> clock_vdp_en_s,
		clk_en_5m37_i		=> clock_5m_en_s,
		clk_en_3m58_i		=> clock_3m_en_s,
		reset_i				=> reset_s,
		por_n_i				=> por_n_s,
		-- Controller Interface
		ctrl_p1_i			=> ctrl_p1_s,
		ctrl_p2_i			=> ctrl_p2_s,
		ctrl_p3_i			=> ctrl_p3_s,
		ctrl_p4_i			=> ctrl_p4_s,
		ctrl_p5_o			=> ctrl_p5_s,
		ctrl_p6_i			=> ctrl_p6_s,
		ctrl_p7_i			=> ctrl_p7_s,
		ctrl_p8_o			=> ctrl_p8_s,
		ctrl_p9_i			=> ctrl_p9_s,
		-- CPU RAM Interface
		ram_addr_o			=> ram_addr_s,
		ram_ce_o				=> ram_ce_s,
		ram_we_o				=> ram_we_s,
		ram_oe_o				=> ram_oe_s,
		ram_data_i			=> d_from_ram_s,
		ram_data_o			=> d_to_ram_s,
		-- Video RAM Interface
		vram_addr_o			=> vram_addr_s,
		vram_ce_o			=> vram_ce_s,
		vram_oe_o			=> vram_oe_s,
		vram_we_o			=> vram_we_s,
		vram_data_i			=> vram_do_s,
		vram_data_o			=> vram_di_s,
		-- Cartridge ROM Interface
		cart_addr_o			=> open,
		cart_data_i			=> (others => '1'),
		cart_en_80_n_o		=> open,
		cart_en_a0_n_o		=> open,
		cart_en_c0_n_o		=> open,
		cart_en_e0_n_o		=> open,
		-- Audio Interface
		audio_o				=> open,
		audio_signed_o		=> audio_signed_s,
		-- RGB Video Interface
		col_o					=> rgb_col_s,
		rgb_r_o				=> open,
		rgb_g_o				=> open,
		rgb_b_o				=> open,
		hsync_n_o			=> rgb_hsync_n_s,
		vsync_n_o			=> rgb_vsync_n_s,
		comp_sync_n_o		=> open,
		-- SPI
		spi_miso_i			=> spi_miso_i,
		spi_mosi_o			=> spi_mosi_o,
		spi_sclk_o			=> spi_sclk_o,
		spi_cs_n_o			=> spi_cs_n_s,
		-- DEBUG
		D_cpu_addr			=> open
	);

	-- SRAM CY7C1019CV33-12VC
	sram0: entity work.dpSRAM_1288
	port map (
		clk_i				=> clock_mem_s,
		-- Porta 0
		porta0_addr_i	=> ram_addr_s,
		porta0_ce_i		=> ram_ce_s,
		porta0_oe_i		=> ram_oe_s,
		porta0_we_i		=> ram_we_s,
		porta0_data_i	=> d_to_ram_s,
		porta0_data_o	=> d_from_ram_s,
		-- Porta 1
		porta1_addr_i	=> "111" & vram_addr_s,
		porta1_ce_i		=> vram_ce_s,
		porta1_oe_i		=> vram_oe_s,
		porta1_we_i		=> vram_we_s,
		porta1_data_i	=> vram_di_s,
		porta1_data_o	=> vram_do_s,
		-- Output to SRAM in board
		sram_addr_o		=> sram_addr_o,
		sram_data_io	=> sram_data_io,
		sram_ce_n_o		=> sram_ce_n_o,
		sram_oe_n_o		=> sram_oe_n_o,
		sram_we_n_o		=> sram_we_n_o
	);

	-- Audio
	audioout: entity work.dac
	generic map (
		msbi_g		=> 7
	)
	port map (
		clk_i		=> clock_master_s,
		res_i		=> reset_s,
		dac_i		=> audio_s,
		dac_o		=> audio_dac_o
	);

	-- Scandoubler button
	btndbl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> btn_dblscan_i,
		result_o			=> btn_dblscan_s
	);

	-- Scanline button
	btnscl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> btn_scanlines_i,
		result_o			=> btn_scanlines_s
	);

	-----------------------------------------------------------------------------
	-- SNES Gamepads
	-----------------------------------------------------------------------------
	snespads_b : entity work.snespad
	generic map (
		num_pads_g			=> 2,
		reset_level_g		=> 0,
		button_level_g		=> 0,
		clocks_per_6us_g	=> 128					-- 6us = 128 ciclos de 21.477MHz
	)
	port map (
		clk_i					=> clock_master_s,
		reset_i				=> por_n_s,
		pad_clk_o			=> pad_clk_o,
		pad_latch_o			=> pad_latch_o,
		pad_data_i			=> pad_data_i,
		but_a_o				=> but_a_s,
		but_b_o				=> but_b_s,
		but_x_o				=> but_x_s,
		but_y_o				=> but_y_s,
		but_start_o			=> but_start_s,
		but_sel_o			=> but_sel_s,
		but_tl_o				=> but_tl_s,
		but_tr_o				=> but_tr_s,
		but_up_o				=> but_up_s,
		but_down_o			=> but_down_s,
		but_left_o			=> but_left_s,
		but_right_o			=> but_right_s
	);

	-----------------------------------------------------------------------------
	-- VGA Scan Doubler
	-----------------------------------------------------------------------------
	dblscan_b : entity work.dblscan
	port map (
		clk_6m_i			=> clock_master_s,
		clk_en_6m_i		=> clock_5m_en_s,
		clk_12m_i		=> clock_master_s,
		clk_en_12m_i	=> clock_vdp_en_s,
		col_i				=> rgb_col_s,
		col_o				=> vga_col_s,
		oddline_o		=> oddline_s,
		hsync_n_i		=> rgb_hsync_n_s,
		vsync_n_i		=> rgb_vsync_n_s,
		hsync_n_o		=> vga_hsync_n_s,
		vsync_n_o		=> vga_vsync_n_s,
		blank_o			=> open
	);

	-- Glue Logic
	audio_s <= std_logic_vector(unsigned(audio_signed_s + 128));

	por_n_s		<= pll_locked_s and btn_reset_n_i;
	reset_s		<= not por_n_s or soft_reset_s;

	spi_cs_n_o 	<= spi_cs_n_s;

	-- Double Scanner
	process (por_n_s, btn_dblscan_s)
	begin
		if por_n_s = '0' then
			dblscan_en_s <= '1';							-- Enabled by default
		elsif falling_edge(btn_dblscan_s) then
			dblscan_en_s <= not dblscan_en_s;
		end if;
	end process;
	
	-- Scanlines
	process (por_n_s, btn_scanlines_s)
	begin
		if por_n_s = '0' then
			scanlines_en_s <= '0';
		elsif falling_edge(btn_scanlines_s) then
			scanlines_en_s <= not scanlines_en_s;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- VGA Output
	-----------------------------------------------------------------------------
	-- Process vga_col
	--
	-- Purpose:
	--   Converts the color information (doubled to VGA scan) to RGB values.
	--
	vga_col : process (clock_master_s, reset_s)
		variable vga_col_v : natural range 0 to 15;
		variable vga_r_v,
					vga_g_v,
					vga_b_v   : rgb_val_t;
	begin
		if reset_s = '1' then
			vga_rgb_r_o <= (others => '0');
			vga_rgb_g_o <= (others => '0');
			vga_rgb_b_o <= (others => '0');
		elsif rising_edge(clock_master_s) then
			if clock_vdp_en_s = '1' then
				if dblscan_en_s = '0' then
					vga_col_v := to_integer(unsigned(rgb_col_s));
				else
					vga_col_v := to_integer(unsigned(vga_col_s));
				end if;
				vga_r_v   := full_rgb_table_c(vga_col_v)(r_c);
				vga_g_v   := full_rgb_table_c(vga_col_v)(g_c);
				vga_b_v   := full_rgb_table_c(vga_col_v)(b_c);
				if (dblscan_en_s = '1' and scanlines_en_s = '1' and oddline_s = '1') then
					-- scanlines ativo, reduzir brilho das linhas impares
					vga_rgb_r_o	<= '0' & std_logic_vector(to_unsigned(vga_r_v, 8))(6 downto 4);
					vga_rgb_g_o	<= '0' & std_logic_vector(to_unsigned(vga_g_v, 8))(6 downto 4);
					vga_rgb_b_o	<= '0' & std_logic_vector(to_unsigned(vga_b_v, 8))(6 downto 4);
				else
					vga_rgb_r_o	<= std_logic_vector(to_unsigned(vga_r_v, 8))(7 downto 4);
					vga_rgb_g_o	<= std_logic_vector(to_unsigned(vga_g_v, 8))(7 downto 4);
					vga_rgb_b_o	<= std_logic_vector(to_unsigned(vga_b_v, 8))(7 downto 4);
				end if;
			end if;
		end if;
	end process vga_col;

	vga_hsync_n_o	<= rgb_hsync_n_s	when dblscan_en_s = '0'		else vga_hsync_n_s;
	vga_vsync_n_o	<= rgb_vsync_n_s	when dblscan_en_s = '0'		else vga_vsync_n_s;

	-- Joystick
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
							but_tl_s, but_tr_s, autofire_cnt_q)
		variable key_v : natural range cv_keys_t'range;
	begin
		-- quadrature device not implemented
		ctrl_p7_s          <= "11";
		ctrl_p9_s          <= "11";

		-- RESET if the START and SEL buttons of controller 1 are pressed together
		if but_start_s(0) = '0' and but_sel_s(0) = '0' then
			soft_reset_s <= '1';
		else
			soft_reset_s <= '0';
		end if;

		for idx in 1 to 2 loop
			if ctrl_p5_s(idx) = '0' and ctrl_p8_s(idx) = '1' then
				-- keys and right button enabled --------------------------------------

				key_v := cv_key_none_c;

				if but_tl_s(idx-1) = '0' then				-- TL button pressed, numbers 1 at 6
					if    but_y_s(idx-1) = '0' then
						-- KEY 1
						key_v := cv_key_1_c;
					elsif but_x_s(idx-1) = '0' then
						-- KEY 2
						key_v := cv_key_2_c;
					elsif but_b_s(idx-1) = '0' then
						-- KEY 3
						key_v := cv_key_3_c;
					elsif but_a_s(idx-1) = '0' then
						-- KEY 4
						key_v := cv_key_4_c;
					elsif but_sel_s(idx-1) = '0' then
						-- KEY 5
						key_v := cv_key_5_c;
					elsif but_start_s(idx-1) = '0' then
						-- KEY 6
						key_v := cv_key_6_c;
					end if;
				elsif but_tr_s(idx-1) = '0' then			-- TR button pressed, 7 at 0, * and #
					if    but_y_s(idx-1) = '0' then
						-- KEY 7
						key_v := cv_key_7_c;
					elsif but_x_s(idx-1) = '0' then
						-- KEY 8
						key_v := cv_key_8_c;
					elsif but_b_s(idx-1) = '0' then
						-- KEY 9
						key_v := cv_key_9_c;
					elsif but_a_s(idx-1) = '0' then
						-- KEY 0
						key_v := cv_key_0_c;
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

				if but_tl_s(idx-1) = '1' and but_tr_s(idx-1) = '1' then	-- fire 2 only if the TL and TR buttons are not pressed
					ctrl_p6_s(idx) <= but_a_s(idx-1) and (but_x_s(idx-1) or autofire_cnt_q(19));	-- A button or X(auto-fire) button is fire 2
				else
					ctrl_p6_s(idx) <= '1';
				end if;

			elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
				-- joystick and left button enabled -----------------------------------
				ctrl_p1_s(idx) <= but_up_s(idx-1);
				ctrl_p2_s(idx) <= but_down_s(idx-1);
				ctrl_p3_s(idx) <= but_left_s(idx-1);
				ctrl_p4_s(idx) <= but_right_s(idx-1);
				if but_tl_s(idx-1) = '1' and but_tr_s(idx-1) = '1' then	-- fire 1 only if the TL and TR buttons are not pressed
					ctrl_p6_s(idx) <= but_b_s(idx-1) and (but_y_s(idx-1) or autofire_cnt_q(19));	-- B button or Y(auto-fire) button is fire 1
				else
					ctrl_p6_s(idx) <= '1';
				end if;
			else
				-- nothing active -----------------------------------------------------
				ctrl_p1_s(idx) <= '1';
				ctrl_p2_s(idx) <= '1';
				ctrl_p3_s(idx) <= '1';
				ctrl_p4_s(idx) <= '1';
				ctrl_p6_s(idx) <= '1';
			end if;
		end loop;
	end process pad_ctrl;
	
	process (por_n_s, clock_3m_en_s)
	begin
		if por_n_s = '0' then
			autofire_cnt_q	<= (others => '0');
		elsif rising_edge(clock_3m_en_s) then
			autofire_cnt_q <= autofire_cnt_q + 1;
		end if;
	end process;


end architecture;