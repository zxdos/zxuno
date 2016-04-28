/*
	AtomIO	: IO routines for the Acorn Atom.

	2009-07-16, P.Harvey-Smith.
*/

#ifndef _ATOM_IO_H_
#define _ATOM_IO_H_

#include "platform.h"
#include "atmmc2io.h"

/* Interrupt trigered by host writing to input latch */
#define INTIN_vect	INT4_vect
#define INTIN		(1<<INT4)
#define INTINMASK	((1<<ISC40) | (1<<ISC41))
#define	INTINDIR	(1<<ISC41)	// Negedge triggered

#define LatchInt()		((EIFR & INTIN)!=0)
#define ClearLatchInt()	{ EIFR |= INTIN; }

#define INTIN_PORT PORTB
#define INTIN_DDR	DDRB
#define INTIN_PIN	PINB
#define INTIN_PPIN	4
#define INTIN_PMASK	(1<<INTIN_PPIN)

//
// Reset line for Atom.
//

#define RESET_PORT		PORTD
#define RESET_PIN		PIND
#define RESET_DDR		DDRD
#define RESET			3
#define RESET_MASK		(1<<RESET)

void InitSPI(void);
void InitIO(void);
uint8_t ReadIO(void);
void WriteIO(uint8_t ToWrite);
void InitMMC(void);
char SPI(uint8_t ToSend);
uint8_t MMCCommand(char befF, uint16_t AdrH, uint16_t AdrL, char befH, char DoDisable);
void ResetMachine(void);
#endif
