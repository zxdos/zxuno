-- Listing 4.14
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity disp_mux_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end disp_mux_test;

architecture arch of disp_mux_test is
   signal d3_reg, d2_reg: std_logic_vector(6 downto 0);
   signal d1_reg, d0_reg: std_logic_vector(6 downto 0);
   signal btn : std_logic_vector(3 downto 0);
begin

   btn <= not bot(3 downto 0);
   led <= not bot;

   disp_unit: entity work.disp_mux
      port map(
         clk=>clk, reset=>'0',
         in3=>d3_reg, in2=>d2_reg, in1=>d1_reg, in0=>d0_reg,
         point=>'1', colon=>'1',
         an=>an, sseg=>sseg);
   -- registers for 4 led patterns
   process (clk)
   begin
      if (clk'event and clk='1') then
         if (btn(3)='1') then
            d3_reg <= sw(6 downto 0);
         end if;
         if (btn(2)='1') then
            d2_reg <= sw(6 downto 0);
         end if;
         if (btn(1)='1') then
            d1_reg <= sw(6 downto 0);
         end if;
         if (btn(0)='1') then
            d0_reg <= sw(6 downto 0);
         end if;
      end if;
   end process;
end arch;
