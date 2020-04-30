
#ifndef _MMC_H
#define _MMC_H

__sfr __at 0x50 SPI_CTRL;
__sfr __at 0x51 SPI_DATA;


#define CS_L() SPI_CTRL = 0xFE
#define CS_H() SPI_CTRL = 0xFF

#define peek(A) (*(volatile unsigned char*)(A))
#define poke(A,V) *(volatile unsigned char*)(A)=(V)
#define peek16(A) (*(volatile unsigned int*)(A))
#define poke16(A,V) *(volatile unsigned int*)(A)=(V)


#endif /* _HARDWARE_H */