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
--
--
--

-- altera message_off 10540 10541

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generic top-level entity for Altera DE2 board
entity de2_top is
	port (
		-- Clocks
		CLOCK_27       : in    std_logic;
		CLOCK_50       : in    std_logic;
		EXT_CLOCK      : in    std_logic;

		-- Switches
		SW             : in    std_logic_vector(17 downto 0);
		-- Buttons
		KEY            : in    std_logic_vector(3 downto 0);

		-- 7 segment displays
		HEX0           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX1           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX2           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX3           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX4           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX5           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX6           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		HEX7           : out   std_logic_vector(6 downto 0)		:= (others => '1');
		
		-- Red LEDs
		LEDR           : out   std_logic_vector(17 downto 0)		:= (others => '0');
		-- Green LEDs
		LEDG           : out   std_logic_vector(8 downto 0)		:= (others => '0');

		-- Serial
		UART_RXD       : in    std_logic;
		UART_TXD       : out   std_logic									:= '1';

		-- IRDA
		IRDA_RXD       : in    std_logic;
		IRDA_TXD       : out   std_logic									:= '0';

		-- SDRAM
		DRAM_ADDR      : out   std_logic_vector(11 downto 0)		:= (others => '0');
		DRAM_DQ        : inout std_logic_vector(15 downto 0)		:= (others => 'Z');
		DRAM_BA_0      : out   std_logic									:= '1';
		DRAM_BA_1      : out   std_logic									:= '1';
		DRAM_CAS_N     : out   std_logic									:= '1';
		DRAM_CKE       : out   std_logic									:= '1';
		DRAM_CLK       : out   std_logic									:= '1';
		DRAM_CS_N      : out   std_logic									:= '1';
		DRAM_LDQM      : out   std_logic									:= '1';
		DRAM_RAS_N     : out   std_logic									:= '1';
		DRAM_UDQM      : out   std_logic									:= '1';
		DRAM_WE_N      : out   std_logic									:= '1';

		-- Flash
		FL_ADDR        : out   std_logic_vector(21 downto 0)		:= (others => '0');
		FL_DQ          : inout std_logic_vector(7 downto 0)		:= (others => 'Z');
		FL_RST_N       : out   std_logic									:= '1';
		FL_OE_N        : out   std_logic									:= '1';
		FL_WE_N        : out   std_logic									:= '1';
		FL_CE_N        : out   std_logic									:= '1';

		-- SRAM
		SRAM_ADDR      : out   std_logic_vector(17 downto 0)		:= (others => '0');
		SRAM_DQ        : inout std_logic_vector(15 downto 0)		:= (others => 'Z');
		SRAM_CE_N      : out   std_logic									:= '1';
		SRAM_OE_N      : out   std_logic									:= '1';
		SRAM_WE_N      : out   std_logic									:= '1';
		SRAM_UB_N      : out   std_logic									:= '1';
		SRAM_LB_N      : out   std_logic									:= '1';

		--	ISP1362 Interface	
		OTG_ADDR       : out   std_logic_vector(1 downto 0)		:= (others => '0');	--	ISP1362 Address 2 Bits
		OTG_DATA       : inout std_logic_vector(15 downto 0)		:= (others => 'Z');	--	ISP1362 Data bus 16 Bits
		OTG_CS_N       : out   std_logic									:= '1';					--	ISP1362 Chip Select
		OTG_RD_N       : out   std_logic									:= '1';					--	ISP1362 Write
		OTG_WR_N       : out   std_logic									:= '1';					--	ISP1362 Read
		OTG_RST_N      : out   std_logic									:= '1';					--	ISP1362 Reset
		OTG_FSPEED     : out   std_logic									:= 'Z';					--	USB Full Speed,	0 = Enable, Z = Disable
		OTG_LSPEED     : out   std_logic									:= 'Z';					--	USB Low Speed, 	0 = Enable, Z = Disable
		OTG_INT0       : in    std_logic;															--	ISP1362 Interrupt 0
		OTG_INT1       : in    std_logic;															--	ISP1362 Interrupt 1
		OTG_DREQ0      : in    std_logic;															--	ISP1362 DMA Request 0
		OTG_DREQ1      : in    std_logic;															--	ISP1362 DMA Request 1
		OTG_DACK0_N    : out   std_logic									:= '1';					--	ISP1362 DMA Acknowledge 0
		OTG_DACK1_N    : out   std_logic									:= '1';					--	ISP1362 DMA Acknowledge 1
		
		--	LCD Module 16X2		
		LCD_ON         : out   std_logic									:= '0';					--	LCD Power ON/OFF, 0 = Off, 1 = On
		LCD_BLON       : out   std_logic									:= '0';					--	LCD Back Light ON/OFF, 0 = Off, 1 = On
		LCD_DATA       : inout std_logic_vector(7 downto 0)		:= (others => '0');	--	LCD Data bus 8 bits
		LCD_RW         : out   std_logic									:= '1';					--	LCD Read/Write Select, 0 = Write, 1 = Read
		LCD_EN         : out   std_logic									:= '1';					--	LCD Enable
		LCD_RS         : out   std_logic									:= '1';					--	LCD Command/Data Select, 0 = Command, 1 = Data
		
		--	SD_Card Interface	
		SD_DAT         : inout std_logic									:= 'Z';					--	SD Card Data (SPI MISO)
		SD_DAT3        : inout std_logic									:= 'Z';					--	SD Card Data 3 (SPI /CS)
		SD_CMD         : inout std_logic									:= 'Z';					--	SD Card Command Signal (SPI MOSI)
		SD_CLK         : out   std_logic									:= '1';					--	SD Card Clock (SPI SCLK)
		
		-- I2C
		I2C_SCLK       : inout std_logic									:= 'Z';
		I2C_SDAT       : inout std_logic									:= 'Z';

		-- PS/2 Keyboard
		PS2_CLK        : inout std_logic									:= 'Z';
		PS2_DAT        : inout std_logic									:= 'Z';

		-- VGA
		VGA_R          : out   std_logic_vector(9 downto 0)		:= (others => '0');
		VGA_G          : out   std_logic_vector(9 downto 0)		:= (others => '0');
		VGA_B          : out   std_logic_vector(9 downto 0)		:= (others => '0');
		VGA_HS         : out   std_logic									:= '0';
		VGA_VS         : out   std_logic									:= '0';
		VGA_BLANK		: out   std_logic									:= '1';				
		VGA_SYNC			: out   std_logic									:= '0';	
		VGA_CLK		   : out   std_logic									:= '0';	
		
		-- Ethernet Interface	
		ENET_CLK       : out   std_logic									:= '0';					--	DM9000A Clock 25 MHz
		ENET_DATA      : inout std_logic_vector(15 downto 0)		:= (others => 'Z');	--	DM9000A DATA bus 16Bits
		ENET_CMD       : out   std_logic									:= '0';					--	DM9000A Command/Data Select, 0 = Command, 1 = Data
		ENET_CS_N      : out   std_logic									:= '1';					--	DM9000A Chip Select
		ENET_WR_N      : out   std_logic									:= '1';					--	DM9000A Write
		ENET_RD_N      : out   std_logic									:= '1';					--	DM9000A Read
		ENET_RST_N     : out   std_logic									:= '1';					--	DM9000A Reset
		ENET_INT       : in    std_logic;															--	DM9000A Interrupt
	               
		-- Audio
		AUD_XCK        : out   std_logic									:= '0';
		AUD_BCLK       : out   std_logic									:= '0';
		AUD_ADCLRCK    : out   std_logic									:= '0';
		AUD_ADCDAT     : in    std_logic;
		AUD_DACLRCK    : out   std_logic									:= '0';
		AUD_DACDAT     : out   std_logic									:= '0';

		-- TV Decoder		
		TD_DATA        : in    std_logic_vector(7 downto 0);									--	TV Decoder Data bus 8 bits
		TD_HS          : in    std_logic;															--	TV Decoder H_SYNC
		TD_VS          : in    std_logic;															--	TV Decoder V_SYNC
		TD_RESET       : out   std_logic									:= '1';					--	TV Decoder Reset
	
		-- GPIO
		GPIO_0         : inout std_logic_vector(35 downto 0)		:= (others => 'Z');
		GPIO_1         : inout std_logic_vector(35 downto 0)		:= (others => 'Z')
	);
