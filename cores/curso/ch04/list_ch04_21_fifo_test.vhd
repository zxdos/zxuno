-- Listing 4.21
library ieee;
use ieee.std_logic_1164.all;
entity fifo_test is
   port(
      clk: in std_logic;
      bot: in std_logic_vector(4 downto 0);
      sw: in std_logic_vector(7 downto 0);
      led: out std_logic_vector(4 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end fifo_test;

architecture arch of fifo_test is
   signal btn, db_btn: std_logic_vector(2 downto 0);
begin

   sseg <= "11111111";
   an <= "1111";
   btn <= not bot(2 downto 0);

   -- debounce circuit for btn(0)
   btn_db_unit0: entity work.debounce(fsmd_arch)
      port map(clk=>clk, reset=>btn(2), sw=>btn(0), db=>db_btn(0));
   -- debounce circuit for btn(1)
   btn_db_unit1: entity work.debounce(fsmd_arch)
      port map(clk=>clk, reset=>btn(2), sw=>btn(1), db=>db_btn(1));
   -- instantiate a 2^2-by-3 fifo)
   fifo_unit: entity work.fifo(arch)
      generic map(B=>3, W=>2)
      port map(clk=>clk, reset=>btn(2),
               rd=>db_btn(0), wr=>db_btn(1),
               w_data=>sw(2 downto 0), r_data=>led(2 downto 0),
               full=>led(4), empty=>led(3));
end arch;
