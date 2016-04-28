--**********************************************************************************************
-- Reset generator for the AVR Core
-- Version 0.7
-- Modified 23.07.2003
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.SynthCtrlPack.all;

entity ResetGenerator is port(
	                            -- Clock inputs
								cp2	       : in  std_logic;
								cp64m	   : in  std_logic;
								-- Reset inputs
	                            nrst       : in  std_logic;
								npwrrst    : in  std_logic;
								wdovf      : in  std_logic;
			                    jtagrst    : in  std_logic;
      							-- Reset outputs
					            nrst_cp2   : out std_logic;
			                    nrst_cp64m : out std_logic;
								nrst_clksw : out std_logic
								);
end ResetGenerator;

architecture RTL of ResetGenerator is

signal cp2RstA   : std_logic;
signal cp2RstB   : std_logic;
signal cp2RstC   : std_logic;

signal cp64mRstA : std_logic;
signal cp64mRstB : std_logic;

signal nrst_ResyncA   : std_logic;
signal nrst_ResyncB   : std_logic;

signal ClrRstDFF : std_logic;
signal ClrRstDFF_Tmp : std_logic;

signal RstDelayA : std_logic;
signal RstDelayB : std_logic;

begin

nrst_Resync_DFFs:process(cp2)
begin
 if cp2='1' and cp2'event then -- Clock
  nrst_ResyncA <= nrst;
  nrst_ResyncB <= nrst_ResyncA;
 end if;	
end process;		
	
ResetDFF:process(cp2)
begin
 if cp2='1' and cp2'event then -- Clock
  if wdovf='1' or jtagrst='1' or nrst_ResyncB='0' or npwrrst='0' then
   ClrRstDFF_Tmp <= '0'; -- Reset
  else 
   ClrRstDFF_Tmp <= '1'; -- Normal state
  end if;	
 end if;	
end process;	

ClrRstDFF <= ClrRstDFF_Tmp; -- !!!TBD!!! GLOBAL primitive may be used !!!

-- High speed clock domain reset(if exists)
SecondClock:if CSecondClockUsed generate 
Reset_cp64m_DFFs:process(ClrRstDFF,cp64m)
begin
 if ClrRstDFF='0' then -- Reset
  cp64mRstA <= '0';
  cp64mRstB <= '0'; 
 elsif cp64m='1' and cp64m'event then -- Clock
  cp64mRstA <= '1';
  cp64mRstB <= cp64mRstA; 
 end if;	
end process;

-- Reset signal for 64 MHz clock domain
nrst_cp64m <= cp64mRstB;

end generate;

-- High speed clock domain doesn't exist
NoSecondClock:if not CSecondClockUsed generate 
 cp64mRstB <= '1';
 nrst_cp64m <= '0';
end generate;

-- Low speed clock domain reset
Reset_cp2_DFFs:process(ClrRstDFF,cp2)
begin
if ClrRstDFF='0' then -- Reset
 cp2RstA <= '0';
 cp2RstB <= '0';
 cp2RstC <= '0'; 
elsif cp2='1' and cp2'event then -- Clock
-- cp2RstA <= cp64mRstB;
 cp2RstA <= RstDelayB;
 cp2RstB <= cp2RstA; 
 cp2RstC <= cp2RstB; 
end if;	
end process;

-- Reset delay line
Reset_Delay_DFFs:process(ClrRstDFF,cp2)
begin
if ClrRstDFF='0' then -- Reset
 RstDelayA <= '0';
 RstDelayB <= '0';
elsif cp2='1' and cp2'event then -- Clock
 RstDelayA <= cp64mRstB;
 RstDelayB <= RstDelayA;
end if;	
end process;

-- Reset signal for cp2 clock domain
nrst_cp2 <= cp2RstC;

-- Separate reset for clock enable module
nrst_clksw <= RstDelayB;

end RTL;
