#include "platform.h"

#include "atmmc2.h"
#include "..\shared\config.h"

#include <string.h>
#include <delays.h>

#include "atmmc2io.h"
#include "integer.h"
#include "buildnumber.h"


#define FLAG_BLENABLED 0x80
#define FLAG_IRQENABLED 0x20


#pragma udata windowbuf
char windowData[512];
#pragma udata

#pragma udata globalbuf
char globalData[256];
#pragma udata

#ifdef INCLUDE_SDDOS
#pragma udata sectorbuf
char sectorData[512];
#pragma udata
#endif


BYTE configByte;
BYTE blVersion;


#pragma code _RESET_VECTOR = 0x001000
extern void _startup (void);        // See c018i.c in your C18 compiler dir
void _start(void)
{
   _asm
   goto _startup
   _endasm
}
#pragma code

#pragma code _HIIRQ_VECTOR = 0x1008
void PSP(void);
#pragma interrupt PSP
void PSP(void)
{
   REDLEDOFF();
   REDLEDON();
   _asm
   BUILDNUMBER
   _endasm
}
#pragma code



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



void WriteEEPROM(BYTE address, BYTE val)
{
   EEADR = address;
   EEDATA = val;
   EECON1bits.EEPGD = 0;
   EECON1bits.CFGS = 0;
   EECON1bits.WREN = 1;
   EECON2 = 0x55;
   EECON2 = 0xAA;
   EECON1bits.WR = 1;
   while(EECON1bits.WR)
   {
      _asm nop _endasm;
   }
   EECON1bits.WREN = 0;
}


BYTE ReadEEPROM(BYTE address)
{
   EEADR = address;
   EECON1bits.EEPGD = 0;
   EECON1bits.CFGS = 0;
   EECON1bits.RD = 1;
   return EEDATA;
}


extern void process(void);

void main(void)
{
   // they're static so they're heap based (check this ;)
   //
   static int i;
   static char received = 0;

   LATD = 0xff;

   CardType = 0;     // no card

   CLOCKINIT();

   // ensure all ADC channels, comparators are off
   //
   ADCON1 = 0b00001111;
   CMCON = 0x07;
   TRISA = 0b11011111;

   // enable PSP
   //
   TRISE = 0b00010111;

   REDLEDOFF();
   GREENLEDOFF();

   LEDPINSOUT();

   configByte = ReadEEPROM(EE_SYSFLAGS);

   // copy the bootloader's version bytes out of program flash
   //
   memcpypgm2ram((void*)(&globalData[0]), (const rom far void *)12, 1);
   memcpypgm2ram((void*)(&globalData[1]), (const rom far void *)14, 1);
   blVersion = (globalData[0] << 4) + (globalData[1] & 0x0f);

   LATB = ReadEEPROM(EE_PORTBVALU);
   TRISB = ReadEEPROM(EE_PORTBTRIS);

   at_initprocessor();

   RELEASEIRQ();

doneprocessing:
   ACTIVITYSTROBE(1);
   PIR1bits.PSPIF = 0;

   while (PIR1bits.PSPIF == 0){}

   at_process();
   goto doneprocessing;
}
