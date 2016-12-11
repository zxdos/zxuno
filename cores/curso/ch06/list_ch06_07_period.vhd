-- Listing 6.7
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity period_counter is
   port(
      clk, reset: in std_logic;
      start, si: in std_logic;
      ready, done_tick: out std_logic;
      prd: out std_logic_vector(9 downto 0)
   );
end period_counter;

architecture arch of period_counter is
   constant CLK_MS_COUNT: integer := 5; -- 50000; -- 1 ms tick
   type state_type is (idle, waite, count, done);
   signal state_reg, state_next: state_type;
   signal t_reg, t_next: unsigned(15 downto 0); -- up to 50000
   signal p_reg, p_next: unsigned(9 downto 0); -- up to 1 sec
   signal delay_reg: std_logic;
   signal edge: std_logic;
begin
   -- state and data register
   process(clk,reset)
   begin
      if reset='1' then
         state_reg <= idle;
         t_reg <= (others=>'0');
         p_reg <= (others=>'0');
         delay_reg <= '0';
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         t_reg <= t_next;
         p_reg <= p_next;
         delay_reg <= si;
      end if;
   end process;

   edge <= (not delay_reg) and si;

   process(start,edge,state_reg,t_reg,t_next,p_reg)
   begin
      ready <= '0';
      done_tick <= '0';
      state_next <= state_reg;
      p_next <= p_reg;
      t_next <= t_reg;
      case state_reg is
         when idle =>
            ready <= '1';
            if (start='1') then
               state_next <= waite;
            end if;
         when waite => -- wait for the first edge
            if (edge='1') then
               state_next <= count;
               t_next <= (others=>'0');
               p_next <= (others=>'0');
            end if;
         when count =>
            if (edge='1') then   -- 2nd edge arrived
               state_next <= done;
            else -- otherwise count
               if t_reg = CLK_MS_COUNT-1 then -- 1ms tick
                  t_next <= (others=>'0');
                  p_next <= p_reg + 1;
               else
                  t_next <= t_reg + 1;
               end if;
            end if;
         when done =>
            done_tick <= '1';
            state_next <= idle;
      end case;
   end process;
   prd <= std_logic_vector(p_reg);
end arch;
