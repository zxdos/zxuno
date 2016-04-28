--**********************************************************************************************
-- Frequency divider for AVR uC (40 MHz -> 4 MHz or 40 MHz -> 20 MHz)
-- Version 1.52(Dust Inc version)
-- Modified 16.01.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.AVRuCPackage.all;

entity FrqDiv is port(
                      clk_in     : in  std_logic;
			          clk_out    : out std_logic
		              );
end FrqDiv;

architecture RTL of FrqDiv is

signal DivCnt       : std_logic_vector(3 downto 0);
signal clk_out_int	: std_logic;

constant Div2 : boolean := TRUE; 

begin

-- Must be sequentially encoded

DivideBy10:if not Div2 generate 

Gen:process(clk_in)
begin
 if(clk_in='1' and clk_in'event) then -- Clock
  
  if(DivCnt=x"4") then DivCnt <= x"0";
   else	DivCnt <= DivCnt + 1;
  end if; 	  
  
  if(DivCnt=x"4") then clk_out_int <= not clk_out_int;
  end if;	  
  
 end if;
end process;		

end generate;


DivideBy10:if Div2 generate 

Gen:process(clk_in)
 begin
  if(clk_in='1' and clk_in'event) then -- Clock
   clk_out_int <= not clk_out_int;
  end if;
 end process;		

end generate;


clk_out <= clk_out_int;

end RTL;
