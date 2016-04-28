--************************************************************************************************
-- PM/DM memory components declarations for AVR core (Xilinx)
-- Version 0.4
-- Designed by Ruslan Lepetenok 
-- Modified 29.10.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package XMemCompPack is

	
component XPM16Kx16 is port(
	                  cp2     : in  std_logic;
					  ce      : in  std_logic;
	                  address : in  std_logic_vector(13 downto 0); 
					  din     : in  std_logic_vector(15 downto 0);		                
					  dout    : out std_logic_vector(15 downto 0);
					  weh     : in  std_logic;
					  wel     : in  std_logic
					  );
end component;


component XDM16Kx8 is port(
	                    cp2       : in  std_logic;
						ce      : in  std_logic;
	                    address   : in  std_logic_vector(13 downto 0); 
					    din       : in  std_logic_vector(7 downto 0);		                
					    dout      : out std_logic_vector(7 downto 0);
					    we        : in  std_logic
					   );
end component;

component XDM32Kx8 is port(
	                    cp2       : in  std_logic;
						ce      : in  std_logic;
	                    address   : in  std_logic_vector(14 downto 0); 
					    din       : in  std_logic_vector(7 downto 0);		                
					    dout      : out std_logic_vector(7 downto 0);
					    we        : in  std_logic
					   );
end component;

-- XPM8Kx16 was moved to the top level

component XPM4Kx16 is port(
	                  cp2     : in  std_logic;
					  ce      : in  std_logic;
	                  address : in  std_logic_vector(11 downto 0); 
					  din     : in  std_logic_vector(15 downto 0);		                
					  dout    : out std_logic_vector(15 downto 0);
					  we     : in  std_logic
					  );
end component;

-- XDM4Kx8 was moved to the top level

end XMemCompPack;
