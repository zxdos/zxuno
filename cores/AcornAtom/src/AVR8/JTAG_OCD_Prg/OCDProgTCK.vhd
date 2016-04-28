--**********************************************************************************************
-- JTAG	"Flash" programmer for AVR Core(TCK Clock Domain)
-- Version 0.4
-- Modified 20.06.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.JTAGPack.all;
use WORK.JTAGProgrammerPack.all;
use WORK.JTAGDataPack.all;
use WORK.JTAGTAPCtrlSMPack.all;

entity OCDProgTCK is port(
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
end OCDProgTCK;

architecture RTL of OCDProgTCK is

signal CurrentTAPState    : TAPCtrlState_Type;
signal NextTAPState       : TAPCtrlState_Type;

-- JTAG Registers
-- Instruction registers
signal InstructionShRg    : std_logic_vector(CInstrLength-1 downto 0); -- Shift
signal InstructionRg      : std_logic_vector(CInstrLength-1 downto 0); -- Update

-- Bypass register
signal BypassShRg         : std_logic; -- Shift(only)


-- **********************************************************************
signal IDCODEShRg         : std_logic_vector(31 downto 0);

signal DataRegsOutMux     : std_logic;

signal UnusedInstr        : std_logic; -- Unsupported instruction

-- Reset chain (1 bit length, no updade register)
signal ResetShRg : std_logic; 

-- ************************* Programmer part ********************************************
-- Program chains
signal PERSh : std_logic_vector(15 downto 0); -- Programming Enable Register (Shift part ?only?)

signal PCRSh    : std_logic_vector(14 downto 0); -- Programming Command Register (Shift part)
signal PCRUd    : std_logic_vector(PCRSh'range); -- Programming Command Register (Update part)
signal PCRShIn  : std_logic_vector(PCRSh'range); -- Programming Command Register Input

signal VFPLSh   : std_logic_vector(7 downto 0); -- Virtual Flash Page Load Register (Shift part only)
signal VFPRSh   : std_logic_vector(7 downto 0); -- Virtual Flash Page Read Register (Shift part only)
signal VFPRShIn : std_logic_vector(VFPRSh'range); -- Virtual Flash Page Read Register Input

signal ProgEnable_Int : std_logic;

-- TCK counter for Virtual Flash Page Load/Read commands
signal VFPCnt         : std_logic_vector(3 downto 0);
signal LdDataLow      : std_logic; -- Load low byte of data
signal LdDataHigh     : std_logic; -- Load high byte of data and runs "Flash" write SM(cp2 clock domain)
signal FlashAdrIncrEn : std_logic; -- Enables increment of VFPCnt (when LdDataHigh='1')
signal LatchWrData    : std_logic; 

-- Address(16-bit) and Instruction For Write (16-bit) registers located in TCK clock domaim 
signal FlEEPrgAdr_Int     : std_logic_vector(15 downto 0); -- Copy of output

-- Address counter length
constant CPageAdrCntLength : positive range 7 to 8 := 7; -- 8 for ATmega128, 7 for ATmega16,...  

-- "Flash" programmer state machines (located in TCK clock domaim)	
type ChipEraseSMStType is (ChipEraseSMStIdle,ChipEraseSMSt1,ChipEraseSMSt2,ChipEraseSMSt3);
signal ChipEraseSM_CurrentState : ChipEraseSMStType;	-- Chip erase 
signal ChipEraseSM_NextState    : ChipEraseSMStType;	-- Chip erase (combinatorial)

signal FlashWr_St            : std_logic; -- 2
signal FlashRd_St            : std_logic; -- 3
signal EEPROMWr_St           : std_logic; -- 4
signal EEPROMRd_St           : std_logic; -- 5
signal FuseWr_St             : std_logic; -- 6
signal LockWr_St             : std_logic; -- 7
signal FuseLockRd_St         : std_logic; -- 8
signal SignByteRd_St         : std_logic; -- 9

signal LoadNOP_St            : std_logic; -- 11 

-- EEPROM Write Support
signal EEWrStart_Int         : std_logic;
signal EERdStart_Int         : std_logic;	  

begin
	
TAPStateReg:process(TCK,TRSTn)
begin
 if(TRSTn='0')  then                 -- Reset
  CurrentTAPState <= TestLogicReset;
 elsif(TCK='1' and TCK'event)  then -- Clock(rising edge)
  CurrentTAPState <= NextTAPState;
 end if;
end process;			


NextTAPState <= FnTAPNextState(CurrentTAPState,TMS);

-- Instruction register
InstructionRegisterShift:process(TCK,TRSTn)
begin
 if(TRSTn='0') then                 -- Reset
  InstructionShRg <= (others => '0');
 elsif(TCK='1' and TCK'event) then  -- Clock(rising edge)
  case CurrentTAPState is 
   --when CaptureIR => InstructionShRg <= InstructionRg(InstructionRg'high downto 2)&"01"; -- !!! TBD !!!
   when CaptureIR => InstructionShRg <= InstructionRg; -- !!! TBD !!!
   when	ShiftIR   => InstructionShRg <= FnJTAGRgSh(InstructionShRg,TDI);
   when others    => null;
  end case;
end if;
end process;			

InstructionRegisterUpdate:process(TCK,TRSTn)
begin
if (TRSTn='0') then                 -- Reset
  InstructionRg <= CInitInstrRegVal;
elsif (TCK='0' and TCK'event) then  -- Clock(falling edge)
  if (CurrentTAPState=TestLogicReset) then 
   InstructionRg <= CInitInstrRegVal;	-- Set to give IDCODE or BYPASS instruction  
  elsif CurrentTAPState=UpdateIR then   
   InstructionRg <= InstructionShRg;
  end if;
end if;
end process;			

-- Data registers

-- ID Code register
IDCodeRegisterShift:process(TCK,TRSTn)
begin
 if (TRSTn='0') then                 -- Reset
  IDCODEShRg <= (others => '0');
 elsif (TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if (InstructionRg=C_IDCODE) then      -- The Instruction register content enables The Data register shift
   case CurrentTAPState is 
    when CaptureDR => IDCODEShRg <= CVersion&CPartNumber&CManufacturerId&'1'; 
    when ShiftDR   => IDCODEShRg <= FnJTAGRgSh(IDCODEShRg,TDI);
    when others    => null;
   end case;
  end if;
 end if;
end process;		

-- Bypass register
BypassRegisterShift:process(TCK,TRSTn)
begin
 if (TRSTn='0')  then                 -- Reset
  BypassShRg <= '0';
 elsif (TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if (InstructionRg=C_BYPASS) then -- !!! TBD !!!
   case CurrentTAPState is 
    when ShiftDR => BypassShRg <= TDI;	 
    when others  => BypassShRg <= '0';  -- ??? TBD
   end case;
  end if;
 end if;
end process;			


DORegAndTDOOE:process(TCK,TRSTn)
begin
 if (TRSTn='0')  then                 -- Reset
  TDO <= '0';
  TDO_OE <= '0';  
 elsif  (TCK='0' and TCK'event)  then -- Clock(falling edge)
  TDO <= DataRegsOutMux;
  if (CurrentTAPState=ShiftIR or CurrentTAPState=ShiftDR) then
   TDO_OE <= '1'; 
  else
   TDO_OE <= '0';
  end if;	 
 end if;
end process;							  

-- ***************************************************************************************

UnusedInstr <= '1' when (InstructionRg=C_UNUSED_3 or InstructionRg=C_UNUSED_D or
                        InstructionRg=C_UNUSED_E or InstructionRg=C_OCD_ACCESS or InstructionRg= C_EX_INST) else '0';
							
DataRegsOutMux <= InstructionShRg(InstructionShRg'low) when CurrentTAPState=ShiftIR else -- !!! TBD !!!
				  '0' when InstructionRg=C_SAMPLE_PRELOAD or InstructionRg=C_EXTEST else -- !!! TBD !!!
				  IDCODEShRg(IDCODEShRg'low) when InstructionRg=C_IDCODE else
				  ResetShRg when InstructionRg=C_AVR_RESET else
				  PERSh(PERSh'low) when InstructionRg=C_PROG_ENABLE else
				  PCRSh(PCRSh'low) when InstructionRg=C_PROG_COMMANDS else
				  VFPLSh(VFPLSh'low) when InstructionRg=C_PROG_PAGELOAD else	  
				  VFPRSh(VFPRSh'low) when InstructionRg=C_PROG_PAGEREAD else	  	  
				  BypassShRg;				  
				  
-- ***************************************************************************************
	  
				  
-- Reset chain (1 bit length, no updade register)				  
ResetRegisterShift:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if(InstructionRg=C_AVR_RESET and CurrentTAPState=ShiftDR) then 
   ResetShRg <= TDI;	 
  end if;
 end if;
end process;	

jtag_rst <= ResetShRg; 


-- ************************************************************************************
-- ************************* Programmer part ********************************************
-- ************************************************************************************

-- Programming Enable Register(no update circuit)
PER_Shift:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if(InstructionRg=C_PROG_ENABLE and CurrentTAPState=ShiftDR) then 
   PERSh <= FnJTAGRgSh(PERSh,TDI);
  end if;
 end if;
end process;	

-- Programming enable signal generation(!!! TBD !!!)
PE_Gen_Rg:process(TCK)
begin
 if(TCK='0' and TCK'event)  then  -- Clock(falling edge)
  if(InstructionRg=C_PROG_ENABLE and CurrentTAPState=UpdateDR) then -- ???
   if(PERSh=C_ProgEnableVect) then
	ProgEnable_Int <= '1';
   else	
    ProgEnable_Int <= '0';
   end if;	
  end if;
 end if;
end process;	

-- Programming Command Register
PCR_Shift:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if(InstructionRg=C_PROG_COMMANDS) then 
   case CurrentTAPState is 
    when CaptureDR => PCRSh <= PCRShIn; -- Load data
    when ShiftDR   => PCRSh <= FnJTAGRgSh(PCRSh,TDI);
    when others    => null;
   end case;
  end if;
 end if;
end process;	


PCRShIn(14 downto 10) <= PCRSh(14 downto 10);	
PCRShIn(8) <= PCRSh(8);	

-- Poll response  !!!TBD!!!
PCRShIn(9) <= '0' when (ChipEraseSM_CurrentState /= ChipEraseSMStIdle) else '1';	

	
PCRReadSystem:process(TCK)
begin
if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
 if(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then 	
	 
  if(FlashRd_St='1') then     -- Flash read	 
   if(PCRSh=C_Prg_3D_1) then	  
	 PCRShIn(7 downto 0) <= FlPrgRdData(7 downto 0); -- Read low flash byte
   elsif(PCRSh=C_Prg_3D_2) then	 
	 PCRShIn(7 downto 0) <= FlPrgRdData(15 downto 8); -- Read high flash byte
   end if;	 
   
  elsif(EEPROMRd_St='1') then -- EEPROM read	 
   if(PCRSh=C_Prg_5D_2) then	 
	PCRShIn(7 downto 0) <= EEPrgRdData; 
   end if;	 
   
  elsif(FuseLockRd_St='1') then -- Fuse/Lock bit Read Mode(8)
   case PCRSh  is  -- !!!TBD!!! (Length) 	
	when C_Prg_8B_1 =>  -- 8b(8f1) Read Extended Fuse Byte
	 PCRShIn(7 downto 0) <= C_ExtFuseByte;
	when C_Prg_8C_1 =>  -- 8c(8f2) Read Fuse High Byte
	 PCRShIn(7 downto 0) <= C_HighFuseByte;
	when C_Prg_8D_1 =>  -- 8d(8f3) Read Fuse Low Byte
	 PCRShIn(7 downto 0) <= C_LowFuseByte;
	when C_Prg_8E_1 =>  -- 8e(8f4) Read Lock Bits
	 PCRShIn(7 downto 0) <= C_LockBits;
	when others => null;
   end case;	 
   
  elsif (SignByteRd_St='1') then -- Signature Byte Read  Mode(9/10)
   if(PCRSh=C_Prg_9C_1) then -- Read Signature Byte(9c) -> 0110010_00000000
    case FlEEPrgAdr_Int(3 downto 0) is  -- !!!TBD!!! (Length) 	
	 when x"0" => PCRShIn(7 downto 0) <= C_SignByte1;
	 when x"1" => PCRShIn(7 downto 0) <= C_SignByte2;
	 when x"2" => PCRShIn(7 downto 0) <= C_SignByte3;
	 when others => null;
    end case;
	
   elsif(PCRSh=C_Prg_10C_1) then -- Read Calibration Byte(10c) -> 0110110_00000000
    case FlEEPrgAdr_Int(3 downto 0) is  -- !!!TBD!!! (Length) 	
	 when x"0" => PCRShIn(7 downto 0) <= C_CalibrByte1;
	 when x"1" => PCRShIn(7 downto 0) <= C_CalibrByte2;
	 when x"2" => PCRShIn(7 downto 0) <= C_CalibrByte3;
     when x"3" => PCRShIn(7 downto 0) <= C_CalibrByte4;
	 when others => null;
    end case;   
   
   end if;
   
  end if;   
 end if;   
end if;
end process;		
	

PCR_Update:process(TCK)
begin
 if(TCK='0' and TCK'event)  then  -- Clock(falling edge)
  if (CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then -- Clock enable (!!!InstructionRg=C_PROG_COMMANDS!!!)
   PCRUd <= PCRSh;
  end if;
 end if;
end process;	


-- Virtual Flash Page Load Register(!!!shift only!!!)
VFPL_Shift:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if(InstructionRg=C_PROG_PAGELOAD and CurrentTAPState=ShiftDR) then 
   VFPLSh <= FnJTAGRgSh(VFPLSh,TDI);
  end if;
 end if;
end process;	

-- !!! TBD !!!
VFPRShIn <= FlPrgRdData(7 downto 0) when VFPCnt(VFPCnt'high)='0' else -- Low Byte
	        FlPrgRdData(15 downto 8);                                 -- High Byte

			
-- Virtual Flash Page Read Register
VFPR_Shift:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if((VFPCnt=x"7" or VFPCnt=x"F"))then -- Load Data (Low/High Byte) !!!TBD!!!
   VFPRSh <= VFPRShIn; -- Load data
  elsif(InstructionRg=C_PROG_PAGEREAD and CurrentTAPState=ShiftDR) then 
   VFPRSh <= FnJTAGRgSh(VFPRSh,TDI);
  end if;
 end if;
end process;	


-- TCK counter for Virtual Flash Page Load/Read commands 
VFPCounterReg:process(TCK)
begin
 if(TCK='1' and TCK'event)  then  -- Clock(rising edge) ???
  if(CurrentTAPState=CaptureDR)then -- Clear
   VFPCnt <= (others => '0');
  elsif(CurrentTAPState=ShiftDR and
	   (InstructionRg=C_PROG_PAGELOAD or InstructionRg=C_PROG_PAGEREAD)and 
	   (FlashWr_St='1' or FlashRd_St='1')) then  -- Was : FlashWr_St='1' only
   VFPCnt <= VFPCnt+1; -- Increment
  end if;
 end if;
end process;	


VFPWrControl:process(TCK)
begin
if(TCK='1' and TCK'event)  then  -- Clock(rising edge) ???
 if(CurrentTAPState=CaptureDR)then -- Clear
  LdDataLow  <= '0';
  LdDataHigh <= '0';
  FlashAdrIncrEn <= '0';
 elsif(CurrentTAPState=ShiftDR and InstructionRg=C_PROG_PAGELOAD and FlashWr_St='1') then  -- Page Load
	   
  if(VFPCnt=x"7") then  
   LdDataLow  <= '1';
  else 
   LdDataLow  <= '0';
  end if;
  
  if(VFPCnt=x"F") then  
   LdDataHigh  <= '1';
  else 
   LdDataHigh  <= '0';
  end if;
  
  if(LdDataHigh='1') then -- !!!TBD!!!
   FlashAdrIncrEn <= '1';
  end if;
  
 end if;
end if;
end process;	


VFPRdControl:process(TCK)
begin
if(TCK='1' and TCK'event)  then  -- Clock(rising edge)
 if(CurrentTAPState=CaptureDR)then -- Clear
  FlRdMStart <= '0';
 elsif(CurrentTAPState=ShiftDR and InstructionRg=C_PROG_PAGEREAD and FlashRd_St='1') then  -- Page Read
  if(VFPCnt=x"1") then
   FlRdMStart <= '1';
  else  
   FlRdMStart <= '0';	  
  end if; 
 end if;
end if;
end process;	


LatchWriteData:process(TCK)
begin
if(TCK='0' and TCK'event)  then  -- Clock(falling edge) ???
 if(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and 
	FlashWr_St='1' and PCRSh=C_Prg_2F_2) then 
  LatchWrData <= '1';
 else 
  LatchWrData  <= '0'; 
 end if;
end if;
end process;	

-- EEPROM
EEPROMWrRdCtrl:process(TCK)
begin
if(TCK='1' and TCK'event)  then  -- Clock(rising edge) ???
 if(CurrentTAPState=CaptureDR)then -- Clear
  EEWrStart_Int <= '0';
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and EEPROMWr_St='1' and PCRSh=C_Prg_4E_2) then  -- EEPROM Write
  EEWrStart_Int <= '1';
 else  
  EEWrStart_Int <= '0';	 
 end if;

 if(CurrentTAPState=CaptureDR)then -- Clear
  EERdStart_Int <= '0';
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and EEPROMRd_St='1' and PCRSh(14 downto 8)=C_Prg_5D_1) then  -- EEPROM Read ! was C_Prg_5D_2
  EERdStart_Int <= '1';
 else  
  EERdStart_Int <= '0';	 
 end if; 
 
end if;
end process;	


-- Flash single beat operations (Write/Read)
FlashSingleWrRdCtrl:process(TCK)
begin
if(TCK='1' and TCK'event)  then  -- Clock(rising edge) ???
 if(CurrentTAPState=CaptureDR)then 
  FlWrSStart <= '0';
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and FlashWr_St='1' and PCRSh=C_Prg_2F_2) then  -- Flash write (single)
  FlWrSStart <= '1';
 else  
  FlWrSStart <= '0';	 
 end if;

 if(CurrentTAPState=CaptureDR)then
  FlRdSStart <= '0';
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and FlashRd_St='1' and PCRSh=C_Prg_3D_1) then  -- Flash read (single)
  FlRdSStart <= '1';
 else  
  FlRdSStart <= '0';	 
 end if; 
 
end if;
end process;	


-- Address register
FlashProgrammerAdrReg:process(TCK)
begin
if(TCK='0' and TCK'event)  then  -- Clock(falling edge) like udate reg ???
 if(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then 
  if(PCRSh(14 downto 8)="0000011") then -- Load Address Low Byte(2c,3c,4c,5c,9b,10b)	   
   FlEEPrgAdr_Int(7 downto 0) <= PCRSh(7 downto 0); 
  elsif(PCRSh(14 downto 8)="0000111")then -- Load Address High Byte(2b,3b,4b,5b)
   FlEEPrgAdr_Int(15 downto 8) <= PCRSh(7 downto 0);
  end if;
 elsif(((CurrentTAPState=ShiftDR or CurrentTAPState=Exit1DR)and 
	   InstructionRg=C_PROG_PAGELOAD and LdDataHigh='1' and FlashAdrIncrEn='1')or  -- Write "Flash"
       (CurrentTAPState=ShiftDR and InstructionRg=C_PROG_PAGEREAD and FlashRd_St='1' and VFPCnt=x"E")) then  -- Read "Flash"
  -- Increment address counter
  FlEEPrgAdr_Int(CPageAdrCntLength-1 downto 0)<=FlEEPrgAdr_Int(CPageAdrCntLength-1 downto 0)+1;  
 end if;
end if;
end process;	


-- Data register
FlashProgrammerDataReg:process(TCK)
begin
if(TCK='0' and TCK'event)  then  -- Clock(falling edge) like udate reg ???
 if(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then 
  if(PCRSh(14 downto 8)="0010011") then -- Load Data Low Byte(2d,4d,6b,6e,6h,7b) 
   FlEEPrgWrData(7 downto 0) <= PCRSh(7 downto 0); 
  elsif(PCRSh(14 downto 8)="0010111") then -- Load Data High Byte(2e) 
   FlEEPrgWrData(15 downto 8) <= PCRSh(7 downto 0); 
  end if;  
 elsif((CurrentTAPState=ShiftDR or CurrentTAPState=Exit1DR)and (InstructionRg=C_PROG_PAGELOAD)) then
  if(LdDataLow='1') then -- Load Data Low Byte(from the Virtual Flash Page Load Register) 
   FlEEPrgWrData(7 downto 0) <= VFPLSh; 
  elsif(LdDataHigh='1') then -- Load Data High Byte(from the Virtual Flash Page Load Register) 
   FlEEPrgWrData(15 downto 8) <= VFPLSh; 
  end if;  
 end if; 
end if;
end process;	


-- Programmer State Machines
EraseSMRg:process(TCK,TRSTn)
begin
if(TRSTn='0') then                 -- Reset (!!!TBD!!!)
 ChipEraseSM_CurrentState <= ChipEraseSMStIdle;
elsif(TCK='1' and TCK'event)  then  -- Clock(rising edge)
 if (CurrentTAPState=TestLogicReset) then -- Test-Logic-Reset state 
  ChipEraseSM_CurrentState <= ChipEraseSMStIdle;
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then
  ChipEraseSM_CurrentState <= ChipEraseSM_NextState; 
 end if; 
end if;
end process;	


-- Programmer State Machines
ChipEraseStartDFF:process(TCK,TRSTn)
begin
 if(TRSTn='0') then                 -- Reset (!!!TBD!!!)
  ChipEraseStart <= '0';
 elsif(TCK='1' and TCK'event)  then  -- Clock(rising edge)
  if(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS and PCRSh=C_Prg_1A_1 and ProgEnable_Int='1') then	 
   ChipEraseStart <= '1';
  else 
   ChipEraseStart <= '0';	  
  end if;	   
 end if;
end process;	


EraseSMComb:process(ChipEraseSM_CurrentState,PCRUd,ChipEraseDone,ProgEnable_Int) -- Combinatorial
begin
 case ChipEraseSM_CurrentState is
  when ChipEraseSMStIdle => 
   if(PCRUd=C_Prg_1A_1 and ProgEnable_Int='1') then
	ChipEraseSM_NextState <= ChipEraseSMSt1; 
   else
	ChipEraseSM_NextState <= ChipEraseSMStIdle;   
   end if;
   when ChipEraseSMSt1 => 
   if(PCRUd=C_Prg_1A_2) then
	ChipEraseSM_NextState <= ChipEraseSMSt2;
   else 
	ChipEraseSM_NextState <= ChipEraseSMStIdle; -- Leaving Erase Mode
   end if;
  when ChipEraseSMSt2 =>
   if(PCRUd=C_Prg_1A_3) then
	ChipEraseSM_NextState <= ChipEraseSMSt3;  
   else 
	ChipEraseSM_NextState <= ChipEraseSMStIdle; -- Leaving Erase Mode	 
   end if;
  when ChipEraseSMSt3 => 
   if(ChipEraseDone='1') then
	ChipEraseSM_NextState <= ChipEraseSMStIdle;
   else
	ChipEraseSM_NextState <= ChipEraseSMSt3;   
   end if;
  when others => ChipEraseSM_NextState <= ChipEraseSMStIdle; 	 
 end case;
end process;	


ProgSMsRegs:process(TCK,TRSTn)
begin
if(TRSTn='0') then                 -- Reset (!!!TBD!!!)
 FlashWr_St      <= '0';
 FlashRd_St      <= '0';
 EEPROMWr_St     <= '0';
 EEPROMRd_St     <= '0';
 FuseWr_St       <= '0';
 LockWr_St       <= '0';
 FuseLockRd_St   <= '0';
 SignByteRd_St   <= '0';
 LoadNOP_St      <= '0';
elsif(TCK='1' and TCK'event)  then  -- Clock(rising edge)
 if(CurrentTAPState=TestLogicReset)then 
  FlashWr_St     <= '0';
  FlashRd_St     <= '0';
  EEPROMWr_St    <= '0';
  EEPROMRd_St    <= '0';
  FuseWr_St      <= '0';
  LockWr_St      <= '0';
  FuseLockRd_St  <= '0';
  SignByteRd_St  <= '0';
  LoadNOP_St     <= '0';  
 elsif(CurrentTAPState=UpdateDR and InstructionRg=C_PROG_COMMANDS) then
  case FlashWr_St is
   when '0' =>
    if(PCRUd=C_Prg_2A and ProgEnable_Int='1')then
     FlashWr_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_2A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_2A(7 downto 0))then
     FlashWr_St <= '0';
	end if; 	
   when others => null;
  end case;	  

  case FlashRd_St is
   when '0' =>
    if(PCRUd=C_Prg_3A and ProgEnable_Int='1')then
     FlashRd_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_3A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_3A(7 downto 0))then
     FlashRd_St <= '0';
	end if; 	
   when others => null;
  end case;	    

  case EEPROMWr_St is
   when '0' =>
    if(PCRUd=C_Prg_4A and ProgEnable_Int='1')then
     EEPROMWr_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_4A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_4A(7 downto 0))then
     EEPROMWr_St <= '0';
	end if; 	
   when others => null;
  end case;	      

  case EEPROMRd_St is
   when '0' =>
    if(PCRUd=C_Prg_5A and ProgEnable_Int='1')then
     EEPROMRd_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_5A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_5A(7 downto 0))then
     EEPROMRd_St <= '0';
	end if; 	
   when others => null;
  end case;	        

  case FuseWr_St is
   when '0' =>
    if(PCRUd=C_Prg_6A and ProgEnable_Int='1')then
     FuseWr_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_6A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_6A(7 downto 0))then
     FuseWr_St <= '0';
	end if; 	
   when others => null;
  end case;	          

  case LockWr_St is
   when '0' =>
    if(PCRUd=C_Prg_7A and ProgEnable_Int='1')then
     LockWr_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_7A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_7A(7 downto 0))then
     LockWr_St <= '0';
	end if; 	
   when others => null;
  end case;	            
  
  case FuseLockRd_St is
   when '0' =>
    if(PCRUd=C_Prg_8A and ProgEnable_Int='1')then
     FuseLockRd_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_8A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_8A(7 downto 0))then
     FuseLockRd_St <= '0';
	end if; 	
   when others => null;
  end case;	          
  
  case SignByteRd_St is
   when '0' =>
    if(PCRUd=C_Prg_9A and ProgEnable_Int='1')then
     SignByteRd_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_9A(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_9A(7 downto 0))then
     SignByteRd_St <= '0';
	end if; 	
   when others => null;
  end case;	            
  
  case LoadNOP_St is
   when '0' =>
    if(PCRUd=C_Prg_11A_1 and ProgEnable_Int='1')then
     LoadNOP_St <= '1';
    end if; 	   
   when '1' =>
    if(PCRUd(14 downto 8)=C_Prg_11A_1(14 downto 8) and PCRUd(7 downto 0)/=C_Prg_11A_1(7 downto 0))then
     LoadNOP_St <= '0';
	end if; 	
   when others => null;
  end case;	              
  
 end if;	 
end if;
end process;		

TAPResetFlag:process(TCK,TRSTn)
begin
if(TRSTn='0') then                 -- Reset (!!!TBD!!!)
 TAPCtrlTLR <= '1'; 	
elsif(TCK='1' and TCK'event)  then  -- Clock(rising edge)	
 if((CurrentTAPState=SelectIRScan and TMS='1')or(CurrentTAPState=TestLogicReset and TMS='0'))then 
  TAPCtrlTLR <= '1';
 else  
  TAPCtrlTLR <= '0';
 end if;	 
end if;
end process;
 
-- *************************** End of programmer part *******************************

-- Outputs
FlEEPrgAdr <= FlEEPrgAdr_Int;

FlWrMStart <= LdDataHigh;

ProgEnable <= ProgEnable_Int;

end RTL;
