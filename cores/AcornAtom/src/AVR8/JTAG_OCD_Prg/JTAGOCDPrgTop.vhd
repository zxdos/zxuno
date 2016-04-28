--**********************************************************************************************
-- Top entity for "Flash" programmer (for AVR Core)
-- Version 0.3A
-- Modified 31.05.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.JTAGCompPack.all;

entity JTAGOCDPrgTop is port(
	                      -- AVR Control
                          ireset       : in  std_logic;
                          cp2	       : in  std_logic;
						  -- JTAG related inputs/outputs
						  TRSTn        : in  std_logic; -- Optional
	                      TMS          : in  std_logic;
                          TCK	       : in  std_logic;
                          TDI          : in  std_logic;
                          TDO          : out std_logic;
						  TDO_OE       : out std_logic;
						  -- From the core
                          PC           : in  std_logic_vector(15 downto 0);
						  -- To the PM("Flash")
						  pm_adr       : out std_logic_vector(15 downto 0);   
						  pm_h_we      : out std_logic;
						  pm_l_we      : out std_logic;
						  pm_dout      : in  std_logic_vector(15 downto 0);  
						  pm_din       : out std_logic_vector(15 downto 0);
						  -- To the "EEPROM" 
						  EEPrgSel     : out std_logic;
						  EEAdr        : out std_logic_vector(11 downto 0);    
						  EEWrData     : out std_logic_vector(7 downto 0);
						  EERdData     : in  std_logic_vector(7 downto 0);
						  EEWr         : out std_logic;
						  -- CPU reset
						  jtag_rst     : out std_logic
                          );
end JTAGOCDPrgTop;

architecture RTL of JTAGOCDPrgTop is

-- From TCK clock domain to cp2 clock domain with resynchronization

signal ChipEraseStart_TCK    : std_logic;
signal ChipEraseStart_cp2    : std_logic;
signal ProgEnable_TCK        : std_logic;
signal ProgEnable_cp2        : std_logic;
signal FlWrMStart_TCK        : std_logic;
signal FlWrMStart_cp2        : std_logic;
signal FlWrSStart_TCK        : std_logic; 
signal FlWrSStart_cp2        : std_logic; 
signal FlRdMStart_TCK        : std_logic; 
signal FlRdMStart_cp2        : std_logic; 
signal FlRdSStart_TCK	     : std_logic; 
signal FlRdSStart_cp2	     : std_logic; 
signal EEWrStart_TCK         : std_logic;
signal EEWrStart_cp2         : std_logic;
signal EERdStart_TCK         : std_logic;
signal EERdStart_cp2         : std_logic;
signal TAPCtrlTLR_TCK        : std_logic;
signal TAPCtrlTLR_cp2        : std_logic;

				  

-- From TCK clock domain to cp2 clock domain without resynchronization
signal FlEEPrgAdr_TCK        : std_logic_vector(15 downto 0); -- Flash/EEPROM Address
signal FlEEPrgWrData_TCK     : std_logic_vector(15 downto 0); -- Flash/EEPROM Data for write

-- From cp2 clock domain to TCK clock domain with resynchronization
signal ChipEraseDone_cp2     : std_logic;
signal ChipEraseDone_TCK     : std_logic;

-- From cp2 clock domain to TCK clock domain without resynchronization
signal FlPrgRdData_cp2       : std_logic_vector(15 downto 0); -- Flash Read Data 
signal EEPrgRdData_cp2       : std_logic_vector(7 downto 0);  -- EEPROM Read Data


begin