end entity;

use work.cv_keys_pack.all;
use work.vdp18_col_pack.all;

architecture behavior of de2_top is

	-- Sinais internos
	signal pll_locked_s		: std_logic;
	signal reset_s				: std_logic;
	signal soft_reset_s		: std_logic;
	signal por_n_s				: std_logic;

	-- Clocks
	signal clock_master_s	: std_logic;
	signal clock_mem_s		: std_logic;
	signal clock_audio_s		: std_logic;
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
	signal audio_s				: std_logic_vector(7 downto 0);

	-- Video
	signal btn_dblscan_s		: std_logic;
	signal dblscan_en_s		: std_logic;
	signal rgb_col_s			: std_logic_vector( 3 downto 0);		-- 15KHz
	signal rgb_hsync_n_s		: std_logic;								-- 15KHz
	signal rgb_vsync_n_s		: std_logic;								-- 15KHz
	signal vga_col_s			: std_logic_vector( 3 downto 0);		-- 31KHz
	signal vga_hsync_n_s		: std_logic;								-- 31KHz
	signal vga_vsync_n_s		: std_logic;								-- 31KHz

	-- Keyboard
	signal ps2_keys_s			: std_logic_vector(15 downto 0);
	signal ps2_joy_s			: std_logic_vector(15 downto 0);

	-- Controle
	signal ctrl_p1_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p2_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p3_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p4_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p5_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p6_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p7_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p8_s			: std_logic_vector( 2 downto 1);
	signal ctrl_p9_s			: std_logic_vector( 2 downto 1);
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

	-- SD
	signal spi_cs_s			: std_logic;
	signal spi_data_in_s		: std_logic_vector(7 downto 0);
	signal spi_data_out_s	: std_logic_vector(7 downto 0);

	-- Debug
	signal D_display			: std_logic_vector(15 downto 0);
	signal D_cpu_addr			: std_logic_vector(15 downto 0);

