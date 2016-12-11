-- Listing 4.12
library ieee;
use ieee.std_logic_1164.all;

entity bin_counter_tb is
end bin_counter_tb;

architecture arch of bin_counter_tb is
   constant THREE: integer := 3;
   constant T: time := 20 ns; -- clk period
   signal clk, reset: std_logic;
   signal syn_clr, load, en, up: std_logic;
   signal d: std_logic_vector(THREE-1 downto 0);
   signal max_tick, min_tick: std_logic;
   signal q: std_logic_vector(THREE-1 downto 0);
begin
   --**************************
   -- instantiation
   --**************************
   counter_unit: entity work.univ_bin_counter(arch)
      generic map(N=>THREE)
      port map(clk=>clk, reset=>reset, syn_clr=>syn_clr,
               load=>load, en=>en, up=>up, d=>d,
               max_tick=>max_tick, min_tick=>min_tick, q=>q);

   --**************************
   -- clock
   --**************************
   -- 20 ns clock running forever
   process
   begin
      clk <= '0';
      wait for T/2;
      clk <= '1';
      wait for T/2;
   end process;
   --**************************
   -- reset
   --**************************
   -- reset asserted for T/2
   reset <= '1', '0' after T/2;

   --**************************
   -- other stimulus
   --**************************
   process
   begin
      --**************************
      -- initial input
      --**************************
      syn_clr <= '0';
      load <= '0';
      en <= '0';
      up <= '1';  -- count up
      d <= (others=>'0');
      wait until falling_edge(clk);
      wait until falling_edge(clk);
      --**************************
      -- test load
      --**************************
      load <= '1';
      d <= "011";
      wait until falling_edge(clk);
      load <= '0';
      -- pause 2 clocks
      wait until falling_edge(clk);
      wait until falling_edge(clk);
      --**************************
      -- test syn_clear
      --**************************
      syn_clr <= '1';  -- clear
      wait until falling_edge(clk);
      syn_clr <= '0';
      --**************************
      -- test up counter and pause
      --**************************
      en <= '1'; -- count
      up <= '1';
      for i in 1 to 10 loop -- count 10 clocks
         wait until falling_edge(clk);
      end loop;
      en <='0';
      wait until falling_edge(clk);
      wait until falling_edge(clk);
      en <='1';
      wait until falling_edge(clk);
      wait until falling_edge(clk);
      --**************************
      -- test down counter
      --**************************
      up <= '0';
      for i in 1 to 10 loop -- run 10 clocks
         wait until falling_edge(clk);
      end loop;
      --**************************
      -- other wait conditions
      --**************************
      -- continue until q=2
      wait until q="010";
      wait until falling_edge(clk);
      up <= '1';
      -- continue until min_tick changes value
      wait on min_tick;
      wait until falling_edge(clk);
      up <= '0';
      wait for 4*T;  -- wait for 80 ns
      en <= '0';
      wait for 4*T;
      --**************************
      -- terminate simulation
      --**************************
      assert false
         report "Simulation Completed"
       severity failure;
   end process ;
end arch;
