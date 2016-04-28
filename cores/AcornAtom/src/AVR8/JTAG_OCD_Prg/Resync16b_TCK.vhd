--**********************************************************************************************
-- Resynchronizer(16 bit,TCK clock) for JTAG OCD and "Flash" controller 
-- Version 0.1
-- Modified 27.05.2004
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

entity Resync16b_TCK is port(	                   
	                        TCK  : in  std_logic;
							DIn  : in  std_logic_vector(15 downto 0);
							DOut : out std_logic_vector(15 downto 0)
                            );
end Resync16b_TCK;

architecture RTL of Resync16b_TCK is

signal DIn_Tmp : std_logic_vector(DIn'range);

begin

ResynchronizerStageOne:process(TCK)
begin
 if(TCK='0' and TCK'event) then  -- Clock(Falling edge)
  DIn_Tmp <= DIn;                -- Stage 1 
 end if;	
end process;

ResynchronizerStageTwo:process(TCK)
begin
 if(TCK='1' and TCK'event) then  -- Clock(Rising edge)
  DOut <= DIn_Tmp;               -- Stage 2   
 end if;	
end process;


end RTL;
