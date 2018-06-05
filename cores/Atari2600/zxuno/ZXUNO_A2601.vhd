--
-- ZXUNO_A2601.vhd
--
-- Atari VCS 2600 toplevel for the ZXUNO
-- 2016 DistWave
--
-- Based on the MiST port from https://github.com/wsoltys/tca2601
-- Copyright (c) 2014 W. Soltys <wsoltys@gmail.com>
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity ZXUNO_A2601 is
    port (
    
-- Clock
      CLOCK_50 : in std_logic;

-- SPI
      SPI_CLK  : out std_logic;
      SPI_MOSI : out std_logic;
      SPI_MISO : in std_logic := '1';
      SPI_CS : out std_logic;

-- LED
      LED : out std_logic;

-- Video
      VGA_R : inout std_logic_vector(2 downto 0);
      VGA_G : inout std_logic_vector(2 downto 0);
      VGA_B : inout std_logic_vector(2 downto 0);
      VGA_HS : inout std_logic;
      VGA_VS : inout std_logic;

      dVGA_R : out std_logic_vector(2 downto 0);
      dVGA_G : out std_logic_vector(2 downto 0);
      dVGA_B : out std_logic_vector(2 downto 0);
      dVGA_HS : out std_logic;
      dVGA_VS : out std_logic;

		NTSC   : out   std_logic; 
      PAL    : out   std_logic;

-- Joystick
      P_L: in std_logic;
      P_R: in std_logic;
      P_A: in std_logic;
      P_U: in std_logic;
      P_D: in std_logic;
		P_tr: inout std_logic;

-- Audio
      AUDIO_L : out std_logic;
      AUDIO_R : out std_logic;
		
-- PS2
      PS2_CLK : inout std_logic;
      PS2_DAT : inout std_logic;

-- SDRAM
      SRAM_nWE : out std_logic
    );
end entity;

-- -----------------------------------------------------------------------

architecture rtl of ZXUNO_A2601 is

-- System clocks
  signal vid_clk: std_logic := '0';
  signal ctrl_clk: std_logic := '0';

-- A2601
  signal audio: std_logic := '0';

  signal p_b: std_logic := '0';
  signal p2_l: std_logic := '0';
  signal p2_r: std_logic := '0';
  signal p2_a: std_logic := '0';
  signal p2_b: std_logic := '0';
  signal p2_u: std_logic := '0';
  signal p2_d: std_logic := '0';
  
  signal p_color: std_logic := '1';
  signal p_pal: std_logic := '0';
  signal p_dif: std_logic_vector(1 downto 0) := (others => '0');
  signal size: std_logic_vector(15 downto 0) := (others => '0');

-- User IO
  signal switches   : std_logic_vector(1 downto 0);
  signal buttons    : std_logic_vector(1 downto 0);
--  signal joy0       : std_logic_vector(7 downto 0);
--  signal joy1       : std_logic_vector(7 downto 0);
  signal joy_a_0    : std_logic_vector(15 downto 0);
  signal joy_a_1    : std_logic_vector(15 downto 0);
--  signal status     : std_logic_vector(7 downto 0);
  signal ascii_new  : std_logic;
  signal ascii_code : STD_LOGIC_VECTOR(6 DOWNTO 0);
  signal clk12k     : std_logic;
--  signal ps2Clk     : std_logic;
--  signal ps2Data    : std_logic;
--  signal ps2_scancode : std_logic_vector(7 downto 0);
  
  signal ps2k_clk_in : std_logic;
  signal ps2k_clk_out : std_logic;
  signal ps2k_dat_in : std_logic;
  signal ps2k_dat_out : std_logic;

--CtrlModule--
-- Internal video signals:  
  signal vga_vsync_i : std_logic := '0';
  signal vga_hsync_i : std_logic := '0';
  signal vga_red_i : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_green_i : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_blue_i	: std_logic_vector(7 downto 0) := (others => '0');
  
  signal osd_window : std_logic;
  signal osd_pixel : std_logic;
 
  signal scanlines : std_logic;

-- Host control signals, from the Control module
  signal host_reset_n: std_logic;
  signal host_divert_sdcard : std_logic;
  signal host_divert_keyboard : std_logic;
  signal host_pal : std_logic;
  signal host_select : std_logic;
  signal host_start : std_logic;

  signal host_bootdata : std_logic_vector(31 downto 0);
  signal host_bootdata_req : std_logic;
  signal host_bootdata_ack : std_logic;

begin

    dVGA_R <= VGA_R;
    dVGA_G <= VGA_G;
    dVGA_B <= VGA_B;
    dVGA_VS <= VGA_VS;
    dVGA_HS <= VGA_HS;
