--**********************************************************************************************
-- JTAG	"Flash" programmer for AVR Core(cp2 Clock Domain)
-- Version 0.5
-- Modified 20.06.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.JTAGPack.all;
use WORK.AVRuCPackage.all;

entity OCDProgcp2 is port(
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
end OCDProgcp2;

architecture RTL of OCDProgcp2 is

-- **********************************************************************************
-- *************************** Programmer part *********************************************
-- **********************************************************************************

-- Edge detectors
signal TAPCtrlTLRDel          : std_logic; -- TAP Run-Test/Idle
	
-- Chip Erase Start	edge detector
signal ChipEraseStartDel  : std_logic;  
-- Flash Write Start(using Virtual Flash Page Load Register) edge detector
signal FlWrMStartDel         : std_logic;  
-- Flash Write Start(using Load Data Low(2d)/Load Data High(2e)) edge detector	
signal FlWrSStartDel	    : std_logic;
--  Flash Read Start(using Virtual Flash Page Read Register) edge detector
signal FlRdMStartDel          : std_logic;  
--  Flash Read Start(using Load Data Low and High Byte(3d)) edge detector	
signal FlRdSStartDel	     : std_logic;	

-- "Flash" programmer state machines 
signal FlWrCnt               : std_logic_vector(1 downto 0) ; -- Write
signal FlRdCnt               : std_logic_vector(1 downto 0) ; -- Read (Low andHigh bytes)
signal FlRd_St               : std_logic; -- "Flash" read(Latch data)

-- "Flash" address and data registers 
signal FlashPrgAdrRg         : std_logic_vector(15 downto 0);  -- Address(Write/Read)
signal FlashPrgDataRg        : std_logic_vector(15 downto 0);  -- Data(for Write)
	
-- Output copies
signal pm_h_we_Int           : std_logic;
signal pm_l_we_Int           : std_logic;

-- Chip erase
signal ChipErase_St          : std_logic;

-- "EEPROM" support
-- Edge detectors
signal EEWrStartDel          : std_logic;
signal EERdStartDel			 : std_logic;

-- EEPROM address and data registers 
signal EEPrgAdrRg            : std_logic_vector(EEAdr'range);  -- Address(Write/Read)
signal EEPrgDataRg           : std_logic_vector(EEWrData'range);  -- Data(for Write)
signal EEWr_Int              : std_logic;

-- EEPROM programmer state machines 
signal EEWrCnt               : std_logic_vector(1 downto 0) ; -- Write
signal EERdCnt               : std_logic_vector(1 downto 0) ; -- Read
signal EERd_St               : std_logic;


begin

-- ***************************** Programmer part ********************************


FlashWriteCntAndCtrl:process(cp2)
begin
 if(cp2='1' and cp2'event)  then  -- Clock cp2(Rising edge)
  -- Edge detectors
  TAPCtrlTLRDel <= TAPCtrlTLR;
  FlWrMStartDel <= FlWrMStart;	 
  FlWrSStartDel <= FlWrSStart;
    
  -- Delay counter
  if(TAPCtrlTLR='1') then -- Reset counter
   FlWrCnt <= (others => '0');	  
  elsif((FlWrMStart='0' and FlWrMStartDel='1')or
	    (FlWrSStart='0' and FlWrSStartDel='1')) then 
   FlWrCnt <= "01";
  elsif(FlWrCnt/="00") then 
   FlWrCnt <= FlWrCnt + 1;	  
  end if;	  
  
  -- Control 
  if(TAPCtrlTLR='1') then -- Reset control signals
   pm_h_we_Int <= '0';	  
   pm_l_we_Int <= '0';	  
  else
   case pm_h_we_Int is 
	when '0' => 
	 if((ChipEraseStart='1' and ChipEraseStartDel='0') or FlWrCnt="11") then 
	  pm_h_we_Int <= '1'; 
	 end if; 	 
	when '1' =>	
	 if(ChipErase_St='0' or (ChipErase_St='1' and FlashPrgAdrRg=C_MaxEraseAdr)) then
	  pm_h_we_Int <= '0';
	 end if; 	  
    when others => null;
   end case; 	

   case pm_l_we_Int is 
	when '0' => 
	 if((ChipEraseStart='1' and ChipEraseStartDel='0') or FlWrCnt="11") then 
	  pm_l_we_Int <= '1'; 
	 end if; 	 
	when '1' =>
	 if(ChipErase_St='0' or (ChipErase_St='1' and FlashPrgAdrRg=C_MaxEraseAdr)) then
	  pm_l_we_Int <= '0';
	 end if; 
    when others => null;
   end case; 	
  end if;

  -- Address (for Erase,Write and Read!!!)
  if(ChipEraseStart='1' and ChipEraseStartDel='0') then -- Start of chip erase -> Clear address counter
   FlashPrgAdrRg <= (others => '0');
  elsif(ChipErase_St='1') then		                    -- Chip erase -> increment aaddress
   FlashPrgAdrRg <= FlashPrgAdrRg + 1;
  elsif(FlWrCnt="11" or FlRdCnt="11") then              -- Normal mode
   FlashPrgAdrRg <= FlEEPrgAdr; 
  end if;
   
  -- Data
  if(ChipEraseStart='1' and ChipEraseStartDel='0') then -- Start of chip erase 
   FlashPrgDataRg <= (others => '1');
  elsif(FlWrCnt="11") then 	                            -- Write to flash 
   FlashPrgDataRg <= FlEEPrgWrData;
  end if;
  
   -- EEPROM Address (for Erase,Write and Read!!!)
  if(ChipEraseStart='1' and ChipEraseStartDel='0') then -- Start of chip erase -> Clear address counter
   EEPrgAdrRg <= (others => '0');
  elsif(ChipErase_St='1') then		                    -- Chip erase -> increment aaddress
   EEPrgAdrRg <= EEPrgAdrRg + 1;
  elsif(EEWrCnt="11" or EERdCnt="11") then  -- Normal mode 
   EEPrgAdrRg <= FlEEPrgAdr(EEPrgAdrRg'range); 
  end if;
   
  -- EEPROM Data
  if(ChipEraseStart='1' and ChipEraseStartDel='0') then -- Start of chip erase 
   EEPrgDataRg <= (others => '1');
  elsif(EEWrCnt="11") then 	                            -- Write to EEPROM 
   EEPrgDataRg <= FlEEPrgWrData(EEPrgDataRg'range);
  end if;
    
  -- EEPROM Write
   case EEWr_Int is 
	when '0' => 
	 if((ChipEraseStart='1' and ChipEraseStartDel='0') or EEWrCnt="11") then 
	  EEWr_Int <= '1'; 
	 end if; 	 
	when '1' =>
	 if(ChipErase_St='0' or (ChipErase_St='1' and FlashPrgAdrRg=C_MaxEraseAdr)) then
	  EEWr_Int <= '0';
	 end if; 
    when others => EEWr_Int <= '0';
   end case; 	
  
  -- EEPROM Read state
  if(EERdCnt="11") then 
   EERd_St <= '1';
  else 
   EERd_St <= '0';
  end if; 
  
  end if;
 end process;	

 -- "Flash" write enables
 pm_l_we <= pm_l_we_Int; 
 pm_h_we <= pm_h_we_Int; 
 
 -- "Flash" data inputs
 pm_din <= FlashPrgDataRg;

-- EEPROM 
 EEAdr    <= EEPrgAdrRg; 
 EEWrData <= EEPrgDataRg;
 EEWr     <= EEWr_Int;
 EEPrgSel <= ProgEnable; -- !!!TBD!!! (Add EESAVE) 
 
-- Flash read 
FlashReadCntAndCtrl:process(cp2)
begin
 if(cp2='1' and cp2'event)  then  -- Clock cp2(Rising edge) 
  -- Edge detectors	 
  FlRdMStartDel <= FlRdMStart;
  FlRdSStartDel <= FlRdSStart; 
  
  -- EEPROM edge detectors
  EEWrStartDel  <= EEWrStart;
  EERdStartDel  <= EERdStart;
  
  -- Delay counter (for read)
  if(TAPCtrlTLR='1') then -- Reset counter
   FlRdCnt <= (others => '0');	  
  elsif((FlRdMStart='0' and FlRdMStartDel='1')or
	    (FlRdSStart='0' and FlRdSStartDel='1')) then 
   FlRdCnt <= "01";
  elsif(FlRdCnt/="00") then 
   FlRdCnt <= FlRdCnt + 1;	  
  end if;	  
  
  if(FlRdCnt="11") then 
   FlRd_St <= '1';
  else 
   FlRd_St <= '0';
  end if; 

  if(FlRd_St='1') then -- Latch read data
   FlPrgRdData <= pm_dout;
  end if;
  
  -- EEPROM Read delay counter
  if(TAPCtrlTLR='1') then -- Reset counter
   EERdCnt <= (others => '0');	  
  elsif(EERdStart='0' and EERdStartDel='1') then -- Falling edge
   EERdCnt <= "01";
  elsif(EERdCnt/="00") then 
   EERdCnt <= EERdCnt + 1;	  
  end if;	  
  
  -- EEPROM Write delay counter
  if(TAPCtrlTLR='1') then -- Reset counter
   EEWrCnt <= (others => '0');	  
  elsif(EEWrStart='0' and EEWrStartDel='1') then -- Falling edge
   EEWrCnt <= "01";
  elsif(EEWrCnt/="00") then 
   EEWrCnt <= EEWrCnt + 1;	  
  end if;	  
  
  -- EEPROM Read latch
  if(EERd_St='1') then  
   EEPrgRdData <= EERdData;
  end if;
  
 end if;	 
end process;  


-- Chip Erase
ChipEraseState:process(cp2)
begin
 if(cp2='1' and cp2'event)  then  -- Clock cp2(Rising edge)	
  ChipEraseStartDel <= ChipEraseStart; -- Edge detector	
	 
  if (TAPCtrlTLR='1') then        -- Reset
	ChipErase_St <= '0'; 
  else
   case	ChipErase_St is
    when '0' => 
	 if(ChipEraseStart='1' and ChipEraseStartDel='0') then -- Start of chip erase
	   ChipErase_St <= '1';
	 end if;  
	when '1' =>
	 if (FlashPrgAdrRg=C_MaxEraseAdr) then
	  ChipErase_St <= '0';
	 end if; 
	when others => null;
   end case;	
  end if;
 end if;
end process;

-- !!!TBD!!!
ChipEraseDone <=  not ChipErase_St;

-- *************************** End of programmer part *******************************

pm_adr <= FlashPrgAdrRg when (ProgEnable='1') else -- Programming Mode
	      PC;                                      -- Normal Operations 

end RTL;
