--**********************************************************************************************
-- UART Peripheral for the AVR Core
-- Version 1.5 "Original" (Mega103) version
-- Modified 14.06.2006
-- Designed by Ruslan Lepetenok
-- UDRE bug found
-- Transmitter bug (for 9 bit transmission) was found 
-- Bug in UART_RcDel_St state machine was fixed
-- Bug in UART_RcDel_St state machine was fixed(2) (!!!simulation only!!!)
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.AVRuCPackage.all;

entity uart is port(
	                -- AVR Control
                    ireset     : in  std_logic;
                    cp2	       : in  std_logic;
                    adr        : in  std_logic_vector(15 downto 0);
                    dbus_in    : in  std_logic_vector(7 downto 0);
                    dbus_out   : out std_logic_vector(7 downto 0);
                    iore       : in  std_logic;
                    iowe       : in  std_logic;
                    out_en     : out std_logic; 
                    -- External connection
                    rxd        : in  std_logic;
                    rx_en      : out std_logic;
                    txd        : out std_logic;
                    tx_en      : out std_logic;
                    -- IRQ
                    txcirq     : out std_logic;
                    txc_irqack : in  std_logic;
                    udreirq    : out std_logic;
			        rxcirq     : out std_logic
					);
end uart;

architecture RTL of uart is

signal UDR_Tx          : std_logic_vector(7 downto 0);
signal UDR_Rx          : std_logic_vector(7 downto 0);
signal UBRR	           : std_logic_vector(7 downto 0);
-- USR Bits
signal USR	           : std_logic_vector(7 downto 0);
signal USR_Wr_En       : std_logic;
alias RXC              : std_logic is USR(7);
alias TXC              : std_logic is USR(6);
alias UDRE             : std_logic is USR(5);
alias FE               : std_logic is USR(4);
alias DOR              : std_logic is USR(3); -- OR in Atmel documents

-- UCR Bits
signal UCR	           : std_logic_vector(7 downto 0);
signal UCR_Wr_En       : std_logic;
alias RXCIE            : std_logic is UCR(7);
alias TXCIE            : std_logic is UCR(6);
alias UDRIE            : std_logic is UCR(5);
alias RXEN             : std_logic is UCR(4);
alias TXEN             : std_logic is UCR(3);
alias CHR9             : std_logic is UCR(2);
alias RXB8             : std_logic is UCR(1);
alias TXB8             : std_logic is UCR(0);

signal CHR9_Latched    : std_logic;
signal TXB8_Latched    : std_logic;

-- Common internal signals
signal UART_Clk_En     : std_logic;

-- Internal signals for transmitter
signal SR_Tx           : std_logic_vector (7 downto 0); -- UART transmit shift register
signal SR_Tx_In        : std_logic_vector (7 downto 0); 
signal Tx_In           : std_logic;

-- Transmitter state machine
signal nUART_Tr_St0    : std_logic;
signal UART_Tr_St1     : std_logic;
signal UART_Tr_St2     : std_logic;
signal UART_Tr_St3     : std_logic;
signal UART_Tr_St4     : std_logic;
signal UART_Tr_St5     : std_logic;
signal UART_Tr_St6     : std_logic;
signal UART_Tr_St7     : std_logic;
signal UART_Tr_St8     : std_logic;
signal UART_Tr_St9     : std_logic;
signal UART_Tr_St10    : std_logic;
signal UART_Tr_St11    : std_logic;

signal Flag_A          : std_logic;
signal Flag_B          : std_logic;

signal UDR_Wr_En       : std_logic;
signal UDR_Rd          : std_logic;

signal USR_Rd          : std_logic;
signal UCR_Rd          : std_logic;
signal UBRR_Rd         : std_logic;

