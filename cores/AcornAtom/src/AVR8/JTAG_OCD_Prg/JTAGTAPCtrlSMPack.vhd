--**********************************************************************************************
-- JTAG TAP controller SM 
-- Version 0.2
-- Modified 14.06.2006
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package JTAGTAPCtrlSMPack is

type TAPCtrlState_Type is (TestLogicReset,RunTestIdle,
                           SelectDRScan,CaptureDR,ShiftDR,Exit1DR,PauseDR,Exit2DR,UpdateDR,
						   SelectIRScan,CaptureIR,ShiftIR,Exit1IR,PauseIR,Exit2IR,UpdateIR);

function FnTAPNextState(CurrentTAPState : TAPCtrlState_Type; TMS : std_logic) return TAPCtrlState_Type;
function FnJTAGRgSh (ShRg : std_logic_vector ; DataIn : std_logic) return std_logic_vector;

end JTAGTAPCtrlSMPack;

package	body JTAGTAPCtrlSMPack is

function FnTAPNextState(CurrentTAPState : TAPCtrlState_Type; TMS : std_logic) return TAPCtrlState_Type is
variable NextTAPState : TAPCtrlState_Type;
begin

case CurrentTAPState is 
 
 when TestLogicReset => 
  if (TMS='0') then NextTAPState := RunTestIdle;
   else NextTAPState := TestLogicReset;  
  end if;

 when RunTestIdle =>
  if (TMS='1') then NextTAPState := SelectDRScan; 
    else NextTAPState := RunTestIdle;  
  end if;

-- Data register     
 when SelectDRScan =>
  if (TMS='1') then NextTAPState := SelectIRScan; 
   else NextTAPState := CaptureDR;  
  end if;
  
 when CaptureDR =>
  if (TMS='1') then NextTAPState := Exit1DR; 
   else NextTAPState := ShiftDR;  
  end if;
  
 when ShiftDR =>
  if (TMS='1') then NextTAPState := Exit1DR; 
   else NextTAPState := ShiftDR;  
  end if; 
  
 when Exit1DR =>
  if (TMS='1') then NextTAPState := UpdateDR; 
   else NextTAPState := PauseDR;  
  end if; 
 
 when PauseDR =>
  if (TMS='1') then NextTAPState := Exit2DR; 
   else NextTAPState := PauseDR;  
  end if;  
 
 when Exit2DR => 
  if (TMS='1') then NextTAPState := UpdateDR; 
   else NextTAPState := ShiftDR;  
  end if;  
 
 when UpdateDR =>
  if (TMS='1') then NextTAPState := SelectDRScan; 
   else NextTAPState := RunTestIdle;  
  end if;   
 
-- Instruction register   
 when SelectIRScan =>
  if (TMS='1') then NextTAPState := TestLogicReset; 
   else NextTAPState := CaptureIR;  
  end if;
  
 when CaptureIR =>
   if (TMS='1') then NextTAPState := Exit1IR; 
    else NextTAPState := ShiftIR;  
  end if;
 
 when ShiftIR => 
  if (TMS='1') then NextTAPState := Exit1IR; 
   else NextTAPState := ShiftIR;  
  end if;  
 
 when Exit1IR =>
  if (TMS='1') then NextTAPState := UpdateIR; 
   else NextTAPState := PauseIR;  
  end if; 
 
 when PauseIR =>
  if (TMS='1') then NextTAPState := Exit2IR; 
   else NextTAPState := PauseIR;  
  end if;  
  
 when Exit2IR =>
  if (TMS='1') then NextTAPState := UpdateIR; 
   else NextTAPState := ShiftIR;  
  end if;  
 
 when UpdateIR =>
 if (TMS='1') then NextTAPState := SelectDRScan; 
  else NextTAPState := RunTestIdle;  
 end if;   
 
 when others => NextTAPState := TestLogicReset;  

end case;	

return NextTAPState;
	
end FnTAPNextState; -- End of funcrtion	

function FnJTAGRgSh (ShRg : std_logic_vector ; DataIn : std_logic) return std_logic_vector is
variable TmpVector : std_logic_vector(ShRg'range);
begin
 TmpVector := DataIn&ShRg(ShRg'high downto ShRg'low+1);	
return TmpVector;	
end FnJTAGRgSh;	-- End of function

end JTAGTAPCtrlSMPack;







