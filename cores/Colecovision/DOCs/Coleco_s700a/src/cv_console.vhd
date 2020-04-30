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
use ieee.numeric_std.all;

entity cv_console is

  generic (
    is_pal_g        : integer := 0;
    compat_rgb_g    : integer := 0
  );
  port (
    -- Global Interface -------------------------------------------------------
    clk_i           : in  std_logic;
    clk_en_10m7_i   : in  std_logic;
	 clk_cpu         : out std_logic;
    reset_n_i       : in  std_logic;
    por_n_o         : out std_logic;
    -- Controller Interface ---------------------------------------------------
    ctrl_p1_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p2_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p3_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p4_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p5_o       : out std_logic_vector( 1 downto 0);
    ctrl_p6_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p7_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p8_o       : out std_logic_vector( 1 downto 0);
    ctrl_p9_i       : in  std_logic_vector( 1 downto 0);
    -- BIOS ROM Interface -----------------------------------------------------
    bios_rom_a_o    : out std_logic_vector(12 downto 0);
    bios_rom_ce_n_o : out std_logic;
    bios_rom_d_i    : in  std_logic_vector( 7 downto 0);
	 
	 boot_rom_d_i	  : in  std_logic_vector( 7 downto 0);
    -- CPU RAM Interface ------------------------------------------------------
 --   cpu_ram_a_o     : out std_logic_vector( 10 downto 0);
	 cpu_ram_a_o     : out std_logic_vector( 13 downto 0);
    cpu_ram_ce_n_o  : out std_logic;
    cpu_ram_we_n_o  : out std_logic;
    cpu_ram_rd_n_o  : out std_logic;
	 cpu_ram_d_i     : in std_logic_vector( 7 downto 0);
    cpu_ram_d_o     : out std_logic_vector( 7 downto 0);
    -- Video RAM Interface ----------------------------------------------------
    vram_a_o        : out std_logic_vector(13 downto 0);
    vram_we_o       : out std_logic;
    vram_d_o        : out std_logic_vector( 7 downto 0);
    vram_d_i        : in  std_logic_vector( 7 downto 0);
    -- Cartridge ROM Interface ------------------------------------------------
    cart_a_o        : out std_logic_vector(14 downto 0);
    cart_en_80_n_o  : out std_logic;
    cart_en_a0_n_o  : out std_logic;
    cart_en_c0_n_o  : out std_logic;
    cart_en_e0_n_o  : out std_logic;
    cart_d_i        : in  std_logic_vector( 7 downto 0);
    -- RGB Video Interface ----------------------------------------------------
    col_o           : out std_logic_vector( 3 downto 0);
    rgb_r_o         : out std_logic_vector( 7 downto 0);
    rgb_g_o         : out std_logic_vector( 7 downto 0);
    rgb_b_o         : out std_logic_vector( 7 downto 0);
    hsync_n_o       : out std_logic;
    vsync_n_o       : out std_logic;
    comp_sync_n_o   : out std_logic;
	 blink_led : out std_logic;
--	 dev_sw		: in std_logic;
	 boot_o		: out std_logic;
	 cs_n			: out std_logic;
	 sclk			: out std_logic;
	 mosi			: out std_logic;
	 miso			: in std_logic;
	 rs232_rxd  : in std_logic;
	 rs232_txd  : out std_logic;
	 
    -- Audio Interface --------------------------------------------------------
    audio_o         : out signed(7 downto 0)
  );

end cv_console;


-- pragma translate_off
use std.textio.all;
-- pragma translate_on

use work.tech_comp_pack.cv_por;
use work.cv_comp_pack.cv_clock;
use work.cv_comp_pack.cv_ctrl;
use work.cv_comp_pack.cv_addr_dec;
use work.cv_comp_pack.cv_bus_mux;
use work.vdp18_core_comp_pack.vdp18_core;
use work.sn76489_comp_pack.sn76489_top;