-- Frequence divider signals
signal Div16_Cnt       : std_logic_vector (3 downto 0);
signal Div16_In        : std_logic_vector (Div16_Cnt'range); -- Counter Input
signal Div16_Eq        : std_logic;  -- Combinatorial output of the comparator

-- Baud generator signals
signal UBRR_Wr_En      : std_logic; 
signal Baud_Gen_Cnt    : std_logic_vector (7 downto 0); -- Counter
signal Baud_Gen_In     : std_logic_vector (Baud_Gen_Cnt'range); -- Counter Input
signal Baud_Gen_Eq     : std_logic; -- Combinatorial output of the comparator
signal Baud_Gen_Out    : std_logic; 

-- Receiver signals

signal nUART_RcDel_St0 : std_logic;
signal UART_RcDel_St1  : std_logic;
signal UART_RcDel_St2  : std_logic;
signal UART_RcDel_St3  : std_logic;
signal UART_RcDel_St4  : std_logic;
signal UART_RcDel_St5  : std_logic;
signal UART_RcDel_St6  : std_logic;
signal UART_RcDel_St7  : std_logic;
signal UART_RcDel_St8  : std_logic;
signal UART_RcDel_St9  : std_logic;
signal UART_RcDel_St10 : std_logic;
signal UART_RcDel_St11 : std_logic;
signal UART_RcDel_St12 : std_logic;
signal UART_RcDel_St13 : std_logic;
signal UART_RcDel_St14 : std_logic;
signal UART_RcDel_St15 : std_logic;
signal UART_RcDel_St16 : std_logic;

signal nUART_Rc_St0    : std_logic;
signal UART_Rc_St1     : std_logic;
signal UART_Rc_St2     : std_logic;
signal UART_Rc_St3     : std_logic;
signal UART_Rc_St4     : std_logic;
signal UART_Rc_St5     : std_logic;
signal UART_Rc_St6     : std_logic;
signal UART_Rc_St7     : std_logic;
signal UART_Rc_St8     : std_logic;
signal UART_Rc_St9     : std_logic;
signal UART_Rc_St10    : std_logic;

signal RXD_ResyncA     : std_logic;
signal RXD_ResyncB     : std_logic;
signal Detector_Out    : std_logic;
signal Detector_A      : std_logic;
signal Detector_B      : std_logic;

signal UART_Rc_SR     : std_logic_vector(9 downto 0);
signal UART_Rc_SR7_In : std_logic;

signal UART_Rc_Delay  : std_logic;

begin
	
-- Baud generator (First divider)
Baud_Generator :process(cp2,ireset)
begin
if (ireset='0') then                 -- Reset
 Baud_Gen_Cnt <= (others => '0'); 
  Baud_Gen_Out <= '0';
     elsif (cp2='1' and cp2'event) then -- Clock
    Baud_Gen_Cnt <= Baud_Gen_In;
	 Baud_Gen_Out <= Baud_Gen_Eq;
	 end if;
end process;		
Baud_Gen_Eq <= '1' when UBRR=Baud_Gen_Cnt else '0';
Baud_Gen_In <= Baud_Gen_Cnt+1 when Baud_Gen_Eq='0' else (others=>'0');

--Divide by 16 (Second divider)
Divide_By_16:process(cp2,ireset)
begin
if (ireset='0') then                   -- Reset
 Div16_Cnt <= (others => '0'); 
--  UART_Clk_En <= '0'; 
   elsif (cp2='1' and cp2'event) then  -- Clock
   if Baud_Gen_Out='1' then            -- Clock enable   
	 Div16_Cnt <= Div16_In;		   
--     UART_Clk_En <= Div16_Eq;
   end if;
   end if;
end process;		
Div16_Eq <= '1' when Div16_Cnt="1111" else '0';
Div16_In <= Div16_Cnt+1 when Div16_Eq='0' else (others=>'0');

Global_Clock_Enable:process(cp2,ireset)
begin
if (ireset='0') then                   -- Reset
   UART_Clk_En <= '0'; 
   elsif (cp2='1' and cp2'event) then  -- Clock
     UART_Clk_En <= Div16_Eq and Baud_Gen_Out;
    end if;
end process;			
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- UBRR 
UBRR_Wr_En <= '1' when (adr=UBRR_Address and iowe='1') else '0'; -- UBRR write enable
UBRR_Load:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
 UBRR <= ( others => '0');	
  elsif (cp2='1' and cp2'event) then -- Clock
   if UBRR_Wr_En='1' then       -- Clock enable
    UBRR <= dbus_in;	  
   end if;
  end if;
end process;	

UDR_Rd <= '1' when (adr=UDR_Address and iore='1') else '0';  -- UDR read enable

-- UDR	for transmitter
UDR_Wr_En <= '1' when (adr=UDR_Address and iowe='1' and TXEN ='1') else '0';  -- UDR write enable
UDR_Tx_Load:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  UDR_Tx <= ( others => '0');	
  CHR9_Latched <= '0';
  TXB8_Latched <= '0';
 elsif (cp2='1' and cp2'event) then   -- Clock
  if (UDR_Wr_En and (Flag_A or nUART_Tr_St0))='1' then       -- Clock enable
   UDR_Tx <= dbus_in;	  
   CHR9_Latched <= CHR9;
   TXB8_Latched <= TXB8;
  end if;
 end if;
end process;	

-- Load flags
Load_Flags:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  Flag_A <= '0';
  Flag_B <= '0'; 
 elsif (cp2='1' and cp2'event) then   -- Clock
  Flag_A <= (not Flag_A and UDR_Wr_En and not nUART_Tr_St0)or
	  	    (Flag_A and not (UART_Tr_St1 and UART_Clk_En)); 
  Flag_B <= (not Flag_B and (UDR_Wr_En and (Flag_A or (nUART_Tr_St0 and not(UART_Tr_St11 and UART_Clk_En)))))or
	  	    (Flag_B and not (UART_Clk_En and UART_Tr_St11));
 end if;
end process;	
					
Transmitter_Shifter:for i in 6 downto 0 generate
SR_Tx_In(i) <= (dbus_in(i) and UDR_Wr_En and((not Flag_A and not nUART_Tr_St0)or(not Flag_B and UART_Tr_St11 and UART_Clk_En)))or -- Direct load from data bus	
			   (UDR_Tx(i)  and UART_Tr_St11 and Flag_B)or                                  -- Load from UDR(TX)
			   (SR_Tx(i+1) and nUART_Tr_St0 and not UART_Tr_St11); 				-- Shift
end generate;

SR_Tx_In(7) <= (dbus_in(7) and UDR_Wr_En and((not Flag_A and not nUART_Tr_St0)or(not Flag_B and UART_Tr_St11 and UART_Clk_En)))or -- Direct load from data bus	
			   (UDR_Tx(7)  and UART_Tr_St11 and Flag_B)or                                   -- Load from UDR(TX)
               (TXB8_Latched and (UART_Tr_St2 and CHR9_Latched))or               -- Shift first
			   ('1' and not((not Flag_A and not nUART_Tr_St0 and UDR_Wr_En)or UART_Tr_St11 or(UART_Tr_St2 and CHR9_Latched))); -- All other cases

TX_In <= ('0' and UART_Tr_St1)or                             -- Start bit
         (SR_Tx(0) and (nUART_Tr_St0 and not UART_Tr_St1))or -- Shift
		 ('1' and not nUART_Tr_St0);                         -- Idle

-- Transmitter shift register
SR_Tx_Load_Sift:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  SR_Tx <= ( others => '0');	
 elsif (cp2='1' and cp2'event) then   -- Clock
  if ((not Flag_A and not nUART_Tr_St0 and UDR_Wr_En)or(UART_Tr_St11 and UART_Clk_En)or (nUART_Tr_St0 and UART_Clk_En and not UART_Tr_St1))='1' then -- Clock enable
   SR_Tx <= SR_Tx_In;	  
  end if;
 end if;
end process;	

-- Transmitter output register
Tx_Out:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  txd <= '1';
 elsif (cp2='1' and cp2'event) then   -- Clock
  if (UART_Clk_En and (nUART_Tr_St0 or Flag_A))='1' then       -- Clock enable
   txd <= TX_In; 
  end if;
 end if;
end process;	

Transmit_State_Machine:process(cp2,ireset)
begin
if (ireset='0') then                 -- Reset
nUART_Tr_St0 <='0';
UART_Tr_St1  <='0';
UART_Tr_St2  <='0';
UART_Tr_St3  <='0';
UART_Tr_St4  <='0';
UART_Tr_St5  <='0';
UART_Tr_St6  <='0';
UART_Tr_St7  <='0';
UART_Tr_St8  <='0';
UART_Tr_St9  <='0';
UART_Tr_St10 <='0';
UART_Tr_St11 <='0';
  elsif (cp2='1' and cp2'event) then -- Clock
   if (UART_Clk_En = '1') then       -- Clock enable
nUART_Tr_St0 <= (not nUART_Tr_St0 and Flag_A) or (nUART_Tr_St0 and not(UART_Tr_St11 and not Flag_B and not UDR_Wr_En));
UART_Tr_St1  <= not UART_Tr_St1 and ((not nUART_Tr_St0 and Flag_A)or(UART_Tr_St11 and (Flag_B or UDR_Wr_En)));  -- Start bit
UART_Tr_St2  <= UART_Tr_St1;										  -- Bit 0
UART_Tr_St3  <=	UART_Tr_St2;										  -- Bit 1
UART_Tr_St4  <=	UART_Tr_St3;										  -- Bit 2
UART_Tr_St5  <=	UART_Tr_St4;										  -- Bit 3
UART_Tr_St6  <=	UART_Tr_St5;										  -- Bit 4
UART_Tr_St7  <=	UART_Tr_St6;										  -- Bit 5
UART_Tr_St8  <=	UART_Tr_St7;										  -- Bit 6
UART_Tr_St9  <=	UART_Tr_St8;										  -- Bit 7
UART_Tr_St10 <= UART_Tr_St9 and CHR9_Latched;						  -- Bit 8 (if enabled)
UART_Tr_St11 <=	(UART_Tr_St9 and not CHR9_Latched) or UART_Tr_St10;	  -- Stop bit
   end if;
  end if;
end process;	

-- USR bits
USR_UDRE:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  UDRE <= '1';	-- !!
 elsif (cp2='1' and cp2'event) then -- Clock
  UDRE <= (UDRE and not(UDR_Wr_En and (Flag_A or (nUART_Tr_St0 and not(UART_Tr_St11 and UART_Clk_En))))) or (not UDRE and (UART_Tr_St11 and Flag_B and UART_Clk_En));	  
 end if;
end process;		

USR_Wr_En <= '1' when (adr=USR_Address and iowe='1') else '0';

USR_TXC:process(cp2,ireset)
begin
 if (ireset='0') then                 -- Reset
  TXC <= '0';
 elsif (cp2='1' and cp2'event) then -- Clock
  TXC <= (not TXC and(UART_Tr_St11 and not Flag_B and UART_Clk_En and not UDR_Wr_En))or	        -- TXC set	??? 
	     (TXC and not(UDR_Wr_En or txc_irqack or (USR_Wr_En and dbus_in(6))));	-- TXC reset  
 end if;
end process;			

-- Transmitter IRQ
txcirq  <= TXC and TXCIE;   
udreirq <= UDRE and UDRIE;  

-- Output enable signal(for external multiplexer control)
out_en <= '1' when ((adr=UDR_Address or adr=UBRR_Address or adr=USR_Address or adr=UCR_Address) and
                     iore='1') else '0';

UCR_Wr_En <= '1' when (adr=UCR_Address and iowe='1') else '0';

UCR_Bits:process(cp2,ireset)
begin
if ireset='0' then                          -- Reset
	UCR(7 downto 2) <= (others => '0');
  	UCR(0) <= '0';
 elsif (cp2='1' and cp2'event) then         -- Clock
  if UCR_Wr_En='1' then 			        -- Clock enable
  	UCR(7 downto 2) <= dbus_in(7 downto 2);
  	UCR(0) <= dbus_in(0);
  end if;
  end if;
end process;			
--*********************************** Receiver **************************************

Receiver:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset

nUART_RcDel_St0 <='0';
UART_RcDel_St1  <='0';
UART_RcDel_St2  <='0';
UART_RcDel_St3  <='0';
UART_RcDel_St4  <='0';
UART_RcDel_St5  <='0';
UART_RcDel_St6  <='0';
UART_RcDel_St7  <='0';
UART_RcDel_St8  <='0';
UART_RcDel_St9  <='0';
UART_RcDel_St10 <='0';
UART_RcDel_St11 <='0';
UART_RcDel_St12 <='0';
UART_RcDel_St13 <='0';
UART_RcDel_St14 <='0';
UART_RcDel_St15 <='0';
UART_RcDel_St16 <='0';

elsif (cp2='1' and cp2'event) then -- Clock
  if Baud_Gen_Out='1' then 		   -- Clock enable

nUART_RcDel_St0 <= 
(not nUART_RcDel_St0 and not RXD_ResyncB)or 
-- Was :(nUART_RcDel_St0 and not((UART_RcDel_St10 and(Detector_Out and not nUART_Rc_St0))or -- Noise instead of start bit
(nUART_RcDel_St0 and not((UART_RcDel_St9 and(Detector_Out and not nUART_Rc_St0))or -- Noise instead of start bit
(UART_RcDel_St9 and UART_Rc_St10)or -- Stop bit was detected
 (UART_RcDel_St16 and not nUART_Rc_St0)));                 -- ?bug? 

UART_RcDel_St1  <= 
not UART_RcDel_St1 and((not nUART_RcDel_St0 and not RXD_ResyncB)or(UART_RcDel_St16 and nUART_Rc_St0));

UART_RcDel_St2  <= UART_RcDel_St1;
UART_RcDel_St3  <= UART_RcDel_St2;
UART_RcDel_St4  <= UART_RcDel_St3;
UART_RcDel_St5  <= UART_RcDel_St4;
UART_RcDel_St6  <= UART_RcDel_St5;
UART_RcDel_St7  <= UART_RcDel_St6;
UART_RcDel_St8  <= UART_RcDel_St7;
UART_RcDel_St9  <= UART_RcDel_St8;

UART_RcDel_St10  <= not UART_RcDel_St10 and UART_RcDel_St9 and 
((not Detector_Out and not nUART_Rc_St0)or(nUART_Rc_St0 and not UART_Rc_St10));

UART_RcDel_St11 <= UART_RcDel_St10;
UART_RcDel_St12 <= UART_RcDel_St11;
UART_RcDel_St13 <= UART_RcDel_St12;
UART_RcDel_St14 <= UART_RcDel_St13;
UART_RcDel_St15 <= UART_RcDel_St14;
UART_RcDel_St16 <= UART_RcDel_St15;	  

  end if;
end if;
end process;			

UART_Rc_SR7_In <= UART_Rc_SR(8) when CHR9='1' else UART_Rc_SR(9);

Receiver_Shift:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
nUART_Rc_St0 <='0';
UART_Rc_St1  <='0';
UART_Rc_St2  <='0';
UART_Rc_St3  <='0';
UART_Rc_St4  <='0';
UART_Rc_St5  <='0';
UART_Rc_St6  <='0';
UART_Rc_St7  <='0';
UART_Rc_St8  <='0';
UART_Rc_St9  <='0';
UART_Rc_St10 <='0';
UART_Rc_SR <= (others => '0');
 elsif (cp2='1' and cp2'event) then -- Clock
  if (Baud_Gen_Out and UART_RcDel_St9)='1' then 			 -- Clock enable

nUART_Rc_St0 <= (not nUART_Rc_St0 and not RXD_ResyncB)or 
                (nUART_Rc_St0 and not UART_Rc_St10);

UART_Rc_St1  <= not UART_Rc_St1 and (not nUART_Rc_St0 and not RXD_ResyncB); -- D0
UART_Rc_St2  <= UART_Rc_St1;                                                -- D1
UART_Rc_St3  <= UART_Rc_St2;                                                -- D2
UART_Rc_St4  <= UART_Rc_St3;                                                -- D3
UART_Rc_St5  <= UART_Rc_St4;                                                -- D4
UART_Rc_St6  <= UART_Rc_St5;                                                -- D5
UART_Rc_St7  <= UART_Rc_St6;                                                -- D6
UART_Rc_St8  <= UART_Rc_St7;                                                -- D7
UART_Rc_St9  <= UART_Rc_St8 and CHR9;                                       -- D8
UART_Rc_St10 <= (UART_Rc_St8 and not CHR9) or UART_Rc_St9;                  -- Stop bit

   UART_Rc_SR(6 downto 0) <= UART_Rc_SR(7 downto 1);
   UART_Rc_SR(7) <= UART_Rc_SR7_In;
   UART_Rc_SR(8) <= UART_Rc_SR(9);
   UART_Rc_SR(9) <= Detector_Out;
  end if;
end if;
end process;			

RXD_Resinc:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
 RXD_ResyncA <= '1';
 RXD_ResyncB <= '1'; 
 elsif (cp2='1' and cp2'event) then -- Clock
  RXD_ResyncA <= rxd;
  RXD_ResyncB <= RXD_ResyncA;
  end if;
end process;			

Receiver_Detect_A:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
Detector_A <= '0';
 elsif (cp2='1' and cp2'event) then -- Clock
 if (Baud_Gen_Out and UART_RcDel_St7)='1' then -- Clock enable
 Detector_A <= RXD_ResyncB;
end if;
end if;
end process;			

Receiver_Detect_B:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
Detector_B <= '0';
 elsif (cp2='1' and cp2'event) then -- Clock
 if (Baud_Gen_Out and UART_RcDel_St8)='1' then -- Clock enable
 Detector_B <= RXD_ResyncB;
end if;
end if;
end process;			

Detector_Out <= (Detector_A and Detector_B)or(Detector_B and RXD_ResyncB)or(Detector_A and RXD_ResyncB);

UDR_Rx_Reg:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
 UDR_Rx <= (others => '0');
 FE     <= '0';					   -- Framing error
 elsif (cp2='1' and cp2'event) then -- Clock
if (UART_Rc_Delay and RXEN and not RXC)='1' then -- Clock enable ??? TBD
 UDR_Rx <= UART_Rc_SR(7 downto 0);
 FE <= not UART_Rc_SR(9);          -- Framing error
 end if;
end if;
end process;			

UCR_RXB8:process(cp2,ireset)
begin
if ireset='0' then                 -- Reset
  RXB8 <= '1';                     -- ??? Check the papers again
elsif (cp2='1' and cp2'event) then -- Clock
if (UART_Rc_Delay and RXEN and not RXC and CHR9)='1' then -- Clock enable ??? TBD
  RXB8 <= UART_Rc_SR(8);		   -- RXB8
end if;
end if;
end process;			

USR_Bits:process(cp2,ireset)
begin
if ireset='0' then                  -- Reset
RXC <= '0';
DOR <= '0';
UART_Rc_Delay <='0';
elsif (cp2='1' and cp2'event) then -- Clock
RXC <= (not RXC and (UART_Rc_Delay and RXEN))or(RXC and not UDR_Rd);
DOR <= (not DOR and (UART_Rc_Delay and RXEN and RXC))or
       (DOR and not (UART_Rc_Delay and RXEN and not RXC));
UART_Rc_Delay <= not UART_Rc_Delay and (Baud_Gen_Out and UART_Rc_St10 and UART_RcDel_St9);
end if;
end process;			

-- Reserved USR bits
USR(2 downto 0) <= (others => '0'); 

USR_Rd  <= '1' when (adr=USR_Address and iore='1') else '0';
UCR_Rd  <= '1' when (adr=UCR_Address and iore='1') else '0';
UBRR_Rd	<= '1' when (adr=UBRR_Address and iore='1') else '0';

-- Output multiplexer
Out_Mux: for i in dbus_out'range generate
dbus_out(i) <= (UDR_Rx(i) and UDR_Rd)or
			   (USR(i) and USR_Rd)or
			   (UCR(i) and UCR_Rd)or
               (UBRR(i) and UBRR_Rd);
end generate; 	

-- Reciever IRQ
rxcirq <= RXC and RXCIE;

-- External lines
rx_en <= RXEN;
tx_en <= TXEN;

end RTL;
