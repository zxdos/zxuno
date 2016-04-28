-- *****************************************************************************************
-- AVR constants 
-- Version 2.1
-- Modified 08.01.2007
-- Designed by Ruslan Lepetenok
-- EIND register address is added
-- type ext_mux_din_type and subtype ext_mux_en_type were removed
-- LOG2 function was removed
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;

package avr_adr_pack is

constant PINF_address    : integer := 16#00#; -- Input Pins           Port F
constant PINE_address    : integer := 16#01#; -- Input Pins           Port E
constant DDRE_address    : integer := 16#02#; -- Data Direction Regis Port E
constant PORTE_address   : integer := 16#03#; -- Data Register        Port E
constant ADCL_address    : integer := 16#04#; -- ADC Data register(Low)
constant ADCH_address    : integer := 16#05#; -- ADC Data register(High)
constant ADCSRA_address  : integer := 16#06#; -- ADC Control and Status Register
constant ADMUX_address   : integer := 16#07#; -- ADC Multiplexer Selection Register
constant ACSR_address    : integer := 16#08#; -- Analog Comparator Control and Status Register
constant UBRR0L_address  : integer := 16#09#; -- USART0 Baud Rate Register Low
constant UCSR0B_address  : integer := 16#0A#; -- USART0 Control and Status Register B
constant UCSR0A_address  : integer := 16#0B#; -- USART0 Control and Status Register A
constant UDR0_address    : integer := 16#0C#; -- USART0 I/O Data Register
constant SPCR_address    : integer := 16#0D#; -- SPI Control Register
constant SPSR_address    : integer := 16#0E#; -- SPI Status Register
constant SPDR_address    : integer := 16#0F#; -- SPI I/O Data Register
constant PIND_address    : integer := 16#10#; -- Input Pins           Port D
constant DDRD_address    : integer := 16#11#; -- Data Direction Regis Port D
constant PORTD_address   : integer := 16#12#; -- Data Register        Port D
constant PINC_address    : integer := 16#13#; -- Input Pins           Port C
constant DDRC_address    : integer := 16#14#; -- Data Direction Regis Port C
constant PORTC_address   : integer := 16#15#; -- Data Register        Port C
constant PINB_address    : integer := 16#16#; -- Input Pins           Port B
constant DDRB_address    : integer := 16#17#; -- Data Direction Regis Port B
constant PORTB_address   : integer := 16#18#; -- Data Register        Port B
constant PINA_address    : integer := 16#19#; -- Input Pins           Port A
constant DDRA_address    : integer := 16#1A#; -- Data Direction Regis Port A
constant PORTA_address   : integer := 16#1B#; -- Data Register        Port A
constant EECR_address    : integer := 16#1C#; -- EEPROM Control Register
constant EEDR_address    : integer := 16#1D#; -- EEPROM Data Register
constant EEARL_address   : integer := 16#1E#; -- EEPROM Address Register(Low)
constant EEARH_address   : integer := 16#1F#; -- EEPROM Address Register(High)
constant SFIOR_address   : integer := 16#20#; -- Special Function I/O Register
constant WDTCR_address   : integer := 16#21#; -- Watchdog Timer Control Register
constant OCDR_address    : integer := 16#22#; -- On-Chip Debug Register
constant OCR2_address    : integer := 16#23#; -- Timer/Counter 2 Output Compare Register
constant TCNT2_address   : integer := 16#24#; -- Timer/Counter 2
constant TCCR2_address   : integer := 16#25#; -- Timer/Counter 2 Control Register
constant ICR1L_address   : integer := 16#26#; -- Timer/Counter 1 Input Capture Register(Low)
constant ICR1H_address   : integer := 16#27#; -- Timer/Counter 1 Input Capture Register(High)
constant OCR1BL_address  : integer := 16#28#; -- Timer/Counter 1 Output Compare Register B(Low)
constant OCR1BH_address  : integer := 16#29#; -- Timer/Counter 1 Output Compare Register B(High)
constant OCR1AL_address  : integer := 16#2A#; -- Timer/Counter 1 Output Compare Register A(Low)
constant OCR1AH_address  : integer := 16#2B#; -- Timer/Counter 1 Output Compare Register A(High)
constant TCNT1L_address  : integer := 16#2C#; -- Timer/Counter 1 Register(Low)
constant TCNT1H_address  : integer := 16#2D#; -- Timer/Counter 1 Register(High)
constant TCCR1B_address  : integer := 16#2E#; -- Timer/Counter 1 Control Register B
constant TCCR1A_address  : integer := 16#2F#; -- Timer/Counter 1 Control Register A
constant ASSR_address    : integer := 16#30#; -- Asynchronous mode Status Register
constant OCR0_address    : integer := 16#31#; -- Timer/Counter 0 Output Compare Register
constant TCNT0_address   : integer := 16#32#; -- Timer/Counter 0
constant TCCR0_address   : integer := 16#33#; -- Timer/Counter 0 Control Register
constant MCUCSR_address  : integer := 16#34#; -- MCU general Control and Status Register
constant MCUCR_address   : integer := 16#35#; -- MCU general Control Register
constant TIFR_address    : integer := 16#36#; -- Timer/Counter Interrupt Flag Register
constant TIMSK_address   : integer := 16#37#; -- Timer/Counter Interrupt Mask Register
constant EIFR_address    : integer := 16#38#; -- External Interrupt Flag Register
constant EIMSK_address   : integer := 16#39#; -- External Interrupt Mask Register
constant EICRB_address   : integer := 16#3A#; -- External Interrupt Control Register B
constant RAMPZ_address   : integer := 16#3B#; -- RAM Page Z Select Register
constant XDIV_address    : integer := 16#3C#; -- XTAL Divide Control Register
constant SPL_address     : integer := 16#3D#; -- Stack Pointer(Low)
constant SPH_address     : integer := 16#3E#; -- Stack Pointer(High)
constant SREG_address    : integer := 16#3F#; -- Status Register

-- Extended I/O space
constant DDRF_address    : integer := 16#61#; -- Data Direction Regis Port F
constant PORTF_address   : integer := 16#62#; -- Data Register        Port F
constant PING_address    : integer := 16#63#; -- Input Pins           Port G
constant DDRG_address    : integer := 16#64#; -- Data Direction Regis Port G
constant PORTG_address   : integer := 16#65#; -- Data Register        Port G
constant SPMCSR_address  : integer := 16#68#; -- Store Program Memory Control and Status Register
constant EICRA_address   : integer := 16#6A#; -- External Interrupt Control Register A
constant XMCRB_address   : integer := 16#6C#; -- External Memory Control Register B
constant XMCRA_address   : integer := 16#6D#; -- External Memory Control Register A
constant OSCCAL_address  : integer := 16#6F#; -- Oscillator Calibration Register
constant TWBR_address    : integer := 16#70#; -- TWI Bit Rate Register
constant TWSR_address    : integer := 16#71#; -- TWI Status Register
constant TWAR_address    : integer := 16#72#; -- TWI Address Register
constant TWDR_address    : integer := 16#73#; -- TWI Data Register
constant TWCR_address    : integer := 16#74#; -- TWI Control Register
constant OCR1CL_address  : integer := 16#78#; -- Timer/Counter 1 Output Compare Register C(Low)
constant OCR1CH_address  : integer := 16#79#; -- Timer/Counter 1 Output Compare Register C(High)
constant TCCR1C_address  : integer := 16#7A#; -- Timer/Counter 1 Control Register C
constant ETIFR_address   : integer := 16#7C#; -- Extended Timer/Counter Interrupt Flag Register
constant ETIMSK_address  : integer := 16#7D#; -- Extended Timer/Counter Interrupt Mask Register
constant ICR3L_address   : integer := 16#80#; -- Timer/Counter 3 Input Capture Register(Low)
constant ICR3H_address   : integer := 16#81#; -- Timer/Counter 3 Input Capture Register(High)
constant OCR3CL_address  : integer := 16#82#; -- Timer/Counter 3 Output Compare Register C(Low)
constant OCR3CH_address  : integer := 16#83#; -- Timer/Counter 3 Output Compare Register C(High)
constant OCR3BL_address  : integer := 16#84#; -- Timer/Counter 3 Output Compare Register B(Low)
constant OCR3BH_address  : integer := 16#85#; -- Timer/Counter 3 Output Compare Register B(High)
constant OCR3AL_address  : integer := 16#86#; -- Timer/Counter 3 Output Compare Register A(Low)
constant OCR3AH_address  : integer := 16#87#; -- Timer/Counter 3 Output Compare Register A(High)
constant TCNT3L_address  : integer := 16#88#; -- Timer/Counter 3 Register Low
constant TCNT3H_address  : integer := 16#89#; -- Timer/Counter 3 Register Low
constant TCCR3B_address  : integer := 16#8A#; -- Timer/Counter 3 Control Register B
constant TCCR3A_address  : integer := 16#8B#; -- Timer/Counter 3 Control Register A
constant TCCR3C_address  : integer := 16#8C#; -- Timer/Counter 3 Control Register C
constant UBRR0H_address  : integer := 16#90#; -- USART0 Baud Rate Register High
constant UCSR0C_address  : integer := 16#95#; -- USART0 Control and Status Register C
constant UBRR1H_address  : integer := 16#98#; -- USART1 Baud Rate Register High
constant UBRR1L_address  : integer := 16#99#; -- USART1 Baud Rate Register Low
constant UCSR1B_address  : integer := 16#9A#; -- USART1 Control and Status Register B
constant UCSR1A_address  : integer := 16#9B#; -- USART1 Control and Status Register A
constant UDR1_address    : integer := 16#9C#; -- USART1 I/O Data Register
constant UCSR1C_address  : integer := 16#9D#; -- USART1 Control and Status Register C

-- Cores with 22 bit PC(I/O)
constant EIND_Address    : integer := 16#3C#; -- !!!TBD!!! Occupated by XDIV in Mega128

end avr_adr_pack;

