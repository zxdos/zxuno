-------------------------------------------------------------------------------
--
-- $Id: cv_comp_pack-p.vhd,v 1.5 2006/01/05 22:22:29 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package cv_comp_pack is

  component cv_clock
    port (
      clk_i         : in  std_logic;
      clk_en_10m7_i : in  std_logic;
      reset_n_i     : in  std_logic;
      clk_en_3m58_o : out std_logic
    );
  end component;

  component cv_ctrl
    port (
      clk_i           : in  std_logic;
      clk_en_3m58_i   : in  std_logic;
      reset_n_i       : in  std_logic;
      ctrl_en_key_n_i : in  std_logic;
      ctrl_en_joy_n_i : in  std_logic;
      a1_i            : in  std_logic;
      ctrl_p1_i       : in  std_logic_vector(2 downto 1);
      ctrl_p2_i       : in  std_logic_vector(2 downto 1);
      ctrl_p3_i       : in  std_logic_vector(2 downto 1);
      ctrl_p4_i       : in  std_logic_vector(2 downto 1);
      ctrl_p5_o       : out std_logic_vector(2 downto 1);
      ctrl_p6_i       : in  std_logic_vector(2 downto 1);
      ctrl_p7_i       : in  std_logic_vector(2 downto 1);
      ctrl_p8_o       : out std_logic_vector(2 downto 1);
      ctrl_p9_i       : in  std_logic_vector(2 downto 1);
      d_o             : out std_logic_vector(7 downto 0)
    );
  end component;

  component cv_addr_dec
    port (
      a_i             : in  std_logic_vector(15 downto 0);
      iorq_n_i        : in  std_logic;
      rd_n_i          : in  std_logic;
      wr_n_i          : in  std_logic;
      mreq_n_i        : in  std_logic;
      rfsh_n_i        : in  std_logic;
      bios_rom_ce_n_o : out std_logic;
		
      ram_ce_n_o      : out std_logic;
      vdp_r_n_o       : out std_logic;
      vdp_w_n_o       : out std_logic;
      psg_we_n_o      : out std_logic;
      ctrl_r_n_o      : out std_logic;
      ctrl_en_key_n_o : out std_logic;
      ctrl_en_joy_n_o : out std_logic;
      cart_en_80_n_o  : out std_logic;
      cart_en_a0_n_o  : out std_logic;
      cart_en_c0_n_o  : out std_logic;
      cart_en_e0_n_o  : out std_logic
    );
  end component;

  component cv_bus_mux
    port (
      bios_rom_ce_n_i : in  std_logic;
		boot_i 			 : in  std_logic;
		
      ram_ce_n_i      : in  std_logic;
      vdp_r_n_i       : in  std_logic;
      ctrl_r_n_i      : in  std_logic;
      cart_en_80_n_i  : in  std_logic;
      cart_en_a0_n_i  : in  std_logic;
      cart_en_c0_n_i  : in  std_logic;
      cart_en_e0_n_i  : in  std_logic;
      bios_rom_d_i    : in  std_logic_vector(7 downto 0);
		boot_rom_d_i    : in  std_logic_vector(7 downto 0);
      cpu_ram_d_i     : in  std_logic_vector(7 downto 0);
      vdp_d_i         : in  std_logic_vector(7 downto 0);
      ctrl_d_i        : in  std_logic_vector(7 downto 0);
      cart_d_i        : in  std_logic_vector(7 downto 0);
      d_o             : out std_logic_vector(7 downto 0)
    );
  end component;

end cv_comp_pack;
