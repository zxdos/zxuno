--Listing 3.2
library ieee;
use ieee.std_logic_1164.all;
entity decoder_2_4 is
   port(
      a: in std_logic_vector(1 downto 0);
      en: in std_logic;
      y: out std_logic_vector(3 downto 0)
   );
end decoder_2_4;

architecture cond_arch of decoder_2_4 is
begin
    y <= "0000" when (en='0') else
         "0001" when (a="00") else
         "0010" when (a="01") else
         "0100" when (a="10") else
         "1000";   -- a="11"
end cond_arch;


--Listing 3.4
architecture sel_arch of decoder_2_4 is
   signal s: std_logic_vector(2 downto 0);
begin
   s <= en & a;
   with s select
      y <= "0000" when "000"|"001"|"010"|"011",
           "0001" when "100",
           "0010" when "101",
           "0100" when "110",
           "1000" when others;   -- s="111"
end sel_arch;

--Listing 3.6
architecture if_arch of decoder_2_4 is begin
   process(en,a)
   begin
      if (en='0') then
         y <= "0000";
      elsif (a="00") then
         y <= "0001";
      elsif (a="01")then
         y <= "0010";
      elsif (a="10")then
         y <= "0100";
      else
         y <= "1000";
      end if;
   end process;
end if_arch;

--Listing 3.8
architecture case_arch of decoder_2_4 is
   signal s: std_logic_vector(2 downto 0);
begin
   s <= en & a;
   process(s)
   begin
      case s is
         when "000"|"001"|"010"|"011" =>
            y <= "0001";
         when "100" =>
            y <= "0001";
         when "101" =>
            y <= "0010";
         when "110" =>
            y <= "0100";
         when others =>
            y <= "1000";
      end case;
   end process;
end case_arch;