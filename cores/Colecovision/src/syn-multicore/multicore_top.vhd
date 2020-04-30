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

-- a-ltera message_off 10540 10541

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity multicore_top is
	generic (
		hdmi_output_g	: boolean	:= true
	);
	port (
		-- Clocks
		clock_50_i			: in    std_logic;

		-- Buttons
		btn_n_i				: in    std_logic_vector(4 downto 1);
		btn_oe_n_i			: in    std_logic;
		btn_clr_n_i			: in    std_logic;

		-- SRAM (AS7C34096)
		sram_addr_o			: out   std_logic_vector(18 downto 0)	:= (others => '0');
		sram_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram_we_n_o			: out   std_logic								:= '1';
		sram_ce_n_o			: out   std_logic_vector(1 downto 0)	:= (others => '1');
		sram_oe_n_o			: out   std_logic								:= '1';

		-- PS2
		ps2_clk_io			: inout std_logic								:= 'Z';
		ps2_data_io			: inout std_logic								:= 'Z';
		ps2_mouse_clk_io  : inout std_logic								:= 'Z';
		ps2_mouse_data_io : inout std_logic								:= 'Z';

		-- SD Card
		sd_cs_n_o			: out   std_logic								:= '1';
		sd_sclk_o			: out   std_logic								:= '0';
		sd_mosi_o			: out   std_logic								:= '0';
		sd_miso_i			: in    std_logic;

		-- Joystick
		joy1_up_i			: in    std_logic;
		joy1_down_i			: in    std_logic;
		joy1_left_i			: in    std_logic;
		joy1_right_i		: in    std_logic;
		joy1_p6_i			: in    std_logic;
		joy1_p7_o			: out   std_logic								:= '1';
		joy1_p9_i			: in    std_logic;
		joy2_up_i			: in    std_logic;
		joy2_down_i			: in    std_logic;
		joy2_left_i			: in    std_logic;
		joy2_right_i		: in    std_logic;
		joy2_p6_i			: in    std_logic;
		joy2_p7_o			: out   std_logic								:= '1';
		joy2_p9_i			: in    std_logic;

		-- Audio
		dac_l_o				: out   std_logic								:= '0';
		dac_r_o				: out   std_logic								:= '0';
		ear_i					: in    std_logic;
		mic_o					: out   std_logic								:= '0';

		-- VGA
		vga_r_o				: out   std_logic_vector(2 downto 0)	:= (others => '0');
		vga_g_o				: out   std_logic_vector(2 downto 0)	:= (others => '0');
		vga_b_o				: out   std_logic_vector(2 downto 0)	:= (others => '0');
		vga_hsync_n_o		: out   std_logic								:= '1';
		vga_vsync_n_o		: out   std_logic								:= '1';

		-- Debug
		leds_n_o				: out   std_logic_vector(7 downto 0)	:= (others => '1')
	);
end entity;

use work.vdp18_col_pack.all;
use work.cv_keys_pack.all;

