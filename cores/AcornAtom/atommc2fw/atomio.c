/*
	AtomIO	: IO routines for the Acorn Atom.

	2009-07-16, P.Harvey-Smith.
*/

#include <avr/interrupt.h>
#include <inttypes.h>
#include <util/delay.h>
#include "atomio.h"
#include "status.h"

void InitIO(void)
{
	// IO reg as input 
	SetIORead();
	
	// Setup input interrupt, negedge
	EICR &= ~INTINMASK;
	EICR |= INTINDIR;
	
	// Enable interrupt
	EIMSK &= ~INTINMASK;
	//EIMSK |= INTIN;
	
	// Set intin pin as an input with pullups
	INTIN_DDR 	&= ~INTIN_PMASK;
	INTIN_PORT	|= INTIN_PMASK;
	
	// Setup Input latch OE
	OEDDR 	|= OEMASK;
	ClearOE();

	// Setup output latch 
	LEDDR	|= LEMASK;
	ClearLE();
	
	// Setup address line 
	ADDRDDR	|= ADDRMASK;
	SelectData();
	
	// Make Atom reset line an input
	RESET_DDR &= ~RESET_MASK;
		
}

ISR(INTIN_vect,ISR_BLOCK)
{
	//uint8_t	AtomByte;
	
	//log0("%2.2X:%2.2X\n ",AtomByte,AtomReply);
	
	// Write it to the SPI, wait for SPI and send response to 
	// Atom.
}

void ResetMachine(void)
{
	log0("ResetAtom()\n");
	// Make reset line an output, and take reset line low
	RESET_DDR	|= RESET_MASK;
	RESET_PORT	&= ~RESET_MASK;
	
	// Let it take effect
	_delay_ms(1);
	
	// make it an input again, and let line float
	RESET_DDR	&= ~RESET_MASK;
	RESET_PORT	&= ~RESET_MASK;
}
