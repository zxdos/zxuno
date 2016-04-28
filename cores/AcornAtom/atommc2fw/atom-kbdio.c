/*
	Atom-kbdio	: IO and Keyboard routines for the Acorn Atom.

	2009-07-28, P.Harvey-Smith.
	
	Implements the following :
	
	1) PS/2 Keyboard interface, driving crosspoint switch connected to
	   Atom keyboard interface.
	
	2) Bi-directional Data bus between the Atom and the AVR, hardware 
	   implemented in an external CPLD.
	   
	3) SD/MMC interface for Atom.
	
	When the Atom writes to the external latch an inturrupt is generated 
	at the AVR, which reads the byte from the latch and sends it to the MMC
	by SPI. The incoming byte reply byte from the SPI is then written back
	to the Atom. In this way the AVR becomes a smart I/O controler for the
	Atom.
	
	This method should also be adaptable to other 8 bit micros, perticually
	those based upon 65x2 and 68xx processors.
	
	2009-09-05 Added the ability to the keyboard module to hadle both the
	normal and escaped scancodes, this allows us to treat for example
	left and right ctrl differently and the numeric keypad keys differently
	from the ins block and seperate cursors.
	
	2009-09-06 Added the ability to reset the Atom from the keyboard by 
	pressing the break key, this is achieved by attaching PD3 of the AVR to
	the 6502 reset line. Normally it is configured as an input and allowed 
	to float. When break is pressed the pin is re-configured as an output and
	sent low, and then after a delay sent high again.
	
	2011-05-25 Ported the new keyboard handling code to the Atom, this fixes 
	several long standing hang bugs with the keyboard code, and should hopefully
	be much more stable.
	
*/

#include <avr/interrupt.h>
#include <inttypes.h>
#include <util/delay.h>
#include "status.h"
#include "atomio.h"
#include "integer.h"
#include "atmmc2.h"

// Global data for MMC

unsigned char globalData[256];

char windowData[512];
BYTE configByte;
BYTE blVersion;

extern WORD globalAmount;

extern void INIT_SPI(void);

void redSignal(char code)
{
   int mark;
   long arm;

   for (mark = 0; mark < code; ++mark)
   {
      REDLEDON();
      for(arm = 0; arm < 40000; ++arm)
      {
      }
      REDLEDOFF();
      for(arm = 0; arm < 40000; ++arm)
      {
      }
   }

   for(arm = 0; arm < 200000; ++arm)
   {
   }
}


void greenSignal(char code)
{
   int mark;
   long arm;

   for (mark = 0; mark < code; ++mark)
   {
      GREENLEDON();
      for(arm = 0; arm < 40000; ++arm)
      {
      }
      GREENLEDOFF();
      for(arm = 0; arm < 40000; ++arm)
      {
      }
   }

   for(arm = 0; arm < 200000; ++arm)
   {
   }
}

void bail(int code)
{
   int i;

   GREENLEDOFF();

   for (i = 0; i < 25; ++i)
   {
      redSignal(code);
   }

   for (;;)
   {
   }
}

int main(void)
{
	
  Serial_Init(57600,57600);

  //	log0("I/O Init\n");
	InitIO();

	// configByte = ReadEEPROM(EE_SYSFLAGS);
	
   REDLEDOFF();
   GREENLEDOFF();

   LEDPINSOUT();

	// configByte = 0xbf;
	configByte = 0xff;

	//log0("MMC Init\n");
	INIT_SPI();
	at_initprocessor();
	
	//log0("init done!\n");
	sei();

	// This is necessary because of a bug in the AVR8 core
	EIMSK = 16;

	while(1)
	{
	  //log0("eifr %d\n", EIFR);
	  //log0("eicr %d\n", EICR);
	  //log0("stat %02x eifr %02x eicr %02x eimsk %02x pinb %02x ddbr %02x\n", SREG, EIFR, EICR, EIMSK, PINB, DDRB);
	  //log0("pinb %d\n", PINB);
	  //log0("ddrb %d\n", DDRB);
		if(LatchInt())
		{
		  //		  log0("process: PA=%02x PB=%02x PD=%02x\n", PINA, PINB, PIND);

			ClearLatchInt();
			at_process();

			// log0("done: DDRA=%02x PORTA=%02x PD=%02x\n", DDRA, PORTA);

		}
	}
	
	return 0;
}