ps2k_dat_in<=PS2_DAT;
PS2_DAT <= '0' when ps2k_dat_out='0' else 'Z';
ps2k_clk_in<=PS2_CLK;
PS2_CLK <= '0' when ps2k_clk_out='0' else 'Z';

ps2k_clk_out<='1';
ps2k_dat_out<='1';

-- Control module

MyCtrlModule : entity work.CtrlModule
	port map (
		clk => ctrl_clk,
		reset_n => '1',

		-- Video signals for OSD
		vga_hsync => vga_hsync_i,
		vga_vsync => vga_vsync_i,
		osd_window => osd_window,
		osd_pixel => osd_pixel,

		-- PS2 keyboard
		ps2k_clk_in => ps2k_clk_in,
		ps2k_dat_in => ps2k_dat_in,
		
		-- SD card signals
		spi_clk => spi_clk,
		spi_mosi => spi_mosi,
		spi_miso => spi_miso,
		spi_cs => spi_cs,
		
		-- DIP switches
		dipswitches(15 downto 5) => open,
		dipswitches(4) => p_dif(1),
		dipswitches(3) => p_dif(0),
		dipswitches(2) => scanlines,
		dipswitches(1) => p_pal,
		dipswitches(0) => p_color,
		
		--ROM size
		size => size,
		
		-- Control signals
		host_divert_keyboard => host_divert_keyboard,
		host_divert_sdcard => host_divert_sdcard,
		host_reset_n => host_reset_n,
		host_start => host_start,
      host_select => host_select,
		
		-- Boot data upload signals
		host_bootdata => host_bootdata,
		host_bootdata_req => host_bootdata_req,
		host_bootdata_ack => host_bootdata_ack
	);

overlay : entity work.OSD_Overlay
	port map
	(
		clk => ctrl_clk,
		red_in => vga_red_i,
		green_in => vga_green_i,
		blue_in => vga_blue_i,
		window_in => '1',
		osd_window_in => osd_window,
		osd_pixel_in => osd_pixel,
		hsync_in => vga_hsync_i,
		red_out(7 downto 5) => VGA_R,
		red_out(4 downto 0) => open,
		green_out(7 downto 5) => VGA_G,
		green_out(4 downto 0) => open,
		blue_out(7 downto 5) => VGA_B,
		blue_out(4 downto 0) => open,
		window_out => open,
		scanline_ena => scanlines
	);

  SRAM_nWE <= '1'; -- disable ram

  VGA_HS <= vga_hsync_i;
  VGA_VS <= vga_vsync_i;
 
  NTSC <= '0';
  PAL <= '0';
  
-- -----------------------------------------------------------------------
-- A2601 core
-- -----------------------------------------------------------------------
  a2601Instance : entity work.A2601NoFlash
    port map (
      vid_clk => vid_clk,
		ram_clk => ctrl_clk,
      audio => audio,
      O_VSYNC => vga_vsync_i,
      O_HSYNC => vga_hsync_i,
      O_VIDEO_R => vga_red_i(7 downto 2),
      O_VIDEO_G => vga_green_i(7 downto 2),
      O_VIDEO_B => vga_blue_i(7 downto 2),
      res => not(host_reset_n),
      p_l => P_L,
      p_r => P_R,
      p_a => P_A,
      p_b => '1',
      p_u => P_U,
      p_d => P_D,
      p2_l => p2_l,
      p2_r => p2_r,
      p2_a => p2_a,
      p2_b => p2_b,
      p2_u => p2_u,
      p2_d => p2_d,
      paddle_0 => joy_a_0(15 downto 8),
      paddle_1 => joy_a_0(7 downto 0),
      paddle_2 => joy_a_1(15 downto 8),
      paddle_3 => joy_a_1(7 downto 0),
      paddle_ena => '0',
      p_start => not(host_start),
      p_select => not(host_select),
      p_color => p_color,
      pal => p_pal,
      p_dif => p_dif,
      bootdata => host_bootdata,
      bootdata_req => host_bootdata_req,
      bootdata_ack => host_bootdata_ack,
		size => size
    );

  AUDIO_L <= audio;
  AUDIO_R <= audio;
  LED <= '0';

-- TO-DO: Player 2 controls
  p2_l <= '1';
  p2_r <= '1';
  p2_a <= '1';
  p2_b <= '1';
  p2_u <= '1';
  p2_d <= '1';
  P_tr <= 'Z';

-- -----------------------------------------------------------------------
-- Clocks and PLL
-- -----------------------------------------------------------------------
  pllInstance : entity work.pll
    port map (
      CLK_IN1 => CLOCK_50,
      CLK_OUT1 => vid_clk,
		CLK_OUT2 => ctrl_clk
    );

end architecture;
