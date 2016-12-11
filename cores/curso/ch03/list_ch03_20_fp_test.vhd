-- Listing 3.20
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity fp_adder_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end fp_adder_test;

architecture arch of fp_adder_test is
   signal btn: std_logic_vector(3 downto 0);
   signal sign1, sign2: std_logic;
   signal exp1, exp2: std_logic_vector(3 downto 0);
   signal frac1, frac2: std_logic_vector(7 downto 0);
   signal sign_out: std_logic;
   signal exp_out: std_logic_vector(3 downto 0);
   signal frac_out: std_logic_vector(7 downto 0);
   signal led3, led2, led1, led0:
             std_logic_vector(6 downto 0);
begin

   btn <= not bot(3 downto 0);
   led <= not bot;

   -- set up the fp adder input signals
   sign1 <= '0';
   exp1 <= "1000";
   frac1<= '1' &  sw(1) & sw(0) & "10101";
   sign2 <= sw(7);
   exp2 <= btn;
   frac2 <= '1' & sw(6 downto 0);

   -- instantiate fp adder
   fp_add_unit: entity work.fp_adder
      port map(
         sign1=>sign1, sign2=>sign2, exp1=>exp1, exp2=>exp2,
         frac1=>frac1, frac2=>frac2,
         sign_out=>sign_out, exp_out=>exp_out,
         frac_out=>frac_out
      );

   -- instantiate three instances of hex decoders
   -- exponent
   sseg_unit_0: entity work.hex_to_sseg
      port map(hex=>exp_out, sseg=>led0);
   -- 4 LSBs of fraction
   sseg_unit_1: entity work.hex_to_sseg
      port map(hex=>frac_out(3 downto 0), sseg=>led1);
   -- 4 MSBs of fraction
   sseg_unit_2: entity work.hex_to_sseg
      port map(hex=>frac_out(7 downto 4), sseg=>led2);
   -- sign
   led3 <= "1111110" when sign_out='1' else -- middle bar
           "1111111";                       -- blank

   -- instantiate 7-seg LED display time-multiplexing module
   disp_unit: entity work.disp_mux
      port map(
         clk=>clk, reset=>'0',
         in0=>led0, in1=>led1, in2=>led2, in3=>led3,
         point=>'0', colon=>'1',
         an=>an, sseg=>sseg
      );
end arch;
