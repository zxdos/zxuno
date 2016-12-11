-- Listing 3.13
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hex_to_sseg_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end hex_to_sseg_test;

architecture arch of hex_to_sseg_test is
   signal inc: std_logic_vector(7 downto 0);
   signal led3, led2, led1, led0: std_logic_vector(6 downto 0);
begin

   led <= not bot;

   -- increment input
   inc <= std_logic_vector(unsigned(sw) + 1);

   -- instantiate four instances of hex decoders
   -- instance for 4 LSBs of input
   sseg_unit_0: entity work.hex_to_sseg
      port map(hex=>sw(3 downto 0), sseg=>led0);
   -- instance for 4 MSBs of input
   sseg_unit_1: entity work.hex_to_sseg
      port map(hex=>sw(7 downto 4), sseg=>led1);
   -- instance for 4 LSBs of incremented value
   sseg_unit_2: entity work.hex_to_sseg
      port map(hex=>inc(3 downto 0), sseg=>led2);
   -- instance for 4 MSBs of incremented value
   sseg_unit_3: entity work.hex_to_sseg
      port map(hex=>inc(7 downto 4), sseg=>led3);

   -- instantiate 7-seg LED display time-multiplexing module
   disp_unit: entity work.disp_mux
      port map(
         clk=>clk, reset=>'0',
         in0=>led0, in1=>led1, in2=>led2, in3=>led3,
         point=>'1', colon=>'0',
         an=>an, sseg=>sseg);
end arch;
