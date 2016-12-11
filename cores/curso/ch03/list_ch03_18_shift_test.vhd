-- Listing 3.18
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity shifter_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end shifter_test;

architecture arch of shifter_test is
   signal miled: std_logic_vector(7 downto 0);
   signal btn : std_logic_vector(2 downto 0);
begin

   btn <= not (bot(4) & bot (2) & bot(0));
   led <= not bot;

   -- instantiate 7-seg LED display time-multiplexing module
   disp_unit: entity work.disp_shift
      port map(
         clk=>clk, reset=>'0',
         inp=>miled, an=>an, sseg=>sseg);

   shift_unit: entity work.barrel_shifter(multi_stage_arch)
      port map(a=>sw, amt=>btn, y=>miled);
end arch;
