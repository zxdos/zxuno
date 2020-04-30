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

-- altera message_off 10540 10541

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;

entity coleco_top is
	generic (
		sdram64mb_g				: boolean	:= true
	);
	port (
		-- Clock (48MHz)
		clock_48M_i				: in    std_logic;
		-- SDRAM
		sdram_clock_o			: out   std_logic									:= '0';
		sdram_cke_o    	  	: out   std_logic									:= '0';
		sdram_addr_o			: out   std_logic_vector(12 downto 0)		:= (others => '0');
		sdram_dq_io				: inout std_logic_vector(15 downto 0)		:= (others => 'Z');
		sdram_ba_o				: out   std_logic_vector( 1 downto 0)		:= (others => '0');
		sdram_dqml_o			: out   std_logic									:= '1';
		sdram_dqmh_o			: out   std_logic									:= '1';
		sdram_cs_n_o   	  	: out   std_logic									:= '1';
		sdram_we_n_o			: out   std_logic									:= '1';
		sdram_cas_n_o			: out   std_logic									:= '1';
		sdram_ras_n_o			: out   std_logic									:= '1';
		-- SPI FLASH (W25Q32)
		flash_clk_o				: out   std_logic									:= '0';
		flash_data_i			: in    std_logic;
		flash_data_o			: out   std_logic									:= '0';
		flash_cs_n_o			: out   std_logic									:= '1';
		-- VGA 5:6:5
		vga_r_o					: out   std_logic_vector(4 downto 0)		:= (others => '0');
		vga_g_o					: out   std_logic_vector(5 downto 0)		:= (others => '0');
		vga_b_o					: out   std_logic_vector(4 downto 0)		:= (others => '0');
		vga_hs_o					: out   std_logic									:= '1';
		vga_vs_o					: out   std_logic									:= '1';
		-- UART
		uart_tx_o				: out   std_logic									:= '1';
		uart_rx_i				: in    std_logic;
		-- External I/O
		keys_n_i					: in    std_logic_vector(3 downto 0);
		buzzer_o					: out   std_logic									:= '1';
		-- ADC
		adc_clock_o				: out   std_logic									:= '0';
		adc_data_i				: in    std_logic;
		adc_cs_n_o				: out   std_logic									:= '1';
		-- PS/2 Keyboard
		ps2_clk_io				: inout std_logic									:= 'Z';
		ps2_dat_io		 		: inout std_logic									:= 'Z';
		-- SD (DIY)
		sd_sclk_o				: out   std_logic									:= '0';
		sd_mosi_o				: out   std_logic									:= '0';
		sd_miso_i				: in    std_logic;
		sd_cs_n_o				: out   std_logic									:= '1';
		-- DAC (DIY)
		audio_dac_l_o			: out   std_logic									:= '0';
		audio_dac_r_o			: out   std_logic									:= '0'
	);
end;

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
	signal spi_data_in_s		: std_logic_vector(7 downto 0);
	signal spi_data_out_s	: std_logic_vector(7 downto 0);

	-- Audio
	signal audio_signed_s	: signed(7 downto 0);
	signal audio_s				: std_logic_vector(7 downto 0);
	signal audio_dac_s		: std_logic;

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