architecture struct of cv_console is

  component T80a
    generic(
      Mode : integer := 0     -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
    );
    port(
      RESET_n    : in  std_logic;
      CLK_n      : in  std_logic;
      CLK_EN_SYS : in  std_logic;
      WAIT_n     : in  std_logic;
      INT_n      : in  std_logic;
      NMI_n      : in  std_logic;
      BUSRQ_n    : in  std_logic;
      M1_n       : out std_logic;
      MREQ_n     : out std_logic;
      IORQ_n     : out std_logic;
      RD_n       : out std_logic;
      WR_n       : out std_logic;
      RFSH_n     : out std_logic;
      HALT_n     : out std_logic;
      BUSAK_n    : out std_logic;
      A          : out std_logic_vector(15 downto 0);
      D_i        : in  std_logic_vector( 7 downto 0);
      D_o        : out std_logic_vector( 7 downto 0)
    );
  end component;

-- component T80se
--    generic(
--      Mode : integer := 0;     -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
--		T2Write : integer := 0;
--		IOWait : integer :=0
--		);
--    port(
--      RESET_n    : in  std_logic;
--      CLK_n      : in  std_logic;
--      CLKEN : in  std_logic;
--      WAIT_n     : in  std_logic;
--      INT_n      : in  std_logic;
--      NMI_n      : in  std_logic;
--      BUSRQ_n    : in  std_logic;
--      M1_n       : out std_logic;
--      MREQ_n     : out std_logic;
--      IORQ_n     : out std_logic;
--      RD_n       : out std_logic;
--      WR_n       : out std_logic;
--      RFSH_n     : out std_logic;
--      HALT_n     : out std_logic;
--      BUSAK_n    : out std_logic;
--      A          : out std_logic_vector(15 downto 0);
--      DI        : in  std_logic_vector( 7 downto 0);
--      DO       : out std_logic_vector( 7 downto 0)
--    );
--  end component;

  signal por_n_s          : std_logic;
  signal reset_n_s        : std_logic;

  signal clk_en_3m58_s    : std_logic;

  -- CPU signals
  signal clk_en_cpu_s     : std_logic;
  signal nmi_n_s          : std_logic;
  signal iorq_n_s         : std_logic;
  signal m1_n_s           : std_logic;
  signal m1_wait_q        : std_logic;
  signal rd_n_s,
         wr_n_s           : std_logic;
  signal mreq_n_s         : std_logic;
  signal rfsh_n_s         : std_logic;
  signal a_s              : std_logic_vector(15 downto 0);
  signal d_to_cpu_s,
         d_from_cpu_s     : std_logic_vector( 7 downto 0);

  -- VDP18 signal
  signal d_from_vdp_s     : std_logic_vector( 7 downto 0);

  -- SN76489 signal
  signal psg_ready_s      : std_logic;

  -- Controller signals
  signal d_from_ctrl_s    : std_logic_vector( 7 downto 0);

  -- Address decoder signals
  signal bios_rom_ce_n_s  : std_logic;
  signal ram_ce_n_s       : std_logic;
  signal vdp_r_n_s,
         vdp_w_n_s        : std_logic;
  signal psg_we_n_s       : std_logic;
  signal ctrl_r_n_s       : std_logic;
  signal ctrl_en_key_n_s,
         ctrl_en_joy_n_s  : std_logic;
  signal cart_en_80_n_s,
         cart_en_a0_n_s,
         cart_en_c0_n_s,
         cart_en_e0_n_s   : std_logic;

  -- misc signals
  signal vdd_s            : std_logic;


signal din_to_cpu_s     : std_logic_vector( 7 downto 0);
-- RS232
signal rx_data : std_logic_vector(7 downto 0);

signal uart_cs_n : 	std_logic;
signal iowr_n_s  : 	std_logic;
signal baudout : std_logic;  
signal dsr_n_s : 	std_logic;
signal dcd_n_s  : 	std_logic;
signal ri_n_s : std_logic; 
signal cts_n_s : std_logic; 
signal rts_n_s : std_logic;
signal dtr_n_s : std_logic;
signal iord_n_s  : 	std_logic;
--signal dev_sw_cs_n  : 	std_logic;
signal spi_dout : std_logic_vector(7 downto 0);
signal spi_cs		: std_logic;
signal ss_n : std_logic_vector(1 downto 0);

signal boot_s		: std_logic;
	
begin
  boot_o <= boot_s;
  vdd_s <= '1';

  -----------------------------------------------------------------------------
  -- Reset generation
  -----------------------------------------------------------------------------
  por_b : cv_por
    port map (
      clk_i   => clk_i,
      por_n_o => por_n_s
    );
  por_n_o   <= por_n_s;
  reset_n_s <= por_n_s and reset_n_i;


  -----------------------------------------------------------------------------
  -- Clock generation
  -----------------------------------------------------------------------------
  clock_b : cv_clock
    port map (
      clk_i         => clk_i,
      clk_en_10m7_i => clk_en_10m7_i,
      reset_n_i     => reset_n_s,
      clk_en_3m58_o => clk_en_3m58_s
    );


--  process (clk7m)
--	begin
--		if clk7m'event and clk7m = '1' then
--		clk_en_3m58_s <= not clk_en_3m58_s;  
--		end if;
--	end process;
	
  clk_en_cpu_s  <= clk_en_3m58_s and psg_ready_s and not m1_wait_q;
   
  clk_cpu <=  clk_en_3m58_s;


  -----------------------------------------------------------------------------
  -- T80 CPU
  -----------------------------------------------------------------------------
  t80a_b : T80a
    generic map (
      Mode       => 0
    )
    port map(
      RESET_n    => reset_n_s,
      CLK_n      => clk_i,
      CLK_EN_SYS => clk_en_cpu_s,
      WAIT_n     => vdd_s,
      INT_n      => vdd_s,
      NMI_n      => nmi_n_s,
      BUSRQ_n    => vdd_s,
      M1_n       => m1_n_s,
      MREQ_n     => mreq_n_s,
      IORQ_n     => iorq_n_s,
      RD_n       => rd_n_s,
      WR_n       => wr_n_s,
      RFSH_n     => rfsh_n_s,
      HALT_n     => open,
      BUSAK_n    => open,
      A          => a_s,
      D_i        => d_to_cpu_s,
      D_o        => d_from_cpu_s
    );

