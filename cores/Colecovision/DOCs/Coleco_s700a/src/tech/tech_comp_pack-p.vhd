-------------------------------------------------------------------------------
--
-- $Id: tech_comp_pack-p.vhd,v 1.3 2006/02/20 00:27:13 arnim Exp $
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package tech_comp_pack is

  component cv_por
    port (
      clk_i   : in  std_logic;
      por_n_o : out std_logic
    );
  end component;

  component generic_ram
    generic (
      addr_width_g : integer := 10;
      data_width_g : integer := 8
    );
    port (
      clk_i : in  std_logic;
      a_i   : in  std_logic_vector(addr_width_g-1 downto 0);
      we_i  : in  std_logic;
      d_i   : in  std_logic_vector(data_width_g-1 downto 0);
      d_o   : out std_logic_vector(data_width_g-1 downto 0)
    );
  end component;

end tech_comp_pack;
