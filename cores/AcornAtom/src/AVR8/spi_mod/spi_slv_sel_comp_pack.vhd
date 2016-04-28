--**********************************************************************************************
-- 
-- Version 0.2
-- Modified 10.01.2007
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package	spi_slv_sel_comp_pack is

component spi_slv_sel is generic(num_of_slvs : integer := 7);
	              port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);
                    dbus_out   : out std_logic_vector(7 downto 0);
                    iore       : in  std_logic;
                    iowe       : in  std_logic;
                    out_en     : out std_logic;
					-- Output
                    slv_sel_n  : out std_logic_vector(num_of_slvs-1 downto 0)
                    );					
end component;

end spi_slv_sel_comp_pack;

