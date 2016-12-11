-- Listing 6.6
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity bin2bcd is
   port(
      clk: in std_logic;
      reset: in std_logic;
      start: in std_logic;
      bin: in std_logic_vector(12 downto 0);
      ready, done_tick: out std_logic;
      bcd3,bcd2,bcd1,bcd0: out std_logic_vector(3 downto 0)
   );
end bin2bcd ;

architecture arch of bin2bcd is
   type state_type is (idle, op, done);
   signal state_reg, state_next: state_type;
   signal p2s_reg, p2s_next: std_logic_vector(12 downto 0);
   signal n_reg, n_next: unsigned(3 downto 0);
   signal bcd3_reg,bcd2_reg,bcd1_reg,bcd0_reg: unsigned(3 downto 0);
   signal bcd3_next,bcd2_next,bcd1_next,bcd0_next: unsigned(3 downto 0);
   signal bcd3_tmp,bcd2_tmp,bcd1_tmp,bcd0_tmp: unsigned(3 downto 0);
begin
   -- state and data registers
   process (clk,reset)
   begin
      if reset='1' then
         state_reg <= idle;
         p2s_reg <= (others=>'0');
         n_reg <= (others=>'0');
         bcd3_reg <= (others=>'0');
         bcd2_reg <= (others=>'0');
         bcd1_reg <= (others=>'0');
         bcd0_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         p2s_reg <= p2s_next;
         n_reg <= n_next;
         bcd3_reg <= bcd3_next;
         bcd2_reg <= bcd2_next;
         bcd1_reg <= bcd1_next;
         bcd0_reg <= bcd0_next;
      end if;
   end process;

   -- fsmd next-state logic / data path operations
   process(state_reg,start,p2s_reg,n_reg,n_next,bin,
           bcd0_reg,bcd1_reg,bcd2_reg,bcd3_reg,
           bcd0_tmp,bcd1_tmp,bcd2_tmp,bcd3_tmp)
   begin
      state_next <= state_reg;
      ready <= '0';
      done_tick <= '0';
      p2s_next <= p2s_reg;
      bcd0_next <= bcd0_reg;
      bcd1_next <= bcd1_reg;
      bcd2_next <= bcd2_reg;
      bcd3_next <= bcd3_reg;
      n_next <= n_reg;
      case state_reg is
         when idle =>
            ready <= '1';
            if start='1' then
               state_next <= op;
               bcd3_next <= (others=>'0');
               bcd2_next <= (others=>'0');
               bcd1_next <= (others=>'0');
               bcd0_next <= (others=>'0');
               n_next <="1101";  -- index
               p2s_next <= bin;  -- input shift register
               state_next <= op;
            end if;
         when op =>
            -- shift in binary bit
            p2s_next <= p2s_reg(11 downto 0) & '0';
            -- shift 4 BCD digits
            bcd0_next <= bcd0_tmp(2 downto 0) & p2s_reg(12);
            bcd1_next <= bcd1_tmp(2 downto 0) & bcd0_tmp(3);
            bcd2_next <= bcd2_tmp(2 downto 0) & bcd1_tmp(3);
            bcd3_next <= bcd3_tmp(2 downto 0) & bcd2_tmp(3);
            n_next <= n_reg - 1;
            if (n_next=0) then
                state_next <= done;
            end if;
         when done =>
            state_next <= idle;
            done_tick <= '1';
     end case;
   end process;

   -- data path function units
   bcd0_tmp <= bcd0_reg + 3 when bcd0_reg > 4 else
               bcd0_reg;
   bcd1_tmp <= bcd1_reg + 3 when bcd1_reg > 4 else
               bcd1_reg;
   bcd2_tmp <= bcd2_reg + 3 when bcd2_reg > 4 else
               bcd2_reg;
   bcd3_tmp <= bcd3_reg + 3 when bcd3_reg > 4 else
               bcd3_reg;

   -- output
   bcd0 <= std_logic_vector(bcd0_reg);
   bcd1 <= std_logic_vector(bcd1_reg);
   bcd2 <= std_logic_vector(bcd2_reg);
   bcd3 <= std_logic_vector(bcd3_reg);
end arch;
