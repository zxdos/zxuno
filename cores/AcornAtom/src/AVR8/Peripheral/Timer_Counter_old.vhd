--**********************************************************************************************
-- Timers/Counters Block Peripheral for the AVR Core
-- Version 1.37? (Special version for the JTAG OCD)
-- Modified 11.06.2004
-- Synchronizer for EXT1/EXT2 inputs was added
-- Designed by Ruslan Lepetenok
-- Note : Only T/C0 and T/C2 are implemented
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.AVRuCPackage.all;

entity Timer_Counter is port(
	                         -- AVR Control
                             ireset         : in  std_logic;
                             cp2	        : in  std_logic;
							 cp2en          : in  std_logic;
							 tmr_cp2en      : in  std_logic;
							 stopped_mode   : in  std_logic; -- ??
						     tmr_running    : in  std_logic; -- ??
                             adr            : in  std_logic_vector(15 downto 0);
                             dbus_in        : in  std_logic_vector(7 downto 0);
                             dbus_out       : out std_logic_vector(7 downto 0);
                             iore           : in  std_logic;
                             iowe           : in  std_logic;
                             out_en         : out std_logic; 
                             -- External inputs/outputs
                             EXT1           : in  std_logic;
                             EXT2           : in  std_logic;
			                 OC0_PWM0       : out std_logic;
			                 OC1A_PWM1A     : out std_logic;
			                 OC1B_PWM1B     : out std_logic;
			                 OC2_PWM2       : out std_logic;
			                 -- Interrupt related signals
                             TC0OvfIRQ      : out std_logic;
			                 TC0OvfIRQ_Ack  : in  std_logic;
			                 TC0CmpIRQ      : out std_logic;
			                 TC0CmpIRQ_Ack  : in  std_logic;
			                 TC2OvfIRQ      : out std_logic;
			                 TC2OvfIRQ_Ack  : in  std_logic;
			                 TC2CmpIRQ      : out std_logic;
			                 TC2CmpIRQ_Ack  : in  std_logic;
			                 TC1OvfIRQ      : out std_logic;
			                 TC1OvfIRQ_Ack  : in  std_logic;
			                 TC1CmpAIRQ     : out std_logic;
			                 TC1CmpAIRQ_Ack : in  std_logic;
			                 TC1CmpBIRQ     : out std_logic;
			                 TC1CmpBIRQ_Ack : in  std_logic;			   
			                 TC1ICIRQ       : out std_logic;
			                 TC1ICIRQ_Ack   : in  std_logic;
								  
								  --Status bits
								  PWM2bit		  : out std_logic;
								  PWM0bit			: out std_logic;
								  PWM10bit			: out std_logic;
								  PWM11bit			: out std_logic
							 );
end Timer_Counter;

architecture RTL of Timer_Counter is

-- Copies of the external signals
signal OC0_PWM0_Int   :	std_logic;
signal OC2_PWM2_Int   :	std_logic;

-- Registers
signal TCCR0  : std_logic_vector(7 downto 0);
signal TCCR1A : std_logic_vector(7 downto 0);
signal TCCR1B : std_logic_vector(7 downto 0);
signal TCCR2  : std_logic_vector(7 downto 0);
signal ASSR   : std_logic_vector(7 downto 0); -- Asynchronous status register (for TCNT0)
signal TIMSK  : std_logic_vector(7 downto 0);
signal TIFR   : std_logic_vector(7 downto 0);
signal TCNT0  : std_logic_vector(7 downto 0);
signal TCNT2  : std_logic_vector(7 downto 0);
signal OCR0   : std_logic_vector(7 downto 0);
signal OCR2   : std_logic_vector(7 downto 0);
signal TCNT1H : std_logic_vector(7 downto 0);
signal TCNT1L : std_logic_vector(7 downto 0);
signal OCR1AH : std_logic_vector(7 downto 0);
signal OCR1AL : std_logic_vector(7 downto 0);
signal OCR1BH : std_logic_vector(7 downto 0);
signal OCR1BL : std_logic_vector(7 downto 0);
signal ICR1AH : std_logic_vector(7 downto 0);
signal ICR1AL : std_logic_vector(7 downto 0);

  -- TCCR0 Bits
alias CS00  : std_logic is TCCR0(0);
alias CS01  : std_logic is TCCR0(1);
alias CS02  : std_logic is TCCR0(2);
alias CTC0  : std_logic is TCCR0(3);
alias COM00 : std_logic is TCCR0(4);
alias COM01 : std_logic is TCCR0(5);
alias PWM0  : std_logic is TCCR0(6);

  -- TCCR1A Bits
alias PWM10  : std_logic is TCCR1A(0);
alias PWM11  : std_logic is TCCR1A(1);
alias COM1B0 : std_logic is TCCR1A(4);
alias COM1B1 : std_logic is TCCR1A(5);
alias COM1A0 : std_logic is TCCR1A(4);
alias COM1A1 : std_logic is TCCR1A(5);

  -- TCCR1B Bits
