#ifndef _IO

// Mask applied to register address bits.
#define ADDRESS_MASK	0x07

#include "status.h"

#define DEBUG_RESULT	0
#define DEBUG_CMD       0
#define DEBUG_GLOBAL    0

#if (PLATFORM==PLATFORM_PIC)

#define LEDPINSOUT() TRISCbits.TRISC0 = 0; TRISCbits.TRISC1 = 0;

#define REDLEDON() PORTCbits.RC0 = 1;
#define REDLEDOFF() PORTCbits.RC0 = 0;
#define GREENLEDON() PORTCbits.RC1 = 1;
#define GREENLEDOFF() PORTCbits.RC1 = 0;

#define ASSERTIRQ()  PORTCbits.RC6 = 0; TRISCbits.TRISC6 = 0;
#define RELEASEIRQ() TRISCbits.TRISC6 = 1;

#define ACTIVITYSTROBE(x) LATAbits.LATA5 = x;

#define WASWRITE TRISEbits.IBF

#define LatchAddressIn()		{ LatchedAddressLast=PORTA; }
#define ReadDataPort()
#define WriteDataPort(value)	{ LATD=value; }	

#define IODDR TRISB
#define IOPORT_R PORTB
#define IOPORT_W LATB

extern void redSignal(unsigned char);

#elif (PLATFORM==PLATFORM_AVR)
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>

#define LEDPORT PORTB
#define LEDDDR  DDRB
#define GLED    6
#define RLED    7
#define GLED_MASK (1 << GLED)
#define RLED_MASK (1 << RLED)

#define LEDPINSOUT() { LEDDDR |= (GLED_MASK | RLED_MASK); };

#define REDLEDON() { LEDPORT &= ~RLED_MASK; };
#define REDLEDOFF()  { LEDPORT |= RLED_MASK; };
#define GREENLEDON()  { LEDPORT &= ~GLED_MASK; };
#define GREENLEDOFF()  { LEDPORT |= GLED_MASK; };

#define ASSERTIRQ()
#define RELEASEIRQ()

#define ACTIVITYSTROBE(x)

#define NOPDelay()		{ asm("nop"); }

/* Dataport for communication with host processor */
#define DATAPORT	PORTA
#define DATAPIN		PINA
#define	DATADDR		DDRA

#define SetIOWrite()	{ DATADDR=0xFF; };
#define SetIORead() 	{ DATADDR=0x00; };

/* OE line from input latch */
#define	OEPORT	PORTB
#define	OE		0		
#define OEMASK	(1 << OE)
#define OEDDR	DDRB

#define AssertOE()	{ OEPORT &= ~OEMASK; NOPDelay(); };
#define ClearOE()	{ OEPORT |= OEMASK; };

/* LE line for output latch */
#define	LEPORT		PORTB
#define	LE			1		
#define LEMASK		(1 << LE)
#define LEDDR		DDRB

#define AssertLE()	{ LEPORT &= ~LEMASK; NOPDelay(); };
#define ClearLE()	{ LEPORT |= LEMASK; };

/* Address pin, selects either latched address or data reg */
#define ADDRPORT	PORTB
#define ADDR		3
#define ADDRMASK	(1 << ADDR)
#define ADDRDDR		DDRB

#define SelectData()	ADDRPORT &= ~ADDRMASK
#define SelectAddr()	ADDRPORT |= ADDRMASK

#define AtomRWLine		4
#define AtomRWMask		(1 << AtomRWLine)

#define LatchAddressIn()			{ SelectAddr(); SetIORead(); AssertOE(); NOPDelay(); LatchedAddressLast=DATAPIN; ClearOE(); }
#define ReadDataPort()				{ SelectData(); SetIORead(); AssertOE(); NOPDelay(); LatchedData=DATAPIN; ClearOE(); }
#define WriteDataPort(value)		{ SelectData(); SetIOWrite(); DATAPORT=value; AssertLE(); ClearLE(); }	
#define AddressPORT	

#define WASWRITE		((LatchedAddressLast & AtomRWMask)==0) 

#define ReadEEPROM(addr)		eeprom_read_byte ((const uint8_t *)(addr))	
#define WriteEEPROM(addr, val)	eeprom_write_byte ((uint8_t *)(addr), (uint8_t)(val))

#define IODDR DDRE
#define IOPORT_R PINE
#define IOPORT_W PORTE

#elif (PLATFORM==PLATFORM_EMU)

// it's for an emulator!

#define LEDPINSOUT()

#define REDLEDON()
#define REDLEDOFF()
#define GREENLEDON()
#define GREENLEDOFF()

#define ASSERTIRQ()
#define RELEASEIRQ()

#define ACTIVITYSTROBE(x)

#define STKPTR 0

#define redSignal(x)

#endif

#define WriteResult(value) 	{ int v = value; if (DEBUG_RESULT) log0("res=%02X\n",v); WriteDataPort(v); }

#define _IO
#endif
