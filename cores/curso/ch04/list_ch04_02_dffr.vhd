-- Listing 4.2
library ieee;
use ieee.std_logic_1164.all;
entity d_ff_reset is
   port(
      clk, reset: in std_logic;
      d: in std_logic;
      q: out std_logic
   );
end d_ff_reset;

architecture arch of d_ff_reset is
begin
   process(clk,reset)
   begin
      if (reset='1') then
         q <='0';
      elsif (clk'event and clk='1') then
         q <= d;
      end if;
   end process;
end arch;
