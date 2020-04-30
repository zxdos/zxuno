/*-----------------------------------------------------------------------
/  PFF - Low level disk interface modlue include file    (C)ChaN, 2010
/-----------------------------------------------------------------------*/

#ifndef _DISKIO
#define _DISKIO

#include "integer.h"
#include "pff.h"

void delay_us(unsigned n);

/* Status of Disk Functions */
typedef BYTE	DSTATUS;

#define STA_NOINIT		0x01	/* Drive not initialized */
#define STA_NODISK		0x02	/* No medium in the drive */


/* Results of Disk Functions */
typedef enum {
	RES_OK = 0,		/* 0: Function succeeded */
	RES_ERROR,		/* 1: Disk error */
	RES_NOTRDY,		/* 2: Not ready */
	RES_PARERR		/* 3: Invalid parameter */
} DRESULT;


/*---------------------------------------*/
/* Prototypes for disk control functions */

DSTATUS disk_initialize (void);
#if _USE_READ
DRESULT disk_readp (BYTE*, DWORD, WORD, WORD);
#endif
#if _USE_WRITE
DRESULT disk_writep (const BYTE*, DWORD);
#endif

#endif
