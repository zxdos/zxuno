--**********************************************************************************************
-- Components declarations for JTAG OCD and "Flash" Programmer 
-- Version 0.2A
-- Modified 31.05.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package JTAGCompPack is 

component OCDProgTCK is port(
						  -- JTAG related inputs/outputs
						  TRSTn             : in  std_logic; -- Optional
	                      TMS               : in  std_logic;
                          TCK	            : in  std_logic;
                          TDI               : in  std_logic;
                          TDO               : out std_logic;
						  TDO_OE            : out std_logic;
						  -- From/To cp2 clock domain("Flash" programmer) 
						  FlEEPrgAdr        : out std_logic_vector(15 downto 0);
						  FlPrgRdData       : in  std_logic_vector(15 downto 0);
						  EEPrgRdData       : in  std_logic_vector(7 downto 0);
                          FlEEPrgWrData     : out std_logic_vector(15 downto 0);
						  ChipEraseStart    : out std_logic;
						  ChipEraseDone     : in  std_logic;
						  ProgEnable        : out std_logic;
						  FlWrMStart        : out std_logic;  -- Multiple 
						  FlWrSStart        : out std_logic;  -- Single 
						  FlRdMStart        : out std_logic;  -- Multiple 
						  FlRdSStart	    : out std_logic;  -- Single 
						  EEWrStart         : out std_logic;
						  EERdStart         : out std_logic;
						  TAPCtrlTLR        : out std_logic; -- TAP Controller is in the Test-Logic/Reset state
						  -- CPU reset
						  jtag_rst          : out std_logic
                          );
end component;	
	
component OCDProgcp2 is port(
	                      -- AVR Control
                          ireset           : in  std_logic;
                          cp2	           : in  std_logic;
						  -- From/To TCK clock domain("Flash" programmer) 
						  FlEEPrgAdr       : in  std_logic_vector(15 downto 0);
						  FlPrgRdData      : out std_logic_vector(15 downto 0);
						  EEPrgRdData      : out std_logic_vector(7 downto 0);
                          FlEEPrgWrData    : in  std_logic_vector(15 downto 0);
						  ChipEraseStart   : in  std_logic;
						  ChipEraseDone    : out std_logic;
						  ProgEnable       : in  std_logic;
						  FlWrMStart       : in  std_logic;  -- Multiple 
						  FlWrSStart       : in  std_logic;  -- Single 
						  FlRdMStart       : in  std_logic;  -- Multiple 
						  FlRdSStart	   : in  std_logic;  -- Single 
						  EEWrStart        : in  std_logic;
						  EERdStart        : in  std_logic;
						  TAPCtrlTLR       : in  std_logic; -- TAP Controller is in the Test-Logic/Reset state
						  -- From the core
                          PC               : in  std_logic_vector(15 downto 0);
						  -- To the PM("Flash")
						  pm_adr           : out std_logic_vector(15 downto 0);   
						  pm_h_we          : out std_logic;
						  pm_l_we          : out std_logic;
						  pm_dout          : in  std_logic_vector(15 downto 0);  
						  pm_din           : out std_logic_vector(15 downto 0);
						  -- To the "EEPROM"
						  EEPrgSel         : out std_logic;
						  EEAdr            : out std_logic_vector(11 downto 0);    
						  EEWrData         : out std_logic_vector(7 downto 0);
						  EERdData         : in  std_logic_vector(7 downto 0);
						  EEWr             : out std_logic
                          );
end component;


component Resync1b_cp2 is port(	                   
	                        cp2  : in  std_logic;
							DIn  : in  std_logic;
							DOut : out std_logic
                            );
end component;


component Resync1b_TCK is port(	                   
	                        TCK  : in  std_logic;
							DIn  : in  std_logic;
							DOut : out std_logic
                            );
end component;


component Resync16b_TCK is port(	                   
	                        TCK  : in  std_logic;
							DIn  : in  std_logic_vector(15 downto 0);
							DOut : out std_logic_vector(15 downto 0)
                            );
end component;


end JTAGCompPack;
