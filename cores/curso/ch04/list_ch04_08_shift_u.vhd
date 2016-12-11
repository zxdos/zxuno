-- Listing 4.8
library ieee;
use ieee.std_logic_1164.all;
entity univ_shift_reg is
   generic(N: integer := 8);
   port(
      clk, reset: in std_logic;
      ctrl: in std_logic_vector(1 downto 0);
      d: in std_logic_vector(N-1 downto 0);
      q: out std_logic_vector(N-1 downto 0)
   );
end univ_shift_reg;

architecture arch of univ_shift_reg is
   signal r_reg: std_logic_vector(N-1 downto 0);
   signal r_next: std_logic_vector(N-1 downto 0);
begin
   -- register
   process(clk,reset)
   begin
      if (reset='1') then
         r_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         r_reg <= r_next;
      end if;
   end process;
   -- next-state logic
   with ctrl select
    r_next <=
      r_reg                        when "00", --no op
      r_reg(N-2 downto 0) & d(0)   when "01", --shift left;
      d(N-1) & r_reg(N-1 downto 1) when "10", --shift right;
      d                            when others; -- load
   -- output
   q <= r_reg;
end arch;
