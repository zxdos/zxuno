library ieee;
use ieee.std_logic_1164.all;

entity colenc is
  port (  clk_in  : in  std_logic;
          col_in  : in  std_logic_vector (3 downto 0);
          r_out   : out std_logic_vector (2 downto 0);
          g_out   : out std_logic_vector (2 downto 0);
          b_out   : out std_logic_vector (2 downto 0));
end colenc;

architecture behavioral of colenc is
begin
  process (clk_in)
  begin
    if rising_edge( clk_in ) then
      r_out<= "000" when col_in(1)='0' else
              "101" when col_in(3)='0' else
              "111";
      g_out<= "000" when col_in(2)='0' else
              "101" when col_in(3)='0' else
              "111";
      b_out<= "000" when col_in(0)='0' else
              "101" when col_in(3)='0' else
              "111";
    end if;
  end process;
end behavioral;
