--************************************************************************************************
-- 16Kx16(32 KB) PM RAM for AVR Core(Xilinx)
-- Version 0.2
-- Designed by Ruslan Lepetenok 
-- Modified 30.07.2005
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

entity XPM16Kx16 is port(
	                  cp2     : in  std_logic;
					  ce      : in  std_logic; 
	                  address : in  std_logic_vector(13 downto 0); 
					  din     : in  std_logic_vector(15 downto 0);		                
					  dout    : out std_logic_vector(15 downto 0);
					  weh     : in  std_logic;
					  wel     : in  std_logic
					  );
end XPM16Kx16;

architecture RTL of XPM16Kx16 is

type   RAMBlDOut_Type is array(2**(address'length-9)-1 downto 0) of  std_logic_vector(dout'range);
signal RAMBlDOut     : RAMBlDOut_Type;

signal WEBL     : std_logic_vector(2**(address'length-9)-1 downto 0);
signal WEBH     : std_logic_vector(2**(address'length-9)-1 downto 0);
signal gnd      : std_logic;

begin

gnd <= '0';	

WEBH_Dcd:for i in WEBL'range generate 
 WEBL(i) <= '1' when (wel='1' and address(address'high downto 9)=i) else '0';
end generate ;

WEBL_Dcd:for i in WEBH'range generate 
 WEBH(i) <= '1' when (weh='1' and address(address'high downto 9)=i) else '0';
end generate ;


RAM_Inst:for i in 0 to 2**(address'length-9)-1 generate

RAM_ByteLow:component RAMB4_S8 port map(
                                      DO   => RAMBlDOut(i)(7 downto 0),
                                      ADDR => address(8 downto 0),
                                      DI   => din(7 downto 0),
                                      EN   => ce,
                                      CLK  => cp2,
                                      WE   => WEBL(i),
                                      RST  => gnd
                                      );

RAM_ByteHigh:component RAMB4_S8 port map(
                                      DO   => RAMBlDOut(i)(15 downto 8),
                                      ADDR => address(8 downto 0),
                                      DI   => din(15 downto 8),
                                      EN   => ce,
                                      CLK  => cp2,
                                      WE   => WEBH(i),
                                      RST  => gnd
                                      );
									  
end generate;

-- Output data mux
dout <= RAMBlDOut(CONV_INTEGER(address(address'high downto 9)));


end RTL;
