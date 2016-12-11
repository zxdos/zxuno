-- Listing 4.1
library ieee;
use ieee.std_logic_1164.all;
entity d_ff is
   port(
      clk: in std_logic;
      d: in std_logic;
      q: out std_logic
   );
end d_ff;

architecture arch of d_ff is
begin
   process(clk)
   begin
      if (clk'event and clk='1') then
         q <= d;
      end if;
   end process;
end arch;