begin

	--------------------------------
	-- PLL
	--------------------------------
	pll: entity work.pll1
	port map (
		inclk0		=> CLOCK_50,
		c0				=> clock_mem_s,			-- 42.857143
		c1				=> clock_master_s,		-- 21.428571 
		locked		=> pll_locked_s
	);

	pllaudio: entity work.pll2
	port map (
		inclk0		=> CLOCK_27,
		c0				=> clock_audio_s			-- 24.000000 MHz
	);

	-- Power-on reset
	por_b : entity work.cv_por
	port map (
		clock_i		=> clock_master_s,
		por_n_o		=> por_n_s
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
		num_maq_g			=> 2,
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
		audio_o				=> audio_s,
		audio_signed_o		=> open,
		-- RGB Video Interface
		col_o					=> rgb_col_s,
		rgb_r_o				=> open,
		rgb_g_o				=> open,
		rgb_b_o				=> open,
		hsync_n_o			=> rgb_hsync_n_s,
		vsync_n_o			=> rgb_vsync_n_s,
		comp_sync_n_o		=> open,
		-- SPI
		spi_miso_i			=> SD_DAT,
		spi_mosi_o			=> SD_CMD,
		spi_sclk_o			=> SD_CLK,
		spi_cs_n_o			=> SD_DAT3,
		-- DEBUG
		D_cpu_addr			=> D_cpu_addr
	 );

	-- SRAM IS61WV25616BLL
	sram0: entity work.dpSRAM_25616
	port map (
		clk_i				=> clock_mem_s,
		-- Porta 0
		porta0_addr_i	=> "00" & ram_addr_s,
		porta0_ce_i		=> ram_ce_s,
		porta0_oe_i		=> ram_oe_s,
		porta0_we_i		=> ram_we_s,
		porta0_d_i		=> d_to_ram_s,
		porta0_d_o		=> d_from_ram_s,
		-- Porta 1
		porta1_addr_i	=> "11111" & vram_addr_s,
		porta1_ce_i		=> vram_ce_s,
		porta1_oe_i		=> vram_oe_s,
		porta1_we_i		=> vram_we_s,
		porta1_d_i		=> vram_di_s,
		porta1_d_o		=> vram_do_s,
		-- Output to SRAM in board
		sram_addr_o		=> SRAM_ADDR,
		sram_data_io	=> SRAM_DQ,
		sram_ub_o		=> SRAM_UB_N,
		sram_lb_o		=> SRAM_LB_N,
		sram_ce_n_o		=> SRAM_CE_N,
		sram_oe_n_o		=> SRAM_OE_N,
		sram_we_n_o		=> SRAM_WE_N
	);

	-- Audio
	audioout: entity work.Audio_WM8731
	port map (
		clock_i			=> clock_audio_s,
		reset_i			=> reset_s,
		psg_i				=> audio_s,

		i2s_xck_o		=> AUD_XCK,
		i2s_bclk_o		=> AUD_BCLK,
		i2s_adclrck_o	=> AUD_ADCLRCK,
		i2s_adcdat_i	=> AUD_ADCDAT,
		i2s_daclrck_o	=> AUD_DACLRCK,
		i2s_dacdat_o	=> AUD_DACDAT,

		i2c_sda_io		=> I2C_SDAT,
		i2c_scl_io		=> I2C_SCLK
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
		hsync_n_i		=> rgb_hsync_n_s,
		vsync_n_i		=> rgb_vsync_n_s,
		hsync_n_o		=> vga_hsync_n_s,
		vsync_n_o		=> vga_vsync_n_s,
		blank_o			=> open
	);

	-- Scandoubler button
	btndbl: entity work.debounce
	generic map (
		counter_size_g	=> 16
	)
	port map (
		clk_i				=> clock_master_s,
		button_i			=> KEY(1),
		result_o			=> btn_dblscan_s
	);

	-- Glue logic
	reset_s		<= not pll_locked_s or not KEY(0) or soft_reset_s;


	-- VGA
	process (por_n_s, btn_dblscan_s)
	begin
		if por_n_s = '0' then
			dblscan_en_s <= '1';							-- Enabled by default
		elsif falling_edge(btn_dblscan_s) then
			dblscan_en_s <= not dblscan_en_s;
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
			VGA_R		<= (others => '0');
			VGA_G		<= (others => '0');
			VGA_B		<= (others => '0');
		elsif rising_edge(clock_master_s) then
			if clock_vdp_en_s = '1' then
				if dblscan_en_s = '0' then
					vga_col_v := to_integer(unsigned(rgb_col_s));
				else
					vga_col_v := to_integer(unsigned(vga_col_s));
				end if;
				vga_r_v	:= full_rgb_table_c(vga_col_v)(r_c);
				vga_g_v	:= full_rgb_table_c(vga_col_v)(g_c);
				vga_b_v	:= full_rgb_table_c(vga_col_v)(b_c);
				VGA_R		<= std_logic_vector(to_unsigned(vga_r_v, 8)) & "00";
				VGA_G		<= std_logic_vector(to_unsigned(vga_g_v, 8)) & "00";
				VGA_B		<= std_logic_vector(to_unsigned(vga_b_v, 8)) & "00";
			end if;
		end if;
	end process vga_col;

	VGA_HS		<= rgb_hsync_n_s	when dblscan_en_s = '0'		else vga_hsync_n_s;
	VGA_VS		<= rgb_vsync_n_s	when dblscan_en_s = '0'		else vga_vsync_n_s;
	VGA_BLANK	<= '1';
	VGA_CLK		<= clock_master_s;

	-- Controle
	-- PS/2 keyboard interface
	ps2if_inst : entity work.colecoKeyboard
	port map (
		clk		=> clock_master_s,
		reset		=> reset_s,
		-- inputs from PS/2 port
		ps2_clk	=> PS2_CLK,
		ps2_data	=> PS2_DAT,
		-- user outputs
		keys		=> ps2_keys_s,
		joy		=> ps2_joy_s
	);

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
		--------------------------------------------------------------------

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

	-- DEBUG

	LEDG(7) <= reset_s;

--	LEDG(1) <= bios_ce_n_s;
	LEDG(6) <= dblscan_en_s;


	--D_display		<= "00000000" & std_logic_vector(audio_s);
	D_display	<= D_cpu_addr;

	ld3: entity work.seg7
	port map(
		D		=> D_display(15 downto 12),
		Q		=> HEX3
	);

	ld2: entity work.seg7
	port map(
		D		=> D_display(11 downto 8),
		Q		=> HEX2
	);

	ld1: entity work.seg7
	port map(
		D		=> D_display(7 downto 4),
		Q		=> HEX1
	);

	ld0: entity work.seg7
	port map(
		D		=> D_display(3 downto 0),
		Q		=> HEX0
	);

end architecture;
