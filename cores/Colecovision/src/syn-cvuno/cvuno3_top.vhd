-------------------------------------------------------------------------------
--
-- ColecoFPGA project
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
-- Brian board TOP
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.vdp18_col_pack.all;

entity cvuno3_top is
	port (
		-- Clocks
		clock_50_i			: in    std_logic;

		-- Buttons
		btn_reset_n_i		: in    std_logic;

		-- SRAM
		sram_addr_o			: out   std_logic_vector(20 downto 0)	:= (others => '0');
		sram_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram_oe_n_o			: out   std_logic								:= '1';
		sram_we_n_o			: out   std_logic								:= '1';

		-- SD Card
		sd_cs_n_o			: out   std_logic								:= '1';
		sd_sclk_o			: out   std_logic								:= '0';
		sd_mosi_o			: out   std_logic								:= '0';
		sd_miso_i			: in    std_logic;
		sd_cd_n_i			: in    std_logic;

		-- Flash
		flash_cs_n_o		: out   std_logic								:= '1';
		flash_sclk_o		: out   std_logic								:= '0';
		flash_mosi_o		: out   std_logic								:= '0';
		flash_miso_i		: in    std_logic;
		flash_wp_o			: out   std_logic								:= '0';
		flash_hold_o		: out   std_logic								:= '1';

		-- PS2
		ps2_clk_io			: inout std_logic								:= 'Z';
		ps2_data_io			: inout std_logic								:= 'Z';
--		ps2_mouse_clk_io  : inout std_logic								:= 'Z';
--		ps2_mouse_data_io : inout std_logic								:= 'Z';

		-- Joystick
		joy_p5_o				: out   std_logic;
		joy_p8_o				: out   std_logic;
		joy1_p1_i			: in    std_logic;
		joy1_p2_i			: in    std_logic;
		joy1_p3_i			: in    std_logic;
		joy1_p4_i			: in    std_logic;
		joy1_p6_i			: in    std_logic;
		joy1_p7_i			: in    std_logic;
		joy1_p9_i			: in    std_logic;
		joy2_p1_i			: in    std_logic;
		joy2_p2_i			: in    std_logic;
		joy2_p3_i			: in    std_logic;
		joy2_p4_i			: in    std_logic;
		joy2_p6_i			: in    std_logic;
		joy2_p7_i			: in    std_logic;
		joy2_p9_i			: in    std_logic;

		-- Audio
		dac_l_o				: out   std_logic								:= '0';
		dac_r_o				: out   std_logic								:= '0';

		-- VGA
		vga_r_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_g_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_b_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_hsync_n_o		: out   std_logic								:= '1';
		vga_vsync_n_o		: out   std_logic								:= '1';
		stnd_o				: out   std_logic								:= '1';
		pal_clk_en_o		: out   std_logic								:= '1';

		-- HDMI
		hdmi_p_o				: out   std_logic_vector(3 downto 0);
		hdmi_n_o				: out   std_logic_vector(3 downto 0);

		-- Cartridge
		cart_addr_o			: out   std_logic_vector(14 downto 0)	:= (others => '0');
		cart_data_i			: in    std_logic_vector( 7 downto 0);
		cart_dir_o			: out   std_logic								:= '1';
		cart_oe_n_o			: out   std_logic								:= '1';
		cart_en_80_n_o		: out   std_logic								:= '1';
		cart_en_A0_n_o		: out   std_logic								:= '1';
		cart_en_C0_n_o		: out   std_logic								:= '1';
		cart_en_E0_n_o		: out   std_logic								:= '1';

		-- LED
		led_o					: out   std_logic								:= '0';
		led2_o				: out   std_logic								:= '0'
	);
end entity;

