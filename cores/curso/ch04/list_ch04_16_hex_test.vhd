-- Listing 4.16
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hex_mux_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end hex_mux_test;

architecture arch of hex_mux_test is
   signal a, b: unsigned(7 downto 0);
   signal sum: std_logic_vector(7 downto 0);
begin

   led <= not bot;

   disp_unit: entity work.disp_hex_mux
      port map(
         clk=>clk, reset=>'0',
         hex3=>sum(7 downto 4), hex2=>sum(3 downto 0),
         hex1=>sw(7 downto 4), hex0=>sw(3 downto 0),
         point=>'1', colon=>'0',
         an=>an, sseg=>sseg);
   a <= "0000" & unsigned(sw(3 downto 0));
   b <= "0000" & unsigned(sw(7 downto 4));
   sum <= std_logic_vector(a + b);
end arch;
