#ifndef _MMC

#include "integer.h"

//#ifndef BUILD_FOR_EMULATOR

#if (PLATFORM==PLATFORM_PIC)

#define SPI_CS_PIN PORTCbits.RC2
#define SPI_CS_TRIS TRISCbits.TRISC2

#define SPI_DIN_PIN PORTCbits.RC5
#define SPI_DIN_TRIS TRISCbits.TRISC5

#define SPI_DOUT_PIN PORTCbits.RC4
#define SPI_DOUT_TRIS TRISCbits.TRISC4

#define SPI_SCK_PIN   PORTCbits.RC3
#define SPI_SCK_TRIS  TRISCbits.TRISC3

#define SELECT()   SPI_CS_PIN=0
#define DESELECT() SPI_CS_PIN=1
#define MMC_SEL()  SPI_CS_PIN==0

#elif (PLATFORM==PLATFORM_AVR)


/* SPI stuff : PHS 2010-06-08 */
#define SPIPORT		PORTD
#define SPIPIN		PIND
#define	SPIDDR		DDRD
#define SPI_SS		4
#define SPI_MOSI	5
#define SPI_MISO	6
#define	SPI_SCK		7

#define SPI_MASK	((1<<SPI_SS) | (1<<SPI_MOSI) | (1<<SPI_MISO) | (1<<SPI_SCK))
#define SPI_SS_MASK	(1<<SPI_SS)

#define AsertSS()	{ SPIPORT &= ~SPI_SS_MASK; };
#define ClearSS()	{ SPIPORT |= SPI_SS_MASK; };
#define WaitSPI()	{ while(!(SPSR & (1<<SPIF))); }; 

#define SELECT()   { SPIPORT &= ~SPI_SS_MASK; }
#define DESELECT() { SPIPORT |= SPI_SS_MASK; }
#define MMC_SEL()  (SPI_CS_PIN & SPI_SS_MASK)==0

#else

#define SELECT()
#define DESELECT()
#define MMC_SEL()

#endif


/* Card type flags (CardType) */
#define CT_MMC 0x01 /* MMC ver 3 */
#define CT_SD1 0x02 /* SD ver 1 */
#define CT_SD2 0x04 /* SD ver 2 */
#define CT_SDC (CT_SD1|CT_SD2) /* SD */
#define CT_BLOCK 0x08 /* Block addressing */

#define _MMC
#endif

