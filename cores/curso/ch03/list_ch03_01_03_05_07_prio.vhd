--Listing 3.1
library ieee;
use ieee.std_logic_1164.all;
entity prio_encoder is
   port(
      r: in std_logic_vector(4 downto 1);
      pcode: out std_logic_vector(2 downto 0)
   );
end prio_encoder;

architecture cond_arch of prio_encoder is
begin
   pcode <= "100" when (r(4)='1') else
            "011" when (r(3)='1') else
            "010" when (r(2)='1') else
            "001" when (r(1)='1') else
            "000";
end cond_arch;


--Listing 3.3
architecture sel_arch of prio_encoder is
begin
   with r select
      pcode <= "100" when "1000"|"1001"|"1010"|"1011"|
                          "1100"|"1101"|"1110"|"1111",
               "011" when "0100"|"0101"|"0110"|"0111",
               "010" when "0010"|"0011",
               "001" when "0001",
               "000" when others;   -- r="0000"
end sel_arch;

--Listing 3.5
architecture if_arch of prio_encoder is
begin
   process(r)
   begin
      if (r(4)='1') then
         pcode <= "100";
      elsif (r(3)='1')then
         pcode <= "011";
      elsif (r(2)='1')then
         pcode <= "010";
      elsif (r(1)='1')then
         pcode <= "001";
      else
         pcode <= "000";
      end if;
   end process;
end if_arch;

--Listing 3.7
architecture case_arch of prio_encoder is
begin
   process(r)
   begin
      case r is
         when "1000"|"1001"|"1010"|"1011"|
              "1100"|"1101"|"1110"|"1111" =>
            pcode <= "100";
         when "0100"|"0101"|"0110"|"0111" =>
            pcode <= "011";
         when "0010"|"0011" =>
            pcode <= "010";
         when "0001" =>
            pcode <= "001";
         when others =>
            pcode <= "000";
      end case;
   end process;
end case_arch;