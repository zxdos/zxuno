-- multiplexes led t for X-SP6-X9
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity XSP6X9_Led_Multiplex is
port (
	clk  : in  std_logic;
	inputs : in  std_logic_vector(63 downto 0);
	segment   : out std_logic_vector( 7 downto 0);
	position   : out std_logic_vector( 7 downto 0)
);
end;

architecture Implementation of XSP6X9_Led_Multiplex is
	signal current :std_logic_vector(7 downto 0) := "00000000";
	signal prev :std_logic_vector(7 downto 0) := "00000000";
begin
  set: process(clk)
  begin
    if rising_edge(clk) then
      prev <= current;
      case prev(7 downto 4) is
        when "0000" =>  segment <= inputs(7  downto  0);
        when "0010" =>  segment <= inputs(15 downto  8);
        when "0100" =>  segment <= inputs(23 downto 16);
        when "0110" =>  segment <= inputs(31 downto 24);
        when "1000" =>  segment <= inputs(39 downto 32);
        when "1010" =>  segment <= inputs(47 downto 40);
        when "1100" =>  segment <= inputs(55 downto 48);
        when "1110" =>  segment <= inputs(63 downto 56);
        when others => segment <= "11111111";
      end case;
      case current(7 downto 4) is
        when "0000" =>  position <= "11111110";
        when "0010" =>  position <= "11111101";
        when "0100" =>  position <= "11111011";
        when "0110" =>  position <= "11110111";
        when "1000" =>  position <= "11101111";
        when "1010" =>  position <= "11011111";
        when "1100" =>  position <= "10111111";
        when "1110" =>  position <= "01111111";
        when others => position <= "11111111";
      end case;
      if (current(3 downto 0) = "1010") then
        current(3 downto 0) <= "0000";
        if (current(7 downto 4) = "1111") then
          current (7 downto 4) <= "0000";
        else
          current(7 downto 4) <= current(7 downto 4) + '1';
        end if;
      else
        current <= current + '1';
      end if;
    end if;
  end process;                
end architecture Implementation;
