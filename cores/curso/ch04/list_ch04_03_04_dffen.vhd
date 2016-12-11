-- Listing 4.3
library ieee;
use ieee.std_logic_1164.all;
entity d_ff_en is
   port(
      clk, reset: in std_logic;
      en: in std_logic;
      d: in std_logic;
      q: out std_logic
   );
end d_ff_en;

architecture arch of d_ff_en is
begin
   process(clk,reset)
   begin
      if (reset='1') then
         q <='0';
      elsif (clk'event and clk='1') then
         if (en='1') then
            q <= d;
         end if;
      end if;
   end process;
end arch;

-- Listing 4.4
architecture two_seg_arch of d_ff_en is
   signal r_reg, r_next: std_logic;
begin
   -- D FF
   process(clk,reset)
   begin
      if (reset='1') then
         r_reg <='0';
      elsif (clk'event and clk='1') then
         r_reg <= r_next;
      end if;
   end process;
   -- next-state logic
   r_next <= d when en ='1' else
             r_reg;
   -- output logic
   q <= r_reg;
end two_seg_arch;