begin

	-- PLL
	pll: entity work.pll1
	port map (
		inclk0	=> clock_48M_i,
		c0			=> clock_master_s,		-- 21.428571
		c1			=> clock_mem_s,			-- 100 MHz   0º
		c2			=> sdram_clock_o,			-- 100 MHz -90°
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
		num_maq_g		=> 5,
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
		spi_miso_i			=> sd_miso_i,
		spi_mosi_o			=> sd_mosi_o,
		spi_sclk_o			=> sd_sclk_o,
		spi_cs_n_o			=> sd_cs_n_o,
		-- DEBUG
		D_cpu_addr			=> open
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

	-- SDRAM
	sdram256mb: if not sdram64mb_g generate
		--
		ram: entity work.dpSDRAM256Mb
		generic map (
			freq_g			=> 100
		)
		port map (
			clock_i			=> clock_mem_s,
			reset_i			=> reset_s,
			refresh_i		=> '1',
			-- Port 0
			port0_cs_i		=> vram_ce_s,
			port0_oe_i		=> vram_oe_s,
			port0_we_i		=> vram_we_s,
			port0_addr_i	=> "00000011111" & vram_addr_s,
			port0_data_i	=> vram_di_s,
			port0_data_o	=> vram_do_s,
			-- Port 1
			port1_cs_i		=> ram_ce_s,
			port1_oe_i		=> ram_oe_s,
			port1_we_i		=> ram_we_s,
			port1_addr_i	=> "00000000" & ram_addr_s,
			port1_data_i	=> d_to_ram_s,
			port1_data_o	=> d_from_ram_s,
			-- SDRAM in board
			mem_cke_o		=> sdram_cke_o,
			mem_cs_n_o		=> sdram_cs_n_o,
			mem_ras_n_o		=> sdram_ras_n_o,
			mem_cas_n_o		=> sdram_cas_n_o,
			mem_we_n_o		=> sdram_we_n_o,
			mem_udq_o		=> sdram_dqmh_o,
			mem_ldq_o		=> sdram_dqml_o,
			mem_ba_o			=> sdram_ba_o,
			mem_addr_o		=> sdram_addr_o,
			mem_data_io		=> sdram_dq_io
		);
	end generate;

	sdram64mb: if sdram64mb_g generate
		--
		ram: entity work.dpSDRAM64Mb
		generic map (
			freq_g			=> 100
		)
		port map (
			clock_i			=> clock_mem_s,
			reset_i			=> reset_s,
			refresh_i		=> '1',
			-- Port 0
			port0_cs_i		=> vram_ce_s,
			port0_oe_i		=> vram_oe_s,
			port0_we_i		=> vram_we_s,
			port0_addr_i	=> "000011111" & vram_addr_s,
			port0_data_i	=> vram_di_s,
			port0_data_o	=> vram_do_s,
			-- Port 1
			port1_cs_i		=> ram_ce_s,
			port1_oe_i		=> ram_oe_s,
			port1_we_i		=> ram_we_s,
			port1_addr_i	=> "000000" & ram_addr_s,
			port1_data_i	=> d_to_ram_s,
			port1_data_o	=> d_from_ram_s,
			-- SDRAM in board
			mem_cke_o		=> sdram_cke_o,
			mem_cs_n_o		=> sdram_cs_n_o,
			mem_ras_n_o		=> sdram_ras_n_o,
			mem_cas_n_o		=> sdram_cas_n_o,
			mem_we_n_o		=> sdram_we_n_o,
			mem_udq_o		=> sdram_dqmh_o,
			mem_ldq_o		=> sdram_dqml_o,
			mem_ba_o			=> sdram_ba_o,
			mem_addr_o		=> sdram_addr_o(11 downto 0),
			mem_data_io		=> sdram_dq_io
		);
	end generate;

	-- Controller
	-- PS/2 keyboard interface
	ps2if_inst : entity work.colecoKeyboard
	port map (
		clk		=> clock_master_s,
		reset		=> reset_s,
		-- inputs from PS/2 port
		ps2_clk	=> ps2_clk_io,
		ps2_data	=> ps2_dat_io,
		-- user outputs
		keys		=> ps2_keys_s,
		joy		=> ps2_joy_s
	);

	-- Scandoubler button
	btndbl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> keys_n_i(1),
		result_o			=> btn_dblscan_s
	);

	-- Scanline button
	btnscl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> keys_n_i(2),
		result_o			=> btn_scanlines_s
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
	audio_s			<= std_logic_vector(unsigned(audio_signed_s + 128));
	audio_dac_l_o	<= audio_dac_s;
	audio_dac_r_o	<= audio_dac_s;

	reset_s		<= not pll_locked_s or not keys_n_i(0) or soft_reset_s;
	por_n_s		<= pll_locked_s;

	-----------------------------------------------------------------------------
	-- Process pad_ctrl
	--
	-- Purpose:
	--   Maps the gamepad signals to the controller buses of the console.
	--
	pad_ctrl: process (ctrl_p5_s, ctrl_p8_s, ps2_keys_s, ps2_joy_s)
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

				if (idx = 1) then
					ctrl_p6_s(idx) <= not ps2_keys_s(0); -- button right (0)
				else
					ctrl_p6_s(idx) <= not ps2_joy_s(4);
				end if;

			elsif ctrl_p5_s(idx) = '1' and ctrl_p8_s(idx) = '0' then
				-- joystick and left button enabled -----------------------------------
				ctrl_p1_s(idx) <= not ps2_joy_s(0);	-- up
				ctrl_p2_s(idx) <= not ps2_joy_s(1); -- down
				ctrl_p3_s(idx) <= not ps2_joy_s(2); -- left
				ctrl_p4_s(idx) <= not ps2_joy_s(3); -- right
		  
				if (idx = 1) then
					ctrl_p6_s(idx) <= not ps2_joy_s(4); -- button left (4)
				else
					ctrl_p6_s(idx) <= not ps2_keys_s(0); -- button right(0)
				end if;
			
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
			vga_r_o <= (others => '0');
			vga_g_o <= (others => '0');
			vga_b_o <= (others => '0');
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
					vga_r_o	<= '0' & std_logic_vector(to_unsigned(vga_r_v, 8))(6 downto 3);
					vga_g_o	<= '0' & std_logic_vector(to_unsigned(vga_g_v, 8))(6 downto 2);
					vga_b_o	<= '0' & std_logic_vector(to_unsigned(vga_b_v, 8))(6 downto 3);
				else
					vga_r_o	<= std_logic_vector(to_unsigned(vga_r_v, 8))(7 downto 3);
					vga_g_o	<= std_logic_vector(to_unsigned(vga_g_v, 8))(7 downto 2);
					vga_b_o	<= std_logic_vector(to_unsigned(vga_b_v, 8))(7 downto 3);
				end if;
			end if;
		end if;
	end process vga_col;

	vga_hs_o	<= rgb_hsync_n_s	when dblscan_en_s = '0'		else vga_hsync_n_s;
	vga_vs_o	<= rgb_vsync_n_s	when dblscan_en_s = '0'		else vga_vsync_n_s;

end architecture;