--**********************************************************************************************
--  Falling edge triggered flip-flop for the synchronizer
--  Version 0.1
--  Modified 30.07.2003
--  Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

entity SynchronizerDFF is port(
							   NRST : in  std_logic; 
	                           CLK  : in  std_logic;
							   D    : in  std_logic;
							   Q    : out std_logic);
end SynchronizerDFF;

architecture RTL of SynchronizerDFF is

begin

DFF:process(CLK,NRST)
begin
 if (NRST='0') then                  -- Reset
  Q <= '0'; 
 elsif (CLK='0' and CLK'event) then  -- Clock (falling edge)
  Q <= D;
 end if;
end process;							


end RTL;
