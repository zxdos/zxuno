--**********************************************************************************************
-- Resynchronizers
-- Version 0.1
-- Modified 10.01.2007
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package	rsnc_comp_pack is

component rsnc_vect is generic(
	                        width        : integer := 8;  
	                        add_stgs_num : integer := 0;
						    inv_f_stgs   : integer := 0
	                        ); 
	                   port(	                   
	                        clk : in  std_logic;
							di  : in  std_logic_vector(width-1 downto 0);
							do  : out std_logic_vector(width-1 downto 0)
                            );
end component;


component rsnc_bit is generic(
	                        add_stgs_num : integer := 0;
						    inv_f_stgs   : integer := 0
	                        ); 
	                   port(	                   
	                        clk : in  std_logic;
							di  : in  std_logic;
							do  : out std_logic
                            );
end component;


component rsnc_l_vect is generic(              
	                          tech		   : integer := 0;
	                          width        : integer := 8;  
	                          add_stgs_num : integer := 0
	                        ); 
	                   port(	                   
	                        clk : in  std_logic;
							di  : in  std_logic_vector(width-1 downto 0);
							do  : out std_logic_vector(width-1 downto 0)
                            );
end component;


component rsnc_l_bit is generic(	
	                        tech		 : integer := 0; 
	                        add_stgs_num : integer := 0
	                        ); 
	                   port(	                   
	                        clk : in  std_logic;
							di  : in  std_logic;
							do  : out std_logic
                            );
end component;


end rsnc_comp_pack;