architecture behavior of multicore_top is

	-- Resets
	signal pll_locked_s		: std_logic;
	signal reset_s				: std_logic;
	signal soft_reset_s		: std_logic;
	signal por_n_s				: std_logic;

	-- Clocks
	signal clock_master_s	: std_logic;
	signal clock_mem_s		: std_logic;
	signal clock_vga_s		: std_logic;
	signal clock_dvi_s		: std_logic;
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

	-- Audio
	signal audio_signed_s	: signed(7 downto 0);
	signal audio_s				: std_logic_vector(7 downto 0);
	signal audio_dac_s		: std_logic;

	-- Video
	signal rgb_col_s			: std_logic_vector( 3 downto 0);		-- 15KHz
	signal rgb_hsync_n_s		: std_logic;								-- 15KHz
	signal rgb_vsync_n_s		: std_logic;								-- 15KHz
	signal cnt_hor_s			: std_logic_vector( 8 downto 0);
	signal cnt_ver_s			: std_logic_vector( 7 downto 0);
	signal vga_col_s			: std_logic_vector( 3 downto 0);
	signal vga_r_s				: std_logic_vector( 3 downto 0);
	signal vga_g_s				: std_logic_vector( 3 downto 0);
	signal vga_b_s				: std_logic_vector( 3 downto 0);
	signal vga_hsync_n_s		: std_logic;
	signal vga_vsync_n_s		: std_logic;
	signal vga_blank_s		: std_logic;
	signal sound_hdmi_s		: std_logic_vector(15 downto 0);
	signal tdms_s				: std_logic_vector( 7 downto 0);
	signal btn_scan_s			: std_logic;
	signal scanlines_en_s	: std_logic;
	signal odd_line_s			: std_logic;

	-- Keyboard
	signal ps2_keys_s			: std_logic_vector(15 downto 0);
	signal ps2_joy_s			: std_logic_vector(15 downto 0);

	-- Controller
	signal ctrl_p1_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p2_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p3_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p4_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p5_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p6_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p7_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p8_s			: std_logic_vector( 2 downto 1)	:= "00";
	signal ctrl_p9_s			: std_logic_vector( 2 downto 1)	:= "00";
	
	signal but_up_s			: std_logic_vector( 2 downto 1);
	signal but_down_s			: std_logic_vector( 2 downto 1);
	signal but_left_s			: std_logic_vector( 2 downto 1);
	signal but_right_s		: std_logic_vector( 2 downto 1);
	signal but_f1_s			: std_logic_vector( 2 downto 1);
	signal but_f2_s			: std_logic_vector( 2 downto 1);

