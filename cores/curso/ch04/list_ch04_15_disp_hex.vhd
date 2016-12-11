-- Listing 4.15
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity disp_hex_mux is
   port(
      clk, reset: in std_logic;
      hex3, hex2, hex1, hex0: in std_logic_vector(3 downto 0);
      point: in std_logic;
      colon: in std_logic;
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end disp_hex_mux ;

architecture arch of disp_hex_mux is
   -- each 7-seg led enabled (2^18/4)*25 ns (40 ms)
   constant N: integer:=18;
   signal q_reg, q_next: unsigned(N-1 downto 0);
   signal sel: std_logic_vector(1 downto 0);
   signal hex: std_logic_vector(3 downto 0);
   signal dp: std_logic;
begin
   -- register
   process(clk,reset)
   begin
      if reset='1' then
         q_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         q_reg <= q_next;
      end if;
   end process;

   -- next-state logic for the counter
   q_next <= q_reg + 1;

   -- 2 MSBs of counter to control 4-to-1 multiplexing
   sel <= std_logic_vector(q_reg(N-1 downto N-2));
   process(sel,hex0,hex1,hex2,hex3,colon,point)
   begin
      case sel is
         when "00" =>
            an <= "1110";
            hex <= hex0;
            dp <= '1';
         when "01" =>
            an <= "1101";
            hex <= hex1;
            dp <= '1';
         when "10" =>
            an <= "1011";
            hex <= hex2;
            dp <= colon;
         when others =>
            an <= "0111";
            hex <= hex3;
            dp <= point;
      end case;
   end process;
   -- hex-to-7-segment led decoding
   with hex select
      sseg(6 downto 0) <=
         "0000001" when "0000",
         "1001111" when "0001",
         "0010010" when "0010",
         "0000110" when "0011",
         "1001100" when "0100",
         "0100100" when "0101",
         "0100000" when "0110",
         "0001111" when "0111",
         "0000000" when "1000",
         "0000100" when "1001",
         "0001000" when "1010", --a
         "1100000" when "1011", --b
         "0110001" when "1100", --c
         "1000010" when "1101", --d
         "0110000" when "1110", --e
         "0111000" when others; --f
   -- decimal point
   sseg(7) <= dp;
end arch;
