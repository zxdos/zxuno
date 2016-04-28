--************************************************************************************************
-- 32Kx8(32 KB) DM RAM for AVR Core(Xilinx)
-- Version 0.1
-- Designed by Ruslan Lepetenok 
-- Modified 29.10.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

-- For Synplicity Synplify
--library virtexe;
--use	virtexe.components.all; 

-- Aldec
library	unisim;
use unisim.vcomponents.all;

entity XDM32Kx8 is port(
	                            cp2       : in  std_logic;
					    ce        : in  std_logic; 
	                            address   : in  std_logic_vector(14 downto 0); 
					    din       : in  std_logic_vector(7 downto 0);		                
					    dout      : out std_logic_vector(7 downto 0);
					    we        : in  std_logic
					   );
end XDM32Kx8;

architecture RTL of XDM32Kx8 is

type   RAMBlDOut_Type is array(2**(address'length-9)-1 downto 0) of  std_logic_vector(dout'range);
signal RAMBlDOut     : RAMBlDOut_Type;

signal WEB      : std_logic_vector(2**(address'length-9)-1 downto 0);
signal cp2n     : std_logic;
signal gnd      : std_logic;

begin

gnd  <= '0';	

WEB_Dcd:for i in WEB'range generate 
 WEB(i) <= '1' when (we='1' and address(address'high downto 9)=i) else '0';
end generate ;


RAM_Inst:for i in 0 to 2**(address'length-9)-1 generate

RAM_Byte:component RAMB4_S8 port map(
                                      DO   => RAMBlDOut(i)(7 downto 0),
                                      ADDR => address(8 downto 0),
                                      DI   => din(7 downto 0),
                                      EN   => ce,
                                      CLK  => cp2,
                                      WE   => WEB(i),
                                      RST  => gnd
                                      );
								  
end generate;

-- Output data mux
dout <= RAMBlDOut(CONV_INTEGER(address(address'high downto 9)));

end RTL;
