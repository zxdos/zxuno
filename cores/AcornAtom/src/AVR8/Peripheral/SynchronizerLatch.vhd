--**********************************************************************************************
--  Transparent latch(used in the synchronizer instead of the first DFF)
--  Version 0.2
--  Modified 10.08.2003
--  Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

entity SynchronizerLatch is port(
	                             D  : in  std_logic;
								 G  : in  std_logic;
								 Q  : out std_logic;
								 QN : out std_logic);
end SynchronizerLatch;

architecture RTL of SynchronizerLatch is
signal Q_Tmp : std_logic;
begin

TransparentLatch:process(G,D)
begin
 if G='1' then -- Latch is transparent
  Q_Tmp <= D;
 end if; 
end process;	

Q <= Q_Tmp;
QN <= not Q_Tmp;

end RTL;
