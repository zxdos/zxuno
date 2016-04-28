--************************************************************************************************
-- Component declaration for the synchronizer
-- Version 0.2
-- Designed by Ruslan Lepetenok 
-- Modified 10.08.2003
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package SynchronizerCompPack is

-- Transparent D latch	
component SynchronizerLatch is port(
	                             D  : in  std_logic;
								 G  : in  std_logic;
								 Q  : out std_logic;
								 QN : out std_logic);
end component;

-- Falling edge triggered flip-flop
component SynchronizerDFF is port(
							   NRST : in  std_logic; 
	                           CLK  : in  std_logic;
							   D    : in  std_logic;
							   Q    : out std_logic);
end component;

end SynchronizerCompPack;	
