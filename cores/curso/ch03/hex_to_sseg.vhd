-- Listing 3.12
library ieee;
use ieee.std_logic_1164.all;
entity hex_to_sseg is
   port(
      hex: in std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(6 downto 0)
   );
end hex_to_sseg;

architecture arch of hex_to_sseg is
begin
   with hex select
      sseg <=
         "0000001" when "0000",
         "1001111" when "0001",
         "0010010" when "0010",
         "0000110" when "0011",
         "1001100" when "0100",
         "0100100" when "0101",
         "0100000" when "0110",
         "0001111" when "0111",
         "0000000" when "1000",
         "0000100" when "1001",
         "0001000" when "1010", --a
         "1100000" when "1011", --b
         "0110001" when "1100", --c
         "1000010" when "1101", --d
         "0110000" when "1110", --e
         "0111000" when others; --f
end arch;
