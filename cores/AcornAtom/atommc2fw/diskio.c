/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for FatFs     (C)ChaN, 2007        */
/*-----------------------------------------------------------------------*/
/* This is a stub disk I/O module that acts as front end of the existing */
/* disk I/O modules and attach it to FatFs module with common interface. */
/*-----------------------------------------------------------------------*/

#include "diskio.h"


extern DSTATUS mmc_initialize(void);
extern DSTATUS mmc_status(void);
extern DSTATUS mmc_readsector(BYTE* buff, DWORD sector);
extern DSTATUS mmc_writesector(const BYTE* buff, DWORD sector);


DWORD get_fattime (void)
{
   return 11<<25 | 1 << 21 | 1 << 16;
}



/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */


DSTATUS disk_initialize (BYTE drive)
{
   return mmc_initialize();
}




/*-----------------------------------------------------------------------*/
/* Return Disk Status                                                    */

DSTATUS disk_status (
   BYTE drv    /* Physical drive nmuber (0..) */
)
{
   return mmc_status();
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */

DRESULT disk_read (
   BYTE drv,      /* Physical drive nmuber (0..) */
   BYTE *buff,    /* Data buffer to store read data */
   DWORD sector,  /* Sector address (LBA) */
   BYTE count     /* Number of sectors to read (1..255) */
)
{
   return mmc_readsector(buff, sector);
}




/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */

#if _READONLY == 0
DRESULT disk_write (
   BYTE drv,         /* Physical drive nmuber (0..) */
   const BYTE *buff, /* Data to be written */
   DWORD sector,     /* Sector address (LBA) */
   BYTE count        /* Number of sectors to write (1..255) */
)
{
   return mmc_writesector(buff, sector);
}
#endif /* _READONLY */



/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */

DRESULT disk_ioctl (
   BYTE drv,      /* Physical drive nmuber (0..) */
   BYTE ctrl,     /* Control code */
   void *buff     /* Buffer to send/receive control data */
)
{
   return RES_OK;
}