--t80a_b : T80se
--    generic map (
--      Mode       => 0,
--		T2Write    => 1,
--		IOWait => 1
--    )
--    port map(
--      RESET_n    => reset_n_s,
--      CLK_n      => clk_i,
--      CLKEN      => clk_en_cpu_s,
--      WAIT_n     => vdd_s,
--      INT_n      => vdd_s,
--      NMI_n      => nmi_n_s,
--      BUSRQ_n    => vdd_s,
--      M1_n       => m1_n_s,
--      MREQ_n     => mreq_n_s,
--      IORQ_n     => iorq_n_s,
--      RD_n       => rd_n_s,
--      WR_n       => wr_n_s,
--      RFSH_n     => rfsh_n_s,
--      HALT_n     => open,
--      BUSAK_n    => open,
--      A          => a_s,
--      DI        => d_to_cpu_s,
--      DO        => d_from_cpu_s
--    );
  -----------------------------------------------------------------------------
  -- Process m1_wait
  --
  -- Purpose:
  --   Implements flip-flop U8A which asserts a wait states controlled by M1.
  --
  m1_wait: process (clk_i, reset_n_s, m1_n_s)
  begin
    if reset_n_s = '0' or m1_n_s = '1' then
      m1_wait_q   <= '0';
    elsif clk_i'event and clk_i = '1' then
      if clk_en_3m58_s = '1' then
        m1_wait_q <= not m1_wait_q;
      end if;
    end if;
  end process m1_wait;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- TMS9928A Video Display Processor
  -----------------------------------------------------------------------------
  vdp18_b : vdp18_core
    generic map (
      is_pal_g      => is_pal_g,
      compat_rgb_g  => compat_rgb_g
    )
    port map (
      clk_i         => clk_i,
      clk_en_10m7_i => clk_en_10m7_i,
      reset_n_i     => reset_n_s,
      csr_n_i       => vdp_r_n_s,
      csw_n_i       => vdp_w_n_s,
      mode_i        => a_s(0),
      int_n_o       => nmi_n_s,
      cd_i          => d_from_cpu_s,
      cd_o          => d_from_vdp_s,
      vram_we_o     => vram_we_o,
      vram_a_o      => vram_a_o,
      vram_d_o      => vram_d_o,
      vram_d_i      => vram_d_i,
      col_o         => col_o,
      rgb_r_o       => rgb_r_o,
      rgb_g_o       => rgb_g_o,
      rgb_b_o       => rgb_b_o,
      hsync_n_o     => hsync_n_o,
      vsync_n_o     => vsync_n_o,
      comp_sync_n_o => comp_sync_n_o
    );


  -----------------------------------------------------------------------------
  -- SN76489 Programmable Sound Generator
  -----------------------------------------------------------------------------
  psg_b : sn76489_top
    generic map (
      clock_div_16_g => 1
    )
    port map (
      clock_i    => clk_i,
      clock_en_i => clk_en_3m58_s,
      res_n_i    => reset_n_s,
      ce_n_i     => psg_we_n_s,
      we_n_i     => psg_we_n_s,
      ready_o    => psg_ready_s,
      d_i        => d_from_cpu_s,
      aout_o     => audio_o
    );


  -----------------------------------------------------------------------------
  -- Controller ports
  -----------------------------------------------------------------------------
  ctrl_b : cv_ctrl
    port map (
      clk_i           => clk_i,
      clk_en_3m58_i   => clk_en_3m58_s,
      reset_n_i       => reset_n_s,
      ctrl_en_key_n_i => ctrl_en_key_n_s,
      ctrl_en_joy_n_i => ctrl_en_joy_n_s,
      a1_i            => a_s(1),
      ctrl_p1_i       => ctrl_p1_i,
      ctrl_p2_i       => ctrl_p2_i,
      ctrl_p3_i       => ctrl_p3_i,
      ctrl_p4_i       => ctrl_p4_i,
      ctrl_p5_o       => ctrl_p5_o,
      ctrl_p6_i       => ctrl_p6_i,
      ctrl_p7_i       => ctrl_p7_i,
      ctrl_p8_o       => ctrl_p8_o,
      ctrl_p9_i       => ctrl_p9_i,
      d_o             => d_from_ctrl_s
    );


  -----------------------------------------------------------------------------
  -- Address decoder
  -----------------------------------------------------------------------------
  addr_dec_b : cv_addr_dec
    port map (
      a_i             => a_s,
      iorq_n_i        => iorq_n_s,
      rd_n_i          => rd_n_s,
      wr_n_i          => wr_n_s,
      mreq_n_i        => mreq_n_s,
      rfsh_n_i        => rfsh_n_s,
      bios_rom_ce_n_o => bios_rom_ce_n_s,
	
      ram_ce_n_o      => ram_ce_n_s,
      vdp_r_n_o       => vdp_r_n_s,
      vdp_w_n_o       => vdp_w_n_s,
      psg_we_n_o      => psg_we_n_s,
      ctrl_r_n_o      => ctrl_r_n_s,
      ctrl_en_key_n_o => ctrl_en_key_n_s,
      ctrl_en_joy_n_o => ctrl_en_joy_n_s,
      cart_en_80_n_o  => cart_en_80_n_s,
      cart_en_a0_n_o  => cart_en_a0_n_s,
      cart_en_c0_n_o  => cart_en_c0_n_s,
      cart_en_e0_n_o  => cart_en_e0_n_s
    );

  bios_rom_ce_n_o <= bios_rom_ce_n_s;
  
  cpu_ram_ce_n_o  <= ram_ce_n_s;
  cpu_ram_we_n_o  <= wr_n_s;
  cpu_ram_rd_n_o  <= rd_n_s;
  cart_en_80_n_o  <= cart_en_80_n_s;
  cart_en_a0_n_o  <= cart_en_a0_n_s;
  cart_en_c0_n_o  <= cart_en_c0_n_s;
  cart_en_e0_n_o  <= cart_en_e0_n_s;


  -----------------------------------------------------------------------------
  -- Bus multiplexer
  -----------------------------------------------------------------------------
  bus_mux_b : cv_bus_mux
    port map (
      bios_rom_ce_n_i => bios_rom_ce_n_s,
		boot_i 			 => boot_s, 
      ram_ce_n_i      => ram_ce_n_s,
      vdp_r_n_i       => vdp_r_n_s,
      ctrl_r_n_i      => ctrl_r_n_s,
      cart_en_80_n_i  => cart_en_80_n_s,
      cart_en_a0_n_i  => cart_en_a0_n_s,
      cart_en_c0_n_i  => cart_en_c0_n_s,
      cart_en_e0_n_i  => cart_en_e0_n_s,
      bios_rom_d_i    => bios_rom_d_i,
		boot_rom_d_i    => boot_rom_d_i,
      cpu_ram_d_i     => cpu_ram_d_i,
      vdp_d_i         => d_from_vdp_s,
      ctrl_d_i        => d_from_ctrl_s,
      cart_d_i        => cart_d_i,
      d_o             => din_to_cpu_s --d_to_cpu_s
    );


  -----------------------------------------------------------------------------
  -- Misc outputs
  -----------------------------------------------------------------------------
  bios_rom_a_o <= a_s(12 downto 0);
  cpu_ram_a_o  <= a_s( 13 downto 0); --a_s( 10 downto 0);
  cpu_ram_d_o  <= d_from_cpu_s;
  cart_a_o     <= a_s(14 downto 0);


