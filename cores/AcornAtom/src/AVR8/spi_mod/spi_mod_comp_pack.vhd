--**********************************************************************************************
-- 
-- Version 0.1
-- Modified 31.12.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package	spi_mod_comp_pack is

component spi_mod is port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);
                    dbus_out   : out std_logic_vector(7 downto 0);
                    iore       : in  std_logic;
                    iowe       : in  std_logic;
                    out_en     : out std_logic; 
                    -- SPI i/f
					misoi	   : in  std_logic;	
					mosii	   : in  std_logic; 
					scki       : in  std_logic;	-- Resynch
					ss_b       : in  std_logic;	-- Resynch
					misoo	   : out std_logic;
					mosio	   : out std_logic;
					scko	   : out std_logic;
					spe        : out std_logic;
					spimaster  : out std_logic;
					-- IRQ
					spiirq     : out std_logic;
					spiack     : in  std_logic;
					-- Slave Programming Mode
					por		   : in  std_logic;
					spiextload : in  std_logic;
					spidwrite  : out std_logic;
					spiload    : out std_logic
                    );					
end component;

end spi_mod_comp_pack;