OCDProgTCK_Inst:component OCDProgTCK port map(
						  -- JTAG related inputs/outputs
						  TRSTn             => TRSTn,
	                      TMS               => TMS,
                          TCK	            => TCK,
                          TDI               => TDI,
                          TDO               => TDO,
						  TDO_OE            => TDO_OE,
						  -- From/To cp2 clock domain("Flash" programmer) 
						  FlEEPrgAdr        => FlEEPrgAdr_TCK,
						  FlPrgRdData       => FlPrgRdData_cp2,
						  EEPrgRdData       => EEPrgRdData_cp2,
                          FlEEPrgWrData     => FlEEPrgWrData_TCK,
						  ChipEraseStart    => ChipEraseStart_TCK,
						  ChipEraseDone     => ChipEraseDone_TCK,
						  ProgEnable        => ProgEnable_TCK,
						  FlWrMStart        => FlWrMStart_TCK,
						  FlWrSStart        => FlWrSStart_TCK,
						  FlRdMStart        => FlRdMStart_TCK,
						  FlRdSStart	    => FlRdSStart_TCK,
						  EEWrStart         => EEWrStart_TCK,
						  EERdStart         => EERdStart_TCK,
						  TAPCtrlTLR        => TAPCtrlTLR_TCK,
						  -- CPU reset
						  jtag_rst          => jtag_rst
                          );
	

						  
OCDProgcp2_Inst:component OCDProgcp2 port map(
	                      -- AVR Control
                          ireset           => ireset,
                          cp2	           => cp2,
						  -- From/To TCK clock domain("Flash" programmer) 
						  FlEEPrgAdr       => FlEEPrgAdr_TCK,
						  FlPrgRdData      => FlPrgRdData_cp2,
						  EEPrgRdData      => EEPrgRdData_cp2,
                          FlEEPrgWrData    => FlEEPrgWrData_TCK,
						  ChipEraseStart   => ChipEraseStart_cp2,
						  ChipEraseDone    => ChipEraseDone_cp2,
						  ProgEnable       => ProgEnable_cp2,
						  FlWrMStart       => FlWrMStart_cp2,
						  FlWrSStart       => FlWrSStart_cp2,
						  FlRdMStart       => FlRdMStart_cp2,
						  FlRdSStart	   => FlRdSStart_cp2,
						  EEWrStart        => EEWrStart_cp2,
						  EERdStart        => EERdStart_cp2,
						  TAPCtrlTLR       => TAPCtrlTLR_cp2,
                          -- From the core
                          PC               => PC,
						  -- To the PM("Flash")
						  pm_adr           => pm_adr,
						  pm_h_we          => pm_h_we,
						  pm_l_we          => pm_l_we,
						  pm_dout          => pm_dout,
						  pm_din           => pm_din,
						  -- To the "EEPROM"
						  EEPrgSel         => EEPrgSel,
						  EEAdr            => EEAdr,
						  EEWrData         => EEWrData,
						  EERdData         => EERdData,
						  EEWr             => EEWr
                          );

	
						  
-- Resynchronizers (TCK to cp2)	
ChipEraseStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	ChipEraseStart_TCK,
							DOut => ChipEraseStart_cp2
                            );
							
ProgEnable_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	ProgEnable_TCK,
							DOut => ProgEnable_cp2
                            );						  							

FlWrMStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	FlWrMStart_TCK,
							DOut => FlWrMStart_cp2
                            );						  
							
FlWrSStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	FlWrSStart_TCK,
							DOut => FlWrSStart_cp2
                            );						  

FlRdMStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	FlRdMStart_TCK,
							DOut => FlRdMStart_cp2
                            );						  							

FlRdSStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	FlRdSStart_TCK,
							DOut => FlRdSStart_cp2
                            );						  
							
EEWrStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	EEWrStart_TCK,
							DOut => EEWrStart_cp2
                            );						  
							
EERdStart_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	EERdStart_TCK,
							DOut => EERdStart_cp2
                            );						  
							
TAPCtrlTLR_Resync_Inst:component Resync1b_cp2 port map(	                   
	                        cp2  => cp2,
							DIn  =>	TAPCtrlTLR_TCK,
							DOut => TAPCtrlTLR_cp2
                            );						  
			

							
-- Resynchronizers (cp2 to TCK)	

ChipEraseDone_Resync_Inst:component Resync1b_TCK port map(	                   
	                        TCK  => TCK,
							DIn  => ChipEraseDone_cp2,
							DOut => ChipEraseDone_TCK
                            );

						
end RTL;