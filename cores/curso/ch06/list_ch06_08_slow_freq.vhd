-- Listing 6.8
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity low_freq_counter is
    port(
        clk, reset: in std_logic;
        start: in std_logic;
        si: in std_logic;
        bcd3, bcd2, bcd1, bcd0: out std_logic_vector(3 downto 0)
    );
end low_freq_counter;

architecture arch of low_freq_counter is
   type state_type is (idle, count, frq, b2b);
   signal state_reg, state_next: state_type;
   signal prd: std_logic_vector(9 downto 0);
   signal dvsr, dvnd, quo: std_logic_vector(19 downto 0);
   signal prd_start, div_start, b2b_start: std_logic;
   signal prd_done_tick, div_done_tick, b2b_done_tick: std_logic;
begin
   --===============================================
   -- component instantiation
   --===============================================
   -- instantiate period counter
   prd_count_unit: entity work.period_counter
   port map(clk=>clk, reset=>reset, start=>prd_start, si=>si,
            ready=>open, done_tick=>prd_done_tick, prd=>prd);
   -- instantiate division circuit
   div_unit: entity work.div
   generic map(W=>20, CBIT=>5)
   port map(clk=>clk, reset=>reset, start=>div_start,
            dvsr=>dvsr, dvnd=>dvnd, quo=>quo, rmd=>open,
            ready=>open, done_tick=>div_done_tick);
   -- instantiate binary-to-BCD convertor
   bin2bcd_unit: entity work.bin2bcd
   port map
      (clk=>clk, reset=>reset, start=>b2b_start,
       bin=>quo(12 downto 0), ready=>open,
       done_tick=>b2b_done_tick,
       bcd3=>bcd3, bcd2=>bcd2, bcd1=>bcd1, bcd0=>bcd0);
   -- signal width extension
   dvnd <= std_logic_vector(to_unsigned(1000000, 20));
   dvsr <= "0000000000" & prd;

   --===============================================
   -- Master FSM
   --===============================================
   process(clk,reset)
   begin
      if reset='1' then
         state_reg <= idle;
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
   end process;

   process(state_reg,start,
           prd_done_tick,div_done_tick,b2b_done_tick)
   begin
      state_next <= state_reg;
      prd_start <='0';
      div_start <='0';
      b2b_start <='0';
      case state_reg is
         when idle =>
            if start='1' then
               state_next <= count;
               prd_start <='1';
            end if;
         when count =>
            if (prd_done_tick='1') then
               div_start <='1';
               state_next <= frq;
            end if;
         when frq =>
            if (div_done_tick='1') then
               b2b_start <='1';
               state_next <= b2b;
            end if;
         when b2b =>
            if (b2b_done_tick='1') then
               state_next <= idle;
            end if;
       end case;
   end process;
end arch;