-------------------------------------------------------
-- rs232
-------------------------------------------------------
serial_port : entity work.T16450
			port map(
				MR_n => reset_n_s,
				XIn => clk_i,
				RClk => baudout,
				CS_n => uart_cs_n,
				Rd_n => rd_n_s, 
				Wr_n => iowr_n_s,
				A => a_s(2 downto 0),
				D_In => d_from_cpu_s,
				D_Out => rx_data,
				SIn => rs232_rxd,
				CTS_n => cts_n_s,
				DSR_n => dsr_n_s,
				RI_n => ri_n_s,
				DCD_n => dcd_n_s,
				SOut => rs232_txd,
				RTS_n => rts_n_s,
				DTR_n => dtr_n_s,
				OUT1_n => boot_s,
				OUT2_n => open,
				BaudOut => baudout,
				Intr => open);


	u5 :  entity work.spi 
		port map
		(
			reset       => not reset_n_s,
			sysclk      => clk_en_10m7_i, --clk_i,
			cpu_wr      => not iowr_n_s,
			cpu_rd      => not rd_n_s,
			cpu_cs      => spi_cs,
			cpu_addr    => a_s(2 downto 0),
			data_in     => d_from_cpu_s,
			data_out    => spi_dout,
			buf_full    => open, --SPI_full,
			buf_emty    => open, --SPI_empty,
			spi_o       => MOSI,
			spi_i       => MISO,
			sck_out     => SCLK,
			ss_n        => ss_n
		);
		
  cs_n <= ss_n(0);
  blink_led <= not SS_n(0);
--  LED(6 downto 4) <= "111";
--  LED(7) <= not SPI_full;  
	 
	 
d_to_cpu_s <= rx_data when uart_cs_n='0' else
				  spi_dout when spi_cs ='1' else	
				 -- "0000000" & dev_sw   when dev_sw_cs_n='0' else
				  din_to_cpu_s;

iowr_n_s  <=  iorq_n_s or wr_n_s ;
iord_n_s  <=  iorq_n_s or rd_n_s;

--iowr_n <= '0' when iorq_n_s='0' and rd_n_s='0' else
--          '1' when iorq_n_s='0' and wr_n_s='0' else
--			 'Z';
			 
uart_cs_n <= '0' when iorq_n_s = '0' and a_s(7 downto 3) = "00100" else '1';
--blink_led <= d_from_cpu_s(0) when iowr_n_s='0' AND a_s(7 downto 3)="01010" ;
--dev_sw_cs_n <= '0' when iord_n_s = '0' and a_s(7 downto 3) = "01010" else '1';
spi_cs <='1' when (iorq_n_s='0' and  a_s(7 downto 3)="01010" ) else '0';

--ram0_n_s <= ram0_ce_n_s or (not out1_n_s);

			  
end struct;
