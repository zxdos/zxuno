--**********************************************************************************************
-- RAM data register for the AVR Core
-- Version 0.1 
-- Modified 02.11.2002
-- Designed by Ruslan Lepetenok
--**********************************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;

entity RAMDataReg is port(	                   
               ireset      : in  std_logic;
               cp2	       : in  std_logic;
               cpuwait     : in  std_logic;
			   RAMDataIn   : in  std_logic_vector(7 downto 0);
			   RAMDataOut  : out std_logic_vector(7 downto 0)
	                     );
end RAMDataReg;

architecture RTL of RAMDataReg is
begin

RAMDataReg:process(cp2,ireset)
begin
if ireset='0' then                  -- Reset
 RAMDataOut <= (others => '0');
  elsif cp2='1' and cp2'event then  -- Clock
   if  cpuwait='0' then             -- Clock enable
    RAMDataOut <= RAMDataIn;
   end if;	
end if;	
end process;

end RTL;
