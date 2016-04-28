--**********************************************************************************************
-- Resynchronizer(1 bit,cp2 clock) for JTAG	OCD and "Flash" controller 
-- Version 0.1
-- Modified 27.05.2004
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

entity Resync1b_cp2 is port(	                   
	                        cp2  : in  std_logic;
							DIn  : in  std_logic;
							DOut : out std_logic
                            );
end Resync1b_cp2;

architecture RTL of Resync1b_cp2 is

signal DIn_Tmp : std_logic;

begin

ResynchronizerDFFs:process(cp2)
begin
 if(cp2='1' and cp2'event) then  -- Clock
  DIn_Tmp <= DIn;                -- Stage 1 
  DOut <= DIn_Tmp;               -- Stage 2   
 end if;	
end process;


end RTL;