alias CS10  : std_logic is TCCR1A(0);
alias CS11  : std_logic is TCCR1A(1);
alias CS12  : std_logic is TCCR1A(2);
alias CTC1  : std_logic is TCCR1A(3);
alias ICES1 : std_logic is TCCR1A(6);
alias ICNC1 : std_logic is TCCR1A(7);

  -- TCCR2 Bits
alias CS20  : std_logic is TCCR2(0);
alias CS21  : std_logic is TCCR2(1);
alias CS22  : std_logic is TCCR2(2);
alias CTC2  : std_logic is TCCR2(3);
alias COM20 : std_logic is TCCR2(4);
alias COM21 : std_logic is TCCR2(5);
alias PWM2  : std_logic is TCCR2(6);

-- ASSR bits
alias TCR0UB  : std_logic is ASSR(0);
alias OCR0UB  : std_logic is ASSR(1);
alias TCN0UB  : std_logic is ASSR(2);
alias AS0     : std_logic is ASSR(3);

-- TIMSK bits
alias TOIE0     : std_logic is TIMSK(0);
alias OCIE0     : std_logic is TIMSK(1);
alias TOIE1     : std_logic is TIMSK(2);
alias OCIE1B    : std_logic is TIMSK(3);
alias OCIE1A    : std_logic is TIMSK(4);
alias TICIE1    : std_logic is TIMSK(5);
alias TOIE2     : std_logic is TIMSK(6);
alias OCIE2     : std_logic is TIMSK(7);

-- TIFR bits
alias TOV0     : std_logic is TIFR(0);
alias OCF0     : std_logic is TIFR(1);
alias TOV1     : std_logic is TIFR(2);
alias OCF1B    : std_logic is TIFR(3);
alias OCF1A    : std_logic is TIFR(4);
alias ICF1     : std_logic is TIFR(5);
alias TOV2     : std_logic is TIFR(6);
alias OCF2     : std_logic is TIFR(7);

-- Prescaler1 signals
signal CK8    : std_logic;
signal CK64   : std_logic;
signal CK256  : std_logic;
signal CK1024 : std_logic;

signal Pre1Cnt : std_logic_vector(9 downto 0); -- Prescaler 1 counter (10-bit)

signal EXT1RE : std_logic; -- Rising edge of external input EXT1 (for TCNT1 only)
signal EXT1FE : std_logic; -- Falling edge of external input EXT1 (for TCNT1 only)

signal EXT2RE : std_logic; -- Rising edge of external input EXT2	(for TCNT2 only)
signal EXT2FE : std_logic; -- Falling edge of external input EXT2 (for TCNT2 only)

-- Risign/falling edge detectors	
signal EXT1Latched : std_logic;	
signal EXT2Latched : std_logic;	

-- Prescalers outputs 
signal TCNT0_En : std_logic; -- Output of the prescaler 0
signal TCNT1_En : std_logic;	-- Output of the prescaler 1
signal TCNT2_En : std_logic;	-- Output of the prescaler 1

-- Prescaler0 signals	
signal PCK08    : std_logic;
signal PCK032   : std_logic;
signal PCK064   : std_logic;
signal PCK0128  : std_logic;
signal PCK0256  : std_logic;
signal PCK01024 : std_logic;

signal Pre0Cnt      : std_logic_vector(9 downto 0); -- Prescaler 0 counter (10-bit)

-- Synchronizer signals
signal EXT1SA  : std_logic;
signal EXT1SB  : std_logic; -- Output of the synchronizer for EXT1
signal EXT2SA  : std_logic;
signal EXT2SB  : std_logic; -- Output of the synchronizer for EXT1

-- Temporary registers
signal OCR0_Tmp : std_logic_vector(OCR0'range);
signal OCR2_Tmp : std_logic_vector(OCR2'range);	

-- Counters control(Inc/Dec)
signal Cnt0Dir  : std_logic; 
signal Cnt2Dir  : std_logic; 

-- 
signal TCNT0WrFl  : std_logic; 
signal TCNT0CmpBl : std_logic; 

signal TCNT2WrFl  : std_logic; 
signal TCNT2CmpBl : std_logic; 

begin
	
-- Synchronizers
SyncDFFs:process(cp2,ireset)	
begin	
 if (ireset='0') then      -- Reset
  EXT1SA <= '0';  
  EXT1SB <= '0';   
  EXT2SA <= '0';   
  EXT2SB <= '0';   
 elsif (cp2='1' and cp2'event) then -- Clock
  if (tmr_cp2en='1') then       -- Clock Enable(Note 2)	 
    EXT1SA <= EXT1;  
    EXT1SB <= EXT1SA;   
    EXT2SA <= EXT2;   
    EXT2SB <= EXT2SA;   
  end if;	 	
 end if;	 
end process;	
	
-- -------------------------------------------------------------------------------------------
-- Prescalers
-- -------------------------------------------------------------------------------------------	
	
-- Prescaler 1 for TCNT1 and TCNT2
Prescaler_1:process(cp2,ireset)
begin
 if  (ireset='0')  then                 -- Reset
  Pre1Cnt <= (others => '0'); 
  CK8 <= '0';
  CK64 <= '0';
  CK256 <= '0';
  CK1024 <= '0';
  EXT1RE <= '0';
  EXT1FE <= '0';
  EXT2RE <= '0';
  EXT2FE <= '0';
  EXT1Latched <= '0';
  EXT2Latched <= '0';
 elsif  (cp2='1' and cp2'event)  then -- Clock
  if (tmr_cp2en='1') then             -- Clock Enable
   Pre1Cnt <= Pre1Cnt+1;
   CK8 <= not CK8 and(Pre1Cnt(0) and Pre1Cnt(1)and Pre1Cnt(2));
   CK64 <= not CK64 and(Pre1Cnt(0) and Pre1Cnt(1) and Pre1Cnt(2) and Pre1Cnt(3) and Pre1Cnt(4) and Pre1Cnt(5));
   CK256 <= not CK256 and(Pre1Cnt(0) and Pre1Cnt(1) and Pre1Cnt(2) and Pre1Cnt(3) and Pre1Cnt(4) and Pre1Cnt(5) and Pre1Cnt(6) and Pre1Cnt(7));
   CK1024 <= not CK1024 and(Pre1Cnt(0) and Pre1Cnt(1) and Pre1Cnt(2) and Pre1Cnt(3) and Pre1Cnt(4) and Pre1Cnt(5) and Pre1Cnt(6) and Pre1Cnt(7) and Pre1Cnt(8) and Pre1Cnt(9));
   EXT1RE <= not EXT1RE and (EXT1SB and not EXT1Latched);
   EXT1FE <= not EXT1FE and (not EXT1SB and EXT1Latched);
   EXT2RE <= not EXT2RE and (EXT2SB and not EXT2Latched);
   EXT2FE <= not EXT2FE and (not EXT2SB and EXT2Latched);
   EXT1Latched <= EXT1SB;
   EXT2Latched <= EXT2SB;
  end if; 
 end if;
end process;		

TCNT1_En <= (not CS12 and not CS11 and CS10) or            -- CK             "001"
            (CK8 and not CS12 and CS11 and not CS10) or    -- CK/8			 "010"
			(CK64 and not CS12 and CS11 and CS10)    or    -- CK/64			 "011"
			(CK256 and CS12 and not CS11 and not CS10) or  -- CK/256		 "100"
            (CK1024 and CS12 and not CS11 and CS10)    or  -- CK/1024		 "101"
			(EXT1FE and CS12 and CS11 and not CS10) or     -- Falling edge	 "110"
            (EXT1RE and CS12 and CS11 and CS10);           -- Rising edge	 "111"
			
TCNT2_En <= (not CS22 and not CS21 and CS20) or            -- CK             "001"
            (CK8 and not CS22 and CS21 and not CS20) or    -- CK/8			 "010"
			(CK64 and not CS22 and CS21 and CS20)    or    -- CK/64			 "011"
			(CK256 and CS22 and not CS21 and not CS20) or  -- CK/256		 "100"
            (CK1024 and CS22 and not CS21 and CS20)    or  -- CK/1024		 "101"
			(EXT2FE and CS22 and CS21 and not CS20) or     -- Falling edge	 "110"
            (EXT2RE and CS22 and CS21 and CS20);           -- Rising edge	 "111"

	
			
Prescaler_0_Cnt:process(cp2,ireset)
begin
 if(ireset='0')  then                 -- Reset
  Pre0Cnt <= (others => '0'); 
 elsif  (cp2='1' and cp2'event)  then -- Clock
  if (tmr_cp2en='1') then             -- Clock Enable(Note 2)	
   Pre0Cnt <= Pre0Cnt+1;
  end if;
 end if; 
end process;					

Prescaler_0:process(cp2,ireset)
begin
 if  (ireset='0')  then                   -- Reset
  PCK08 <= '0';
  PCK032 <= '0';
  PCK064 <= '0';
  PCK0128 <= '0';
  PCK0256 <= '0';
  PCK01024 <= '0';
 elsif  (cp2='1' and cp2'event)  then -- Clock
  if (tmr_cp2en='1') then             -- Clock Enable
   PCK08 <= (not PCK08 and(Pre0Cnt(0) and Pre0Cnt(1)and Pre0Cnt(2)));
   PCK032 <= (not PCK032 and(Pre0Cnt(0) and Pre0Cnt(1) and Pre0Cnt(2) and Pre0Cnt(3) and Pre0Cnt(4))); 
   PCK064 <= (not PCK064 and(Pre0Cnt(0) and Pre0Cnt(1) and Pre0Cnt(2) and Pre0Cnt(3) and Pre0Cnt(4) and Pre0Cnt(5)));
   PCK0128 <= (not PCK0128 and(Pre0Cnt(0) and Pre0Cnt(1) and Pre0Cnt(2) and Pre0Cnt(3) and Pre0Cnt(4) and Pre0Cnt(5) and Pre0Cnt(6)));
   PCK0256 <= (not PCK0256 and(Pre0Cnt(0) and Pre0Cnt(1) and Pre0Cnt(2) and Pre0Cnt(3) and Pre0Cnt(4) and Pre0Cnt(5) and Pre0Cnt(6) and Pre0Cnt(7)));
   PCK01024 <= (not PCK01024 and(Pre0Cnt(0) and Pre0Cnt(1) and Pre0Cnt(2) and Pre0Cnt(3) and Pre0Cnt(4) and Pre0Cnt(5) and Pre0Cnt(6) and Pre0Cnt(7) and Pre0Cnt(8) and Pre0Cnt(9))); 
  end if; 
 end if;
end process;					


TCNT0_En <= (not CS02 and not CS01 and CS00) or              -- PCK            "001" 
            (PCK08 and not CS02 and CS01 and not CS00) or    -- PCK/8		   "010"
			(PCK032 and not CS02 and CS01 and CS00)or	     -- PCK/32		   "011"
			(PCK064 and CS02 and not CS01 and not CS00)or    -- PCK/64		   "100"
			(PCK0128 and CS02 and not CS01 and CS00)or       -- PCK/64		   "101"
			(PCK0256 and CS02 and CS01 and not CS00)or       -- PCK/256		   "110"
            (PCK01024 and CS02 and CS01 and CS00);           -- PCK/1024	   "111"

-- -------------------------------------------------------------------------------------------
-- End of prescalers
-- -------------------------------------------------------------------------------------------


-- -------------------------------------------------------------------------------------------
-- Timer/Counter 0 
-- -------------------------------------------------------------------------------------------

TimerCounter0Cnt:process(cp2,ireset)
begin
 if (ireset='0') then                    -- Reset
  TCNT0 <= (others => '0'); 
 elsif  (cp2='1' and cp2'event)  then    -- Clock
  if(adr=TCNT0_Address and iowe='1' and cp2en='1') then  -- Write to TCNT0
   TCNT0 <= dbus_in;	  
  elsif(tmr_cp2en='1') then
   case PWM0 is 
	when '0' =>           -- Non-PWM mode  
	 if(CTC0='1' and TCNT0=OCR0) then  -- Clear T/C on compare match
	  TCNT0 <= (others => '0');
	 elsif(TCNT0_En='1') then
	  TCNT0 <= TCNT0 + 1; -- Increment TCNT0	  
	 end if;
	when '1' =>           -- PWM mode  
	 if(TCNT0_En='1') then
	   case Cnt0Dir is
		when '0' =>        -- Counts up
		 if(TCNT0=x"FF") then
		  TCNT0<=x"FE";
		 else 
	      TCNT0 <= TCNT0 + 1; -- Increment TCNT0 (0 to FF)
		 end if;
		when '1' =>        -- Counts down
		 if(TCNT0=x"00") then
		  TCNT0 <= x"01";
		 else 
	      TCNT0 <= TCNT0 - 1; -- Decrement TCNT0 (FF to 0)	  
		 end if;
        when others => null;
       end case;	
     end if;
	when others => null;
   end case;
   
  end if;	  
 end if;
end process;				


Cnt0DirectionControl:process(cp2,ireset)
begin
 if (ireset='0')  then                   -- Reset
  Cnt0Dir <= '0';
 elsif (cp2='1' and cp2'event)  then     -- Clock
  if(tmr_cp2en='1') then  				 -- Clock enable
   if(TCNT0_En='1') then
    if (PWM0='1') then   
     case Cnt0Dir is
	  when '0' => 
	   if(TCNT0=x"FF") then
	    Cnt0Dir <= '1';
	   end if; 
      when '1' => 
	   if(TCNT0=x"00") then
	    Cnt0Dir <= '0';
	   end if; 
	  when others => null;
     end case;
    end if;
   end if;
  end if;
 end if;
end process;				


TCnt0OutputControl:process(cp2,ireset)
begin
 if (ireset='0')  then                    -- Reset
  OC0_PWM0_Int <= '0';
 elsif  (cp2='1' and cp2'event)  then     -- Clock
  if(tmr_cp2en='1') then                  -- Clock enable
   if(TCNT0_En='1') then
	   
    case PWM0 is
     when '0' =>	     --  Non PWM Mode
	  if(TCNT0=OCR0 and TCNT0CmpBl='0') then
	   if(COM01='0' and COM00='1') then -- Toggle	 
	    OC0_PWM0_Int <= not OC0_PWM0_Int;	 
	   end if; 
	  end if; 
     when '1' =>	     --  PWM Mode	   
	  case TCCR0(5 downto 4) is -- -> COM01&COM00
	   when "10" =>      -- Non-inverted PWM  
	    if(TCNT0=x"FF") then  -- Update OCR0
		 if (OCR0_Tmp=x"00") then 
		  OC0_PWM0_Int <= '0'; -- Clear
		 elsif (OCR0_Tmp=x"FF") then
		  OC0_PWM0_Int <= '1'; -- Set
		 end if; 
	    elsif(TCNT0=OCR0 and OCR0/=x"00") then
         if(Cnt0Dir='0') then  -- Up-counting 
		  OC0_PWM0_Int <= '0'; -- Clear			 
		 else 				   -- Down-counting
          OC0_PWM0_Int <= '1'; -- Set		 			
		 end if;
		end if;
	   when "11" =>      -- Inverted PWM  
	    if(TCNT0=x"FF") then  -- Update OCR0
		 if (OCR0_Tmp=x"00") then 
		  OC0_PWM0_Int <= '1'; -- Set
		 elsif (OCR0_Tmp=x"FF") then
		  OC0_PWM0_Int <= '0'; -- Clear
		 end if; 
	    elsif(TCNT0=OCR0 and OCR0/=x"00") then
         if(Cnt0Dir='0') then  -- Up-counting 
		  OC0_PWM0_Int <= '1'; -- Set 			 
		 else 				   -- Down-counting
          OC0_PWM0_Int <= '0'; -- Clear 		 			
		 end if;
	    end if;
	   when others => null;
	  end case; 
	   
     when others =>	null;     	   	  
    end case;
   
   end if;	  	
  end if;	  
 end if;
end process;				


OC0_PWM0 <= OC0_PWM0_Int;

TCnt0_TIFR_Bits:process(cp2,ireset)
begin
 if (ireset='0') then -- Reset
  TOV0 <= '0';
  OCF0 <= '0';
 elsif  (cp2='1' and cp2'event)  then -- Clock	
	 
  -- TOV0
  if(stopped_mode='1' and tmr_running='0' and cp2en='1') then -- !!!Special mode!!!
   if(adr=TIFR_Address and iowe='1') then	 
	TOV0 <= dbus_in(0); -- !!!
   end if;
  else 
   case TOV0 is
    when '0' => 
     if (tmr_cp2en='1' and TCNT0_En='1') then
	  if (PWM0='0') then   -- Non PWM Mode
	   if (TCNT0=x"FF") then
	    TOV0 <= '1';  	 
	   end if;
	  else                 -- PWM Mode 
	   if(TCNT0=x"00") then  	 
	    TOV0 <= '1';  	 
	   end if;
	  end if; 
     end if;
    when '1' => 
     if((TC0OvfIRQ_Ack='1' or (adr=TIFR_Address and iowe='1' and dbus_in(0)='1')) and cp2en='1') then -- Clear TOV0 flag
      TOV0 <= '0';
     end if; 
    when others => null;
   end case; 
  end if;
  
  -- OCF0
  if(stopped_mode='1' and tmr_running='0' and cp2en='1') then -- !!!Special mode!!!
   if(adr=TIFR_Address and iowe='1') then	 
	OCF0 <= dbus_in(1); -- !!!
   end if;
  else 
   case OCF0 is
    when '0' => 
	 if (tmr_cp2en='1' and TCNT0_En='1') then 
	  if (TCNT0=OCR0 and TCNT0CmpBl='0') then
	   OCF0 <= '1';  
	  end if;
	 end if; 
    when '1' => 
     if((TC0CmpIRQ_Ack='1' or (adr=TIFR_Address and iowe='1' and dbus_in(1)='1')) and cp2en='1') then -- Clear OCF2 flag
      OCF0 <= '0';
     end if; 
    when others => null;
   end case; 
  end if;
  
 end if;	
end process;


TCCR0(7) <= '0';

TCCR0_Reg:process(cp2,ireset)
begin
 if (ireset='0')  then                          -- Reset
  TCCR0(6 downto 0) <= (others => '0'); 
 elsif (cp2='1' and cp2'event)  then            -- Clock
  if (cp2en='1') then                           -- Clock Enable	
   if (adr=TCCR0_Address and iowe='1') then              
	TCCR0(6 downto 0) <= dbus_in(6 downto 0);
   end if;
  end if;
 end if;
end process;	

OCR0_Write:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  OCR0 <= (others => '0');
 elsif (cp2='1' and cp2'event)  then        -- Clock
  case PWM0 is 
   when '0' =>                              -- Non-PWM mode
    if (adr=OCR0_Address and iowe='1' and cp2en='1') then  -- Load data from the data bus
	 OCR0 <= dbus_in;
    end if;
   when '1' => 								-- PWM mode
    if(TCNT0=x"FF" and tmr_cp2en='1' and TCNT0_En='1') then  -- Load data from the temporary register
	 OCR0 <= OCR0_Tmp;  
    end if;
   when others => null;
  end case;
 end if;
end process;			


OCR0_Tmp_Write:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  OCR0_Tmp <= (others => '0');
 elsif (cp2='1' and cp2'event)  then        -- Clock
  if (cp2en='1') then 	 
   if (adr=OCR0_Address and iowe='1') then  -- Load data from the data bus
    OCR0_Tmp <= dbus_in;
   end if;
  end if;
 end if;
end process;			

-- 

TCNT0WriteControl:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  TCNT0WrFl <= '0';
 elsif (cp2='1' and cp2'event)  then        -- Clock
  if (cp2en='1') then 
    case TCNT0WrFl is
 	 when '0' =>
	  if (adr=TCNT0_Address and iowe='1' and TCNT0_En='0') then  -- Load data from the data bus 
	   TCNT0WrFl <= '1';
	  end if;
	 when '1' =>
	  if(TCNT0_En='0') then 
	   TCNT0WrFl <= '0';
	  end if; 	  
	 when others => null;
	end case; 	
  end if;
 end if;
end process;			

-- Operations on compare match(OCF0 and Toggling) disabled for TCNT0
TCNT0CmpBl <= '1' when (TCNT0WrFl='1' or (adr=TCNT0_Address and iowe='1')) else 
	          '0'; 


-- -------------------------------------------------------------------------------------------
-- Timer/Counter 2
-- -------------------------------------------------------------------------------------------

TimerCounter2Cnt:process(cp2,ireset)
begin
 if (ireset='0') then                    -- Reset
  TCNT2 <= (others => '0'); 
 elsif  (cp2='1' and cp2'event)  then    -- Clock
  if(adr=TCNT2_Address and iowe='1' and cp2en='1') then  -- Write to TCNT2
   TCNT2 <= dbus_in;	  
  elsif(tmr_cp2en='1') then
   case PWM2 is 
	when '0' =>           -- Non-PWM mode  
	 if(CTC2='1' and TCNT2=OCR2) then  -- Clear T/C on compare match
	  TCNT2 <= (others => '0');
	 elsif(TCNT2_En='1') then
	  TCNT2 <= TCNT2 + 1; -- Increment TCNT2
	 end if;
	when '1' =>           -- PWM mode  
	 if(TCNT2_En='1') then
	   case Cnt2Dir is
		when '0' =>        -- Counts up
		 if(TCNT2=x"FF") then
		  TCNT2 <= x"FE";
		 else 
	      TCNT2 <= TCNT2 + 1; -- Increment TCNT2 (0 to FF)
		 end if;
		when '1' =>        -- Counts down
		 if(TCNT2=x"00") then
		  TCNT2 <= x"01";
		 else 
	      TCNT2 <= TCNT2 - 1; -- Decrement TCNT0 (FF to 0)	  
		 end if;
        when others => null;
       end case;	
     end if;
	when others => null;
   end case;
   
  end if;	  
 end if;
end process;				


Cnt2DirectionControl:process(cp2,ireset)
begin
 if (ireset='0')  then                   -- Reset
  Cnt2Dir <= '0';
 elsif (cp2='1' and cp2'event)  then     -- Clock
  if(tmr_cp2en='1') then  				 -- Clock enable
   if(TCNT2_En='1') then
    if (PWM2='1') then   
     case Cnt2Dir is
	  when '0' => 
	   if(TCNT2=x"FF") then
	    Cnt2Dir <= '1';
	   end if; 
      when '1' => 
	   if(TCNT2=x"00") then
	    Cnt2Dir <= '0';
	   end if; 
	  when others => null;
     end case;
    end if;
   end if;
  end if;
 end if;
end process;				


TCnt2OutputControl:process(cp2,ireset)
begin
 if (ireset='0')  then                    -- Reset
  OC2_PWM2_Int <= '0';
 elsif  (cp2='1' and cp2'event)  then     -- Clock
  if(tmr_cp2en='1') then                  -- Clock enable
   if(TCNT2_En='1') then
	   
    case PWM2 is
     when '0' =>	     --  Non PWM Mode
	  if(TCNT2=OCR2 and TCNT2CmpBl='0') then
	   if(COM21='0' and COM20='1') then -- Toggle	 
	    OC2_PWM2_Int <= not OC2_PWM2_Int;	 
	   end if; 
	  end if; 
     when '1' =>	     --  PWM Mode	   
	  case TCCR2(5 downto 4) is -- -> COM21&COM20
	   when "10" =>      -- Non-inverted PWM  
	    if(TCNT2=x"FF") then  -- Update OCR2
		 if (OCR2_Tmp=x"00") then 
		  OC2_PWM2_Int <= '0'; -- Clear
		 elsif (OCR2_Tmp=x"FF") then
		  OC2_PWM2_Int <= '1'; -- Set
		 end if; 
	    elsif(TCNT2=OCR2 and OCR2/=x"00") then
         if(Cnt2Dir='0') then  -- Up-counting 
		  OC2_PWM2_Int <= '0'; -- Clear			 
		 else 				   -- Down-counting
          OC2_PWM2_Int <= '1'; -- Set		 			
		 end if;
		end if;
	   when "11" =>      -- Inverted PWM  
	    if(TCNT2=x"FF") then  -- Update OCR2
		 if (OCR2_Tmp=x"00") then 
		  OC2_PWM2_Int <= '1'; -- Set
		 elsif (OCR2_Tmp=x"FF") then
		  OC2_PWM2_Int <= '0'; -- Clear
		 end if; 
	    elsif(TCNT2=OCR2 and OCR2/=x"00") then
         if(Cnt2Dir='0') then  -- Up-counting 
		  OC2_PWM2_Int <= '1'; -- Set 			 
		 else 				   -- Down-counting
          OC2_PWM2_Int <= '0'; -- Clear 		 			
		 end if;
	    end if;
	   when others => null;
	  end case; 
	   
     when others =>	null;     	   	  
    end case;
   
   end if;	  	
  end if;	  
 end if;
end process;				


OC2_PWM2 <= OC2_PWM2_Int;

TCnt2_TIFR_Bits:process(cp2,ireset)
begin
 if (ireset='0') then -- Reset
  TOV2 <= '0';
  OCF2 <= '0';
 elsif  (cp2='1' and cp2'event)  then -- Clock	
	 
  -- TOV2
  if(stopped_mode='1' and tmr_running='0' and cp2en='1') then -- !!!Special mode!!!
   if(adr=TIFR_Address and iowe='1') then	 
	TOV2 <= dbus_in(6); -- !!!
   end if;
  else 
   case TOV2 is
    when '0' => 
     if (tmr_cp2en='1' and TCNT2_En='1') then
	  if (PWM2='0') then   -- Non PWM Mode
	   if (TCNT2=x"FF") then
	    TOV2 <= '1';  	 
	   end if;
	  else                 -- PWM Mode 
	   if(TCNT2=x"00") then  	 
	    TOV2 <= '1';  	 
	   end if;
	  end if; 
     end if;
    when '1' => 
     if((TC2OvfIRQ_Ack='1' or (adr=TIFR_Address and iowe='1' and dbus_in(6)='1')) and cp2en='1') then -- Clear TOV2 flag
      TOV2 <= '0';
     end if; 
    when others => null;
   end case; 
  end if;
  
  -- OCF2
  if(stopped_mode='1' and tmr_running='0' and cp2en='1') then -- !!!Special mode!!!
   if(adr=TIFR_Address and iowe='1') then	 
	OCF2 <= dbus_in(7); -- !!!
   end if;
  else 
   case OCF2 is
    when '0' => 
	 if (tmr_cp2en='1' and TCNT2_En='1') then 
	  if (TCNT2=OCR2 and TCNT2CmpBl='0') then
	   OCF2 <= '1';  
	  end if;
	 end if; 
    when '1' => 
     if((TC2CmpIRQ_Ack='1' or (adr=TIFR_Address and iowe='1' and dbus_in(7)='1')) and cp2en='1') then -- Clear OCF2 flag
      OCF2 <= '0';
     end if; 
    when others => null;
   end case; 
  end if;
  
 end if;	
end process;


TCCR2(7) <= '0';

TCCR2_Reg:process(cp2,ireset)
begin
 if (ireset='0')  then                          -- Reset
  TCCR2(6 downto 0) <= (others => '0'); 
 elsif (cp2='1' and cp2'event)  then            -- Clock
  if (cp2en='1') then                           -- Clock Enable	
   if (adr=TCCR2_Address and iowe='1') then              
	TCCR2(6 downto 0) <= dbus_in(6 downto 0);
   end if;
  end if;
 end if;
end process;	

OCR2_Write:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  OCR2 <= (others => '0');
 elsif (cp2='1' and cp2'event)  then        -- Clock
  case PWM2 is 
   when '0' =>                              -- Non-PWM mode
    if (adr=OCR2_Address and iowe='1' and cp2en='1') then  -- Load data from the data bus
	 OCR2 <= dbus_in;
    end if;
   when '1' => 								-- PWM mode
    if(TCNT2=x"FF" and tmr_cp2en='1' and TCNT2_En='1') then  -- Load data from the temporary register
	 OCR2 <= OCR2_Tmp;  
    end if;
   when others => null;
  end case;
 end if;
end process;			


OCR2_Tmp_Write:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  OCR2_Tmp <= (others => '0');
 elsif (cp2='1' and cp2'event)  then        -- Clock
  if (cp2en='1') then 	 
   if (adr=OCR2_Address and iowe='1') then  -- Load data from the data bus
    OCR2_Tmp <= dbus_in;
   end if;
  end if;
 end if;
end process;			

-- 

TCNT2WriteControl:process(cp2,ireset)
begin
 if (ireset='0')  then                      -- Reset
  TCNT2WrFl <= '0';
 elsif (cp2='1' and cp2'event)  then        -- Clock
  if (cp2en='1') then 
    case TCNT2WrFl is
 	 when '0' =>
	  if (adr=TCNT2_Address and iowe='1' and TCNT2_En='0') then  -- Load data from the data bus 
	   TCNT2WrFl <= '1';
	  end if;
	 when '1' =>
	  if(TCNT2_En='0') then 
	   TCNT2WrFl <= '0';
	  end if; 	  
	 when others => null;
	end case; 	
  end if;
 end if;
end process;			

-- Operations on compare match(OCF2 and Toggling) disabled for TCNT2
TCNT2CmpBl <= '1' when (TCNT2WrFl='1' or (adr=TCNT2_Address and iowe='1')) else 
	          '0'; 

	
-- -------------------------------------------------------------------------------------------
-- Common (Control/Interrupt) bits
-- ------------------------------------------------------------------------------------------- 

TIMSK_Bits:process(cp2,ireset)
begin
 if (ireset='0') then 
  TIMSK <= (others => '0');
 elsif  (cp2='1' and cp2'event)  then
  if (cp2en='1') then       -- Clock Enable	
   if (adr=TIMSK_Address and iowe='1') then
    TIMSK <= dbus_in;	
   end if;
  end if;	 
 end if;	
end process;


-- Interrupt flags of Timer/Counter0
TC0OvfIRQ <= TOV0 and TOIE0;	  -- Interrupt on overflow of TCNT0
TC0CmpIRQ <= OCF0 and OCIE0;	  -- Interrupt on compare match	of TCNT0

-- Interrupt flags of Timer/Counter0
TC2OvfIRQ <= TOV2 and TOIE2;	  -- Interrupt on overflow of TCNT2
TC2CmpIRQ <= OCF2 and OCIE2;	  -- Interrupt on compare match	of TCNT2

-- Unused interrupt requests(for T/C1)
TC1OvfIRQ  <= TOV1 and TOIE1;
TC1CmpAIRQ <= OCF1A and OCIE1A;
TC1CmpBIRQ <= OCF1B and OCIE1B;
TC1ICIRQ   <= ICF1 and TICIE1;

-- Unused TIFR flags(for T/C1)
TOV1  <= '0';
OCF1A <= '0';	
OCF1B <= '0';
ICF1  <= '0';

-- -------------------------------------------------------------------------------------------
-- End of common (Control/Interrupt) bits
-- -------------------------------------------------------------------------------------------

-- -------------------------------------------------------------------------------------------
-- Bus interface
-- -------------------------------------------------------------------------------------------

out_en <= '1' when ((adr=TCCR0_Address or 
                     adr=TCCR1A_Address or 
                     adr=TCCR1B_Address or
                     adr=TCCR2_Address or
                     adr=ASSR_Address or
                     adr=TIMSK_Address or						 
                     adr=TIFR_Address or
                     adr=TCNT0_Address or
                     adr=TCNT2_Address or
                     adr=OCR0_Address or
                     adr=OCR2_Address or
                     adr=TCNT1H_Address	or
                     adr=TCNT1L_Address	or
                     adr=OCR1AH_Address	or
                     adr=OCR1AL_Address	or
                     adr=OCR1BH_Address	or
                     adr=OCR1BL_Address	or 
                     adr=ICR1AH_Address	or
                     adr=ICR1AL_Address) and iore='1') else '0';  

-- Output multilexer
						 
--Output_Mux:process(adr,TCCR0,OCR0,OCR0_Tmp,TCNT0,TCCR2,OCR2,OCR2_Tmp,TCNT2,TIFR,TIMSK) -- Combinatorial
--begin		  
-- case adr is 
--  when TCCR0_Address => dbus_out <= TCCR0;
--  when OCR0_Address => 
--   if (PWM0='0') then
--	dbus_out <= OCR0;
--   else
--	dbus_out <= OCR0_Tmp;
--   end if;	
--  when TCNT0_Address => dbus_out <= TCNT0;
--  when TCCR2_Address => dbus_out <= TCCR2;
--  when OCR2_Address =>    
--   if (PWM2='0') then
--	dbus_out <= OCR2;
--   else
--	dbus_out <= OCR2_Tmp;
--   end if;	
--  when TCNT2_Address => dbus_out <= TCNT2;
--  when TIFR_Address => dbus_out <= TIFR;
--  when TIMSK_Address => dbus_out <= TIMSK;
--  when others => dbus_out <= (others => '0'); 
-- end case; 
--end process;		  

PWM0bit <= PWM0;
PWM10bit <= PWM10;
PWM11bit <= PWM11;
PWM2bit <= PWM2;

-- Synopsys version
dbus_out <= TCCR0 when (adr=TCCR0_Address) else 
			OCR0 when (adr=OCR0_Address and PWM0='0') else -- Non PWM mode of T/C0
            OCR0_Tmp when (adr=OCR0_Address and PWM0='1') else -- PWM mode of T/C0
			TCNT0 when (adr=TCNT0_Address) else 
            TCCR2 when (adr=TCCR2_Address) else 
			OCR2 when (adr=OCR2_Address and PWM2='0') else -- Non PWM mode of T/C2
            OCR2_Tmp when (adr=OCR2_Address and PWM2='1') else -- PWM mode of T/C2
			TCNT2 when (adr=TCNT2_Address) else 
			TIFR when (adr=TIFR_Address) else 	
			TIMSK when (adr=TIMSK_Address) else	
			(others => '0');	
			
-- -------------------------------------------------------------------------------------------
-- End of bus interface
-- -------------------------------------------------------------------------------------------

end RTL;
