-- *****************************************************************************************
-- AVR constants and type declarations
-- Version 1.0A(Special version for the JTAG OCD)
-- Modified 05.05.2004
-- Designed by Ruslan Lepetenok
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

use WORK.SynthCtrlPack.all;

package AVRuCPackage is
-- Old package
type ext_mux_din_type is array(0 to CExtMuxInSize-1) of std_logic_vector(7 downto 0);
subtype ext_mux_en_type  is std_logic_vector(0 to CExtMuxInSize-1);
-- End of old package

constant IOAdrWidth    : positive := 16;
	
type AVRIOAdr_Type is array(0 to 63) of std_logic_vector(IOAdrWidth-1 downto 0); 	
constant CAVRIOAdr : AVRIOAdr_Type :=("0000000000000000","0000000000000001","0000000000000010","0000000000000011",
                                      "0000000000000100","0000000000000101","0000000000000110","0000000000000111",
                                      "0000000000001000","0000000000001001","0000000000001010","0000000000001011",
                                      "0000000000001100","0000000000001101","0000000000001110","0000000000001111",
                                      "0000000000010000","0000000000010001","0000000000010010","0000000000010011",
                                      "0000000000010100","0000000000010101","0000000000010110","0000000000010111",
                                      "0000000000011000","0000000000011001","0000000000011010","0000000000011011",
                                      "0000000000011100","0000000000011101","0000000000011110","0000000000011111",
                                      "0000000000100000","0000000000100001","0000000000100010","0000000000100011",
                                      "0000000000100100","0000000000100101","0000000000100110","0000000000100111",
                                      "0000000000101000","0000000000101001","0000000000101010","0000000000101011",
                                      "0000000000101100","0000000000101101","0000000000101110","0000000000101111",
                                      "0000000000110000","0000000000110001","0000000000110010","0000000000110011",
                                      "0000000000110100","0000000000110101","0000000000110110","0000000000110111",
                                      "0000000000111000","0000000000111001","0000000000111010","0000000000111011",
                                      "0000000000111100","0000000000111101","0000000000111110","0000000000111111");  -- I/O port addresses

-- I/O register file
constant RAMPZ_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3B#);
constant SPL_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3D#);
constant SPH_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3E#);
constant SREG_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3F#);
-- End of I/O register file

-- UART
constant UDR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0C#);
constant UBRR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#09#);
constant USR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0B#);
constant UCR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0A#);
-- End of UART	

-- Timer/Counter
constant TCCR0_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#33#);
constant TCCR1A_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2F#);
constant TCCR1B_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2E#);
constant TCCR2_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#25#);
constant ASSR_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#30#);
constant TIMSK_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#37#);
constant TIFR_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#36#);
constant TCNT0_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#32#);
constant TCNT2_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#24#);
constant OCR0_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#31#);
constant OCR2_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#23#);
constant TCNT1H_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2D#);
constant TCNT1L_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2C#);
constant OCR1AH_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2B#);
constant OCR1AL_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#2A#);
constant OCR1BH_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#29#);
constant OCR1BL_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#28#);
constant ICR1AH_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#27#);
constant ICR1AL_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#26#);
-- End of Timer/Counter	

-- Service module
constant MCUCR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#35#);
constant EIMSK_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#39#);
constant EIFR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#38#);
constant EICR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3A#);
constant MCUSR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#34#);
constant XDIV_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#3C#);
-- End of service module

-- EEPROM 
constant EEARH_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1F#);
constant EEARL_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1E#);
constant EEDR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1D#);
constant EECR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1C#);
-- End of EEPROM 

-- SPI
constant SPDR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0F#);
constant SPSR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0E#);
constant SPCR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#0D#);
-- End of SPI

-- PORTA addresses 
constant PORTA_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1B#);
constant DDRA_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#1A#);
constant PINA_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#19#);

-- PORTB addresses 
constant PORTB_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#18#);
constant DDRB_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#17#);
constant PINB_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#16#);

-- PORTC addresses 
constant PORTC_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#15#);
constant DDRC_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#14#);
constant PINC_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#13#);

-- PORTD addresses 
constant PORTD_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#12#);
constant DDRD_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#11#);
constant PIND_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#10#);

-- PORTE addresses 
constant PORTE_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#03#);
constant DDRE_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#02#);
constant PINE_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#01#);

-- PORTF addresses
constant PORTF_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#07#);
constant DDRF_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#08#);
constant PINF_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#00#);

-- ******************** Parallel port address table **************************************
constant CMaxNumOfPPort : positive := 6;

type PPortAdrTbl_Type is record Port_Adr : std_logic_vector(IOAdrWidth-1 downto 0);
	                            DDR_Adr  : std_logic_vector(IOAdrWidth-1 downto 0);
	                            Pin_Adr  : std_logic_vector(IOAdrWidth-1 downto 0);
end record;

type PPortAdrTblArray_Type is array (0 to CMaxNumOfPPort-1) of PPortAdrTbl_Type;

constant PPortAdrArray : PPortAdrTblArray_Type := ((PORTA_Address,DDRA_Address,PINA_Address),  -- PORTA
                                                   (PORTB_Address,DDRB_Address,PINB_Address), -- PORTB
                                                   (PORTC_Address,DDRC_Address,PINC_Address), -- PORTC
                                                   (PORTD_Address,DDRD_Address,PIND_Address), -- PORTD
                                                   (PORTE_Address,DDRE_Address,PINE_Address), -- PORTE
                                                   (PORTF_Address,DDRF_Address,PINF_Address)); -- PORTF																	

-- ***************************************************************************************
											   
-- Analog to digital converter
constant ADCL_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#04#);
constant ADCH_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#05#);
constant ADCSR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#06#);
constant ADMUX_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#07#);

-- Analog comparator
constant ACSR_Address  : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#08#);

-- Watchdog
constant WDTCR_Address : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#21#);

-- JTAG OCDR (ATmega128)
constant OCDR_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#22#);

-- JTAG OCDR (ATmega16)
--constant OCDR_Address   : std_logic_vector(IOAdrWidth-1 downto 0) := CAVRIOAdr(16#31#);

-- ***************************************************************************************

-- Function declaration
function LOG2(Number : positive) return natural;

end AVRuCPackage;

package	body AVRuCPackage is

-- Functions	
function LOG2(Number : positive) return natural is
variable Temp : positive;
begin
Temp := 1;
if Number=1 then 
 return 0;
  else 
   for i in 1 to integer'high loop
    Temp := 2*Temp; 
     if Temp>=Number then 
      return i;
     end if;
end loop;
end if;	
end LOG2;	
-- End of functions	

end AVRuCPackage;	
