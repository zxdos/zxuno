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
      if( col_in(3)='0' ) then
        g_out<= col_in(2) & '0' & col_in(2);
        r_out<= col_in(1) & '0' & col_in(1);
        b_out<= col_in(0) & '0' & col_in(0);
      else
        g_out<= col_in(2) & col_in(2) & col_in(2);
        r_out<= col_in(1) & col_in(1) & col_in(1);
        b_out<= col_in(0) & col_in(0) & col_in(0);
      end if;
    end if;
  end process;
end behavioral;
