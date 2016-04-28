#ifndef __MMC2_H
#define __MMC2_H

#include "platform.h"

#if (PLATFORM==PLATFORM_PIC)
#include <p18cxxx.h>
#elif (PLATFORM==PLATFORM_AVR)
#endif

#define VSN_MAJ 2
#define VSN_MIN 10

#define SECBUFFSIZE 512
#define GLOBUFFSIZE 256

#if defined(__18F4525) || (PLATFORM==PLATFORM_AVR)
#define INCLUDE_SDDOS
#endif

#define EE_SYSFLAGS 0xff
#define EE_PORTBVALU 0xfe
#define EE_PORTBTRIS 0xfe

extern unsigned char configByte;
extern unsigned char CardType;
extern unsigned char blVersion;
extern unsigned char portBVal;

extern unsigned char globalData[];

#if (PLATFORM!=PLATFORM_AVR)
extern void WriteEEPROM(unsigned char address, unsigned char val);
extern unsigned char ReadEEPROM(unsigned char address);
#endif

extern void at_initprocessor(void);
extern void at_process(void);


#define MODEREAD 1
#define MODEWRITE 2


typedef void (*WORKERFN)(void);

#define WFUNC(x)  extern void wfn##x(void); const WORKERFN WFN_##x = wfn##x;



#ifdef INCLUDE_SDDOS

#define SDOS_SECTOR_SIZE	256

typedef struct
{
   char filename[13];
   unsigned char attribs;
}
imgInfo;

extern unsigned char *sectorData;

#endif


#endif // __MMC2_H
