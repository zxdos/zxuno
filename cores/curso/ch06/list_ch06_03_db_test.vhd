-- Listing 6.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity debounce_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end debounce_test;

architecture arch of debounce_test is
   signal btn: std_logic_vector(3 downto 0);
   signal q1_reg, q1_next: unsigned(7 downto 0);
   signal q0_reg, q0_next: unsigned(7 downto 0);
   signal b_count, d_count: std_logic_vector(7 downto 0);
   signal btn_reg: std_logic;
   signal db_tick, btn_tick, clr: std_logic;
-- Listing 7.3
begin

   btn <= not bot(3 downto 0);
   led <= not bot;
   -- instantiate debouncing circuit
   db_unit: entity work.debounce(fsmd_arch)
      port map(
         clk=>clk, reset=>'0', sw=>btn(1),
         db_level=> open, db_tick=>db_tick
      );
   -- instantiate hex display time-multiplxing circuit
   disp_unit: entity work.disp_hex_mux
      port map(
         clk=>clk, reset=>'0',
         hex3=>b_count(7 downto 4), hex2=>b_count(3 downto 0),
         hex1=>d_count(7 downto 4), hex0=>d_count(3 downto 0),
         point=>'1', colon=>'0',
         an=>an, sseg=>sseg
      );

   --=================================================
   -- edge detection circuit for un-debounced input
   --=================================================
   process(clk)
   begin
      if (clk'event and clk='1') then
         btn_reg <= btn(1);
      end if;
   end process;
   btn_tick <= (not btn_reg) and btn(1);

   --=================================================
   -- two counters
   --=================================================
   clr <= btn(0);
   process(clk)
   begin
      if (clk'event and clk='1') then
         q1_reg <= q1_next;
         q0_reg <= q0_next;
      end if;
   end process;
   -- next-state logic for the counter
   q1_next <= (others=>'0') when clr='1' else
              q1_reg + 1 when btn_tick='1' else
              q1_reg;
   q0_next <= (others=>'0') when clr='1' else
              q0_reg + 1 when db_tick='1' else
              q0_reg;
   -- counter output
   b_count <= std_logic_vector(q1_reg);
   d_count <= std_logic_vector(q0_reg);
end arch;