begin

	-- PLL
	pll: entity work.pll1
	port map (
		inclk0	=> clock_50_i,
		c0			=> clock_master_s,		--  21.000
		c1			=> clock_mem_s,			--  42.000
		c2			=> clock_vga_s,			--  25.200
		c3			=> clock_dvi_s,			-- 126.000
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

	vg: entity work.colecovision
	generic map (
		num_maq_g		=> 6,
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
		cnt_hor_o			=> cnt_hor_s,
		cnt_ver_o			=> cnt_ver_s,
		rgb_r_o				=> open,
		rgb_g_o				=> open,
		rgb_b_o				=> open,
		hsync_n_o			=> rgb_hsync_n_s,
		vsync_n_o			=> rgb_vsync_n_s,
		comp_sync_n_o		=> open,
		-- SPI
		spi_miso_i			=> sd_miso_i,
		spi_mosi_o			=> sd_mosi_o,
		spi_sclk_o			=> sd_sclk_o,
		spi_cs_n_o			=> sd_cs_n_o,
		-- DEBUG
		D_cpu_addr			=> open
	);

	-- SRAM
	sram0: entity work.dpSRAM_5128
	port map (
		clk_i				=> clock_mem_s,
		-- Port 0
		porta0_addr_i	=> "00" & ram_addr_s,
		porta0_ce_i		=> ram_ce_s,
		porta0_oe_i		=> ram_oe_s,
		porta0_we_i		=> ram_we_s,
		porta0_data_i	=> d_to_ram_s,
		porta0_data_o	=> d_from_ram_s,
		-- Port 1
		porta1_addr_i	=> "11111" & vram_addr_s,
		porta1_ce_i		=> vram_ce_s,
		porta1_oe_i		=> vram_oe_s,
		porta1_we_i		=> vram_we_s,
		porta1_data_i	=> vram_di_s,
		porta1_data_o	=> vram_do_s,
		-- SRAM in board
		sram_addr_o		=> sram_addr_o,
		sram_data_io	=> sram_data_io,
		sram_ce_n_o		=> sram_ce_n_o(0),
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
		dac_o		=> audio_dac_s
	);

	-- PS/2 keyboard interface
	ps2if_inst: entity work.colecoKeyboard
	port map (
		clk		=> clock_master_s,
		reset		=> reset_s,
		-- inputs from PS/2 port
		ps2_clk	=> ps2_clk_io,
		ps2_data	=> ps2_data_io,
		-- user outputs
		keys		=> ps2_keys_s,
		joy		=> ps2_joy_s
	);

	---------------------------------
	-- scanlines
	btnscl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> btn_n_i(1) or btn_n_i(2),
		result_o			=> btn_scan_s
	);

	-- Glue Logic
	por_n_s		<= '0' when pll_locked_s = '0' or (btn_n_i(3) = '0' and btn_n_i(4) = '0')	else '1';
	reset_s		<= not pll_locked_s or not btn_n_i(3) or soft_reset_s;

	-- Controller
	but_up_s		<= joy2_up_i		& joy1_up_i;
	but_down_s	<= joy2_down_i		& joy1_down_i;
	but_left_s	<= joy2_left_i		& joy1_left_i;
	but_right_s	<= joy2_right_i	& joy1_right_i;
	but_f1_s		<= joy2_p6_i		& joy1_p6_i;
	but_f2_s		<= joy2_p9_i		& joy1_p9_i;

	-----------------------------------------------------------------------------
	-- Process pad_ctrl
	--
	-- Purpose:
	--   Maps the gamepad signals to the controller buses of the console.
	--
	pad_ctrl: process (
		ctrl_p5_s, ctrl_p8_s, ps2_keys_s, ps2_joy_s, but_up_s, but_down_s,
		but_left_s, but_right_s, but_f1_s, but_f2_s
	)
		variable key_v : natural range cv_keys_t'range;
	begin
		-- quadrature device not implemented
		ctrl_p7_s          <= "11";
		ctrl_p9_s          <= "11";

		--------------------------------------------------------------------
		-- soft reset to get to cart menu : use ps2 ESC key in keys(8)
		if ps2_keys_s(8) = '1' then
			soft_reset_s <= '1';
		else
			soft_reset_s <= '0';
		end if;
		------------------------------------------------------------------------

		for idx in 1 to 2 loop -- was 2
			if ctrl_p5_s(idx) = '0' and ctrl_p8_s(idx) = '1' then
				-- keys and right button enabled --------------------------------------
				-- keys not fully implemented

				key_v := cv_key_none_c;

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

				ctrl_p1_s(idx) <= cv_keys_c(key_v)(1);
				ctrl_p2_s(idx) <= cv_keys_c(key_v)(2);
				ctrl_p3_s(idx) <= cv_keys_c(key_v)(3);
				ctrl_p4_s(idx) <= cv_keys_c(key_v)(4);
				ctrl_p6_s(idx) <= not ps2_keys_s(0) and but_f2_s(idx);	-- button right
		  
			elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
				-- joystick and left button enabled -----------------------------------
				ctrl_p1_s(idx) <= not ps2_joy_s(0) and but_up_s(idx);		-- up
				ctrl_p2_s(idx) <= not ps2_joy_s(1) and but_down_s(idx);	-- down
				ctrl_p3_s(idx) <= not ps2_joy_s(2) and but_left_s(idx);	-- left
				ctrl_p4_s(idx) <= not ps2_joy_s(3) and but_right_s(idx);	-- right
				ctrl_p6_s(idx) <= not ps2_joy_s(4) and but_f1_s(idx);		-- button left

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

	-- Audio
	audio_s <= std_logic_vector(unsigned(audio_signed_s + 128));
	dac_l_o	<= audio_dac_s;
	dac_r_o	<= audio_dac_s;

	-----------------------------------------------------------------------------
	-- VGA Output
	-----------------------------------------------------------------------------

	process (pll_locked_s, btn_scan_s)
	begin
		if pll_locked_s = '0' then
			scanlines_en_s <= '0';
		elsif falling_edge(btn_scan_s) then
			scanlines_en_s <= not scanlines_en_s;
		end if;
	end process;

	-- VGA framebuffer
	vga: entity work.vga
	port map (
		I_CLK			=> clock_master_s,
		I_CLK_VGA	=> clock_vga_s,
		I_COLOR		=> rgb_col_s,
		I_HCNT		=> cnt_hor_s,
		I_VCNT		=> cnt_ver_s,
		O_HSYNC		=> vga_hsync_n_s,
		O_VSYNC		=> vga_vsync_n_s,
		O_COLOR		=> vga_col_s,
		O_HCNT		=> open,
		O_VCNT		=> open,
		O_H			=> open,
		O_BLANK		=> vga_blank_s
	);

	-- Scanlines
	process(vga_hsync_n_s,vga_vsync_n_s)
	begin
		if vga_vsync_n_s = '0' then
			odd_line_s <= '0';
		elsif rising_edge(vga_hsync_n_s) then
			odd_line_s <= not odd_line_s;
		end if;
	end process;

	-- Process vga_col
	--
	-- Purpose:
	--   Converts the color information (doubled to VGA scan) to RGB values.
	--
	vga_col : process (clock_vga_s)
		variable vga_col_v : natural range 0 to 15;
		variable vga_r_v,
					vga_g_v,
					vga_b_v   : rgb_val_t;
		variable vga_r2_v,
					vga_g2_v,
					vga_b2_v  : std_logic_vector(3 downto 0);
	begin
		if rising_edge(clock_vga_s) then
			vga_col_v := to_integer(unsigned(vga_col_s));
			vga_r_v   := full_rgb_table_c(vga_col_v)(r_c);
			vga_g_v   := full_rgb_table_c(vga_col_v)(g_c);
			vga_b_v   := full_rgb_table_c(vga_col_v)(b_c);
			vga_r2_v	 := std_logic_vector(to_unsigned(vga_r_v, 8))(7 downto 4);
			vga_g2_v	 := std_logic_vector(to_unsigned(vga_g_v, 8))(7 downto 4);
			vga_b2_v	 := std_logic_vector(to_unsigned(vga_b_v, 8))(7 downto 4);
			if scanlines_en_s = '1' then
				if vga_r2_v > 1 and odd_line_s = '1' then
					vga_r_s <= vga_r2_v - 2;
				else
					vga_r_s <= vga_r2_v;
				end if;
				if vga_g2_v > 1 and odd_line_s = '1' then
					vga_g_s <= vga_g2_v - 2;
				else
					vga_g_s <= vga_g2_v;
				end if;
				if vga_b2_v > 1 and odd_line_s = '1' then
					vga_b_s <= vga_b2_v - 2;
				else
					vga_b_s <= vga_b2_v;
				end if;
			else
				vga_r_s <= vga_r2_v;
				vga_g_s <= vga_g2_v;
				vga_b_s <= vga_b2_v;
			end if;
		end if;
	end process vga_col;

	uh: if hdmi_output_g generate
		-- HDMI
		inst_dvid: entity work.hdmi
		generic map (
			FREQ	=> 25200000,	-- pixel clock frequency 
			FS		=> 48000,		-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
			CTS	=> 25200,		-- CTS = Freq(pixclk) * N / (128 * Fs)
			N		=> 6144			-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
		) 
		port map (
			I_CLK_VGA		=> clock_vga_s,
			I_CLK_TMDS		=> clock_dvi_s,
			I_RED				=> vga_r_s & vga_r_s,
			I_GREEN			=> vga_g_s & vga_g_s,
			I_BLUE			=> vga_b_s & vga_b_s,
			I_BLANK			=> vga_blank_s,
			I_HSYNC			=> vga_hsync_n_s,
			I_VSYNC			=> vga_vsync_n_s,
			I_AUDIO_PCM_L 	=> sound_hdmi_s,
			I_AUDIO_PCM_R	=> sound_hdmi_s,
			O_TMDS			=> tdms_s
		);
		
		sound_hdmi_s <= '0' & audio_s & "0000000";
		vga_hsync_n_o	<= tdms_s(7);	-- 2+		10
		vga_vsync_n_o	<= tdms_s(6);	-- 2-		11
		vga_b_o(2)		<= tdms_s(5);	-- 1+		144	
		vga_b_o(1)		<= tdms_s(4);	-- 1-		143
		vga_r_o(0)		<= tdms_s(3);	-- 0+		133
		vga_g_o(2)		<= tdms_s(2);	-- 0-		132
		vga_r_o(1)		<= tdms_s(1);	-- CLK+	113
		vga_r_o(2)		<= tdms_s(0);	-- CLK-	112
	end generate;

	nuh: if not hdmi_output_g generate
		vga_r_o			<= vga_r_s(3 downto 1);
		vga_g_o			<= vga_g_s(3 downto 1);
		vga_b_o			<= vga_b_s(3 downto 1);
		vga_hsync_n_o	<= vga_hsync_n_s;
		vga_vsync_n_o	<= vga_vsync_n_s;
	end generate;

end architecture;