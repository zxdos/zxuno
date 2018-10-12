library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity dos8 is
  port (
    CLK: in std_logic;

    PHI_2: in std_logic;
    D_IN: in std_logic_vector(7 downto 0);
    D_OUT: out std_logic_vector(7 downto 0;
    IRQ