architecture behavior of cvuno3_top is

	-- Clocks
	signal clock_master_s	: std_logic;
	signal clock_mem_s		: std_logic;
	signal clock_vdp_en_s	: std_logic;
	signal clock_5m_en_s		: std_logic;
	signal clock_3m_en_s		: std_logic;
	signal clock_vga_s		: std_logic;
	signal clock_hdmi_s		: std_logic;
	signal clock_hdmi_n_s	: std_logic;

	-- Resets
	signal por_cnt_s			: unsigned(7 downto 0)				:= (others => '1');
	signal por_s				: std_logic;
	signal por_n_s				: std_logic;
	signal reset_s				: std_logic;

	-- Internal BIOS
	signal bios_addr_s		: std_logic_vector(12 downto 0);		-- 8K
	signal d_from_bios_s		: std_logic_vector( 7 downto 0);
	signal bios_ce_s			: std_logic;
	signal bios_we_s			: std_logic;

	signal d_to_cv_s			: std_logic_vector( 7 downto 0);

	-- RAM memory
	signal ram_addr_s			: std_logic_vector(16 downto 0);		-- 128K
	signal d_from_ram_s		: std_logic_vector( 7 downto 0);
	signal d_to_ram_s			: std_logic_vector( 7 downto 0);
	signal ram_ce_s			: std_logic;
	signal ram_oe_s			: std_logic;
	signal ram_we_s			: std_logic;

	-- VRAM memory
	signal vram_addr_s		: std_logic_vector(13 downto 0);		-- 16K
	signal vram_do_s			: std_logic_vector( 7 downto 0);
	signal vram_di_s			: std_logic_vector( 7 downto 0);
	signal vram_ce_s			: std_logic;
	signal vram_oe_s			: std_logic;
	signal vram_we_s			: std_logic;

	-- Audio
	signal audio_signed_s	: signed(7 downto 0);
	signal audio_s				: std_logic_vector( 7 downto 0);
	signal audio_dac_s		: std_logic;

	-- Video
	signal rgb_col_s			: std_logic_vector( 3 downto 0);		-- 15KHz
	signal cnt_hor_s			: std_logic_vector( 8 downto 0);
	signal cnt_ver_s			: std_logic_vector( 7 downto 0);
	signal vga_out_en_s		: std_logic;
	signal vga_hsync_n_s		: std_logic;
	signal vga_vsync_n_s		: std_logic;
	signal vga_blank_s		: std_logic;
	signal vga_col_s			: std_logic_vector( 3 downto 0);
	signal vga_r_s				: std_logic_vector( 3 downto 0);
	signal vga_g_s				: std_logic_vector( 3 downto 0);
	signal vga_b_s				: std_logic_vector( 3 downto 0);
	signal scanlines_en_s	: std_logic									:= '0';
	signal odd_line_s			: std_logic;
	signal sound_hdmi_s		: std_logic_vector(15 downto 0);
	signal tdms_r_s			: std_logic_vector( 9 downto 0);
	signal tdms_g_s			: std_logic_vector( 9 downto 0);
	signal tdms_b_s			: std_logic_vector( 9 downto 0);
	signal tdms_p_s			: std_logic_vector( 3 downto 0);
	signal tdms_n_s			: std_logic_vector( 3 downto 0);

	-- Controller
	signal ctrl_p1_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p2_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p3_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p4_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p5_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p6_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p7_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p8_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p9_s			: std_logic_vector( 2 downto 1);

	-- SD
	signal sd_cs_n_s			: std_logic;

