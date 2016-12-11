library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity disp_shift is
   port(
      clk, reset: in std_logic;
      inp: in std_logic_vector(7 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end disp_shift ;

architecture arch of disp_shift is
   -- refreshing rate around 800 Hz (50MHz/2^16)
   constant N: integer:=18;
   signal q_reg, q_next: unsigned(N-1 downto 0);
   signal sel: std_logic_vector(1 downto 0);
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
   -- and to generate active-low enable signal
   sel <= std_logic_vector(q_reg(N-1 downto N-2));
   process(sel,inp)
   begin
      case sel is
         when "00" =>
            an <= "1110";
            sseg <= not ("000" & inp(0) & '0' & inp(1) & "00");
         when "01" =>
            an <= "1101";
            sseg <= not ("000" & inp(2) & '0' & inp(3) & "00");
         when "10" =>
            an <= "1011";
            sseg <= not ("000" & inp(4) & '0' & inp(5) & "00");
         when others =>
            an <= "0111";
            sseg <= not ("000" & inp(6) & '0' & inp(7) & "00");
      end case;
   end process;
end arch;