begin

	-- PLL
	pll_1: entity work.pll1
	port map (
		CLK_IN1	=> clock_50_i,				--  50.000
		CLK_OUT1	=> clock_master_s,		--  21.47727 (21.739) MHz (6x NTSC)
		CLK_OUT2	=> clock_mem_s,			--  42.95454 (43.478) MHz
		CLK_OUT3 => clock_vga_s,			--  25.20000 (25.000) MHz
		CLK_OUT4	=> clock_hdmi_s,			-- 126.0000 (125.000) MHz
		CLK_OUT5	=> clock_hdmi_n_s			-- 180o
	);

	-- Clocks
	clks: entity work.clocks
	port map (
		clock_i			=> clock_master_s,
		por_i				=> por_s,
		clock_vdp_en_o	=> clock_vdp_en_s,
		clock_5m_en_o	=> clock_5m_en_s,
		clock_3m_en_o	=> clock_3m_en_s
	);

	-- The Colecovision
	vg: entity work.colecovision
	generic map (
		num_maq_g			=> 8,			-- CVUNO board
		compat_rgb_g		=> 0
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
		ram_data_i			=> d_to_cv_s,
		ram_data_o			=> d_to_ram_s,
		-- Video RAM Interface
		vram_addr_o			=> vram_addr_s,
		vram_ce_o			=> vram_ce_s,
		vram_oe_o			=> vram_oe_s,
		vram_we_o			=> vram_we_s,
		vram_data_i			=> vram_do_s,
		vram_data_o			=> vram_di_s,
		-- Cartridge ROM Interface
		cart_addr_o			=> cart_addr_o,
		cart_data_i			=> cart_data_i,
		cart_oe_n_o			=> cart_oe_n_o,
		cart_en_80_n_o		=> cart_en_80_n_o,
		cart_en_a0_n_o		=> cart_en_A0_n_o,
		cart_en_c0_n_o		=> cart_en_C0_n_o,
		cart_en_e0_n_o		=> cart_en_E0_n_o,
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
		hsync_n_o			=> open,
		vsync_n_o			=> open,
		comp_sync_n_o		=> open,
		-- SPI
		spi_miso_i			=> sd_miso_i,
		spi_mosi_o			=> sd_mosi_o,
		spi_sclk_o			=> sd_sclk_o,
		spi_cs_n_o			=> sd_cs_n_s,
		sd_cd_n_i			=> sd_cd_n_i,
		-- DEBUG
		D_cpu_addr			=> open--D_cpu_addr
	 );

	-- Internal BIOS
	bios: entity work.colecobios
	port map (
		clock_i		=> clock_master_s,
		addr_wr_i	=> bios_addr_s,
		data_i		=> d_to_ram_s,
		we_i			=> bios_we_s,
		addr_rd_i	=> bios_addr_s,
		data_o		=> d_from_bios_s
	);

	-- SRAM
	sram: entity work.dpSRAM_5128
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
		sram_addr_o		=> sram_addr_o(18 downto 0),
		sram_data_io	=> sram_data_io,
		sram_ce_n_o		=> open,
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

	-- Glue logic
	process(clock_master_s)
	begin
		if rising_edge(clock_master_s) then
			if por_cnt_s /= 0 then
				por_cnt_s <= por_cnt_s - 1;
			end if;
		end if;
	end process;

	por_s			<= '1' when por_cnt_s /= 0		else '0';
	por_n_s		<= '0' when por_cnt_s /= 0		else '1';
	reset_s		<= por_s or not btn_reset_n_i;
	audio_s		<= std_logic_vector(unsigned(audio_signed_s + 128));
	dac_l_o		<= audio_dac_s;
	dac_r_o		<= audio_dac_s;
	sd_cs_n_o	<= sd_cs_n_s;
	cart_dir_o	<= '0';

	-- Memory
	bios_addr_s	<= ram_addr_s(12 downto 0);
	bios_ce_s	<= '1' when ram_addr_s(16 downto 13) = "0000" and ram_ce_s = '1'	else '0';
	bios_we_s	<= '1' when bios_ce_s = '1' and ram_we_s = '1'							else '0';

	d_to_cv_s	<= d_from_bios_s when bios_ce_s = '1'		else d_from_ram_s;
	
	-- Controller
	ctrl_p1_s	<= joy2_p1_i & joy1_p1_i;
	ctrl_p2_s	<= joy2_p2_i & joy1_p2_i;
	ctrl_p3_s	<= joy2_p3_i & joy1_p3_i;
	ctrl_p4_s	<= joy2_p4_i & joy1_p4_i;
	ctrl_p6_s	<= joy2_p6_i & joy1_p6_i;
	ctrl_p7_s	<= joy2_p7_i & joy1_p7_i;
	ctrl_p9_s	<= joy2_p9_i & joy1_p9_i;
	joy_p5_o		<= ctrl_p5_s(1);
	joy_p8_o		<= ctrl_p8_s(1);


	-----------------------------------------------------------------------------
	-- VGA/RGB Output
	-----------------------------------------------------------------------------
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

	-- VGA
	process (clock_vga_s)
		variable vga_col_v	: natural range 0 to 15;
		variable vga_r_v,
					vga_g_v,
					vga_b_v		: rgb_val_t;
		variable vga_r1_v,
					vga_g1_v,
					vga_b1_v		: std_logic_vector(7 downto 0);
		variable vga_r2_v,
					vga_g2_v,
					vga_b2_v		: std_logic_vector(3 downto 0);
	begin
		if rising_edge(clock_vga_s) then
			vga_col_v := to_integer(unsigned(vga_col_s));
			vga_r_v   := full_rgb_table_c(vga_col_v)(r_c);
			vga_g_v   := full_rgb_table_c(vga_col_v)(g_c);
			vga_b_v   := full_rgb_table_c(vga_col_v)(b_c);
			vga_r1_v	 := std_logic_vector(to_unsigned(vga_r_v, 8));
			vga_g1_v	 := std_logic_vector(to_unsigned(vga_g_v, 8));
			vga_b1_v	 := std_logic_vector(to_unsigned(vga_b_v, 8));
			vga_r2_v	 := vga_r1_v(7 downto 4);
			vga_g2_v	 := vga_g1_v(7 downto 4);
			vga_b2_v	 := vga_b1_v(7 downto 4);
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

	vga_r_o			<= vga_r_s;
	vga_g_o			<= vga_g_s;
	vga_b_o			<= vga_b_s;
	vga_hsync_n_o	<= vga_hsync_n_s;
	vga_vsync_n_o	<= vga_vsync_n_s;

	-- HDMI
	sound_hdmi_s <= '0' & audio_s & audio_s(7 downto 1);

	hdmi: entity work.hdmi
	generic map (
		FREQ	=> 25200000,	-- pixel clock frequency 
		FS		=> 48000,		-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
		CTS	=> 25200,		-- CTS = Freq(pixclk) * N / (128 * Fs)
		N		=> 6144			-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
	)
	port map (
		I_CLK_PIXEL		=> clock_vga_s,
		I_R				=> vga_r_s & vga_r_s,
		I_G				=> vga_g_s & vga_g_s,
		I_B				=> vga_b_s & vga_b_s,
		I_BLANK			=> vga_blank_s,
		I_HSYNC			=> vga_hsync_n_s,
		I_VSYNC			=> vga_vsync_n_s,
		-- PCM audio
		I_AUDIO_ENABLE	=> '1',
		I_AUDIO_PCM_L 	=> sound_hdmi_s,
		I_AUDIO_PCM_R	=> sound_hdmi_s,
		-- TMDS parallel pixel synchronous outputs (serialize LSB first)
		O_RED				=> tdms_r_s,
		O_GREEN			=> tdms_g_s,
		O_BLUE			=> tdms_b_s
	);

	hdmio: entity work.hdmi_out_xilinx
	port map (
		clock_pixel_i		=> clock_vga_s,
		clock_tdms_i		=> clock_hdmi_s,
		clock_tdms_n_i		=> clock_hdmi_n_s,
		red_i					=> tdms_r_s,
		green_i				=> tdms_g_s,
		blue_i				=> tdms_b_s,
		tmds_out_p			=> hdmi_p_o,
		tmds_out_n			=> hdmi_n_o
	);

	-- LED
	led_o		<= not sd_cs_n_s;
	led2_o	<= '0';

end architecture;