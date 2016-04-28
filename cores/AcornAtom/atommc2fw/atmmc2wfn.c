#include "atmmc2.h"

#include <string.h>
#include "atmmc2io.h"
#include "atmmc2def.h"
#include "diskio.h"
#include "ff.h"
#include "wildcard.h"

#pragma udata fildata

BYTE res;

BYTE globalIndex;
WORD globalAmount;
BYTE globalDataPresent;
BYTE rwmode;

DIR dir;

int filenum = -1;


FILINFO filinfodata[4];
FIL fildata[4];

FATFS fatfs;

extern BYTE windowData[];

#define WILD_LEN	16

char	WildPattern[WILD_LEN+1];

#ifdef INCLUDE_SDDOS

int lastDriveNo = -1;

imgInfo driveInfo[4];

BYTE globalCurDrive;
DWORD globalLBAOffset;

BYTE SDDOS_seek();

#endif

#pragma udata

// use only immediately after open
extern void get_fileinfo_special(FILINFO *);




void at_initprocessor(void)
{
   int i;
   rwmode = 0;

   fatfs.win = windowData;

#ifdef INCLUDE_SDDOS
   memset(&driveInfo[0], 0xff, sizeof(imgInfo)*4);
#endif

  f_chdrive(0);
  f_mount(0, &fatfs);
  
  for (i = 0; i < 4; i++) {
    fildata[i].fs = NULL;
  }
}


void GetWildcard(void)
{
	int	Idx			= 0;
	int	WildPos		= -1;
	int	LastSlash	= -1;
	
	//log0("GetWildcard() %s\n",(const char *)globalData);
	
	while ((Idx<strlen((const char*)globalData)) && (WildPos<0)) 
	{
		// Check for wildcard character
		if((globalData[Idx]=='?') || (globalData[Idx]=='*')) 
			WildPos=Idx;

		// Check for path seperator
		if((globalData[Idx]=='\\') || (globalData[Idx]=='/'))
			LastSlash=Idx;
			
		Idx++;
	}
	
	//log0("GetWildcard() Idx=%d, WildPos=%d, LastSlash=%d\n",Idx,WildPos,LastSlash);
	
	if(WildPos>-1)
	{
		if(LastSlash>-1)
		{
			// Path followed by wildcard
			// Terminate dir filename at last slash and copy wildcard
			globalData[LastSlash]=0x00;
			strncpy(WildPattern,(const char*)&globalData[LastSlash+1],WILD_LEN);
		}
		else
		{
			// Wildcard on it's own
			// Copy wildcard, then set path to null
			strncpy(WildPattern,(const char*)globalData,WILD_LEN);
			globalData[0]=0x00;
		}
	}
	else
	{
		// No wildcard, show all files
#if (PLATFORM==PLATFORM_PIC)
		strcpypgm2ram((char*)&WildPattern[0], (const rom far char*)"*");
#elif (PLATFORM==PLATFORM_AVR)
		strncpy_P(WildPattern,PSTR("*"),WILD_LEN);
#endif
	}
	
	//log0("GetWildcard() globalData=%s WildPattern=%s\n",(const char*)globalData,WildPattern); 
}

void wfnDirectoryOpen(void)
{
	// Separate wildcard and path 
	GetWildcard();
   
	res = f_opendir(&dir, (const char*)globalData);
   if (FR_OK != res)
   {
      WriteDataPort(STATUS_COMPLETE | res);
      return;
   }

   WriteDataPort(STATUS_OK);
}




void wfnDirectoryRead(void)
{
  FILINFO *filinfo = &filinfodata[0];
   char len;
	int	Match;

	while (1)
	{
		char n = 0;

		res = f_readdir(&dir, filinfo);
		if (res != FR_OK || !filinfo->fname[0])
		{
			// done
			WriteDataPort(STATUS_COMPLETE | res);
			return;
		}

		// Check to see if filename matches current wildcard
		//
		Match=wildcmp(WildPattern,filinfo->fname);
		//log0("WildPattern=%s, filinfo->fname=%s, Match=%d\n",WildPattern,filinfo->fname,Match);
		if(Match)
		{
			len = (char)strlen(filinfo->fname);

			if (filinfo->fattrib & AM_DIR)	
			{
				n = 1;
				globalData[0] = '<';
			}

			strcpy((char*)&globalData[n], (const char*)filinfo->fname);

			if (filinfo->fattrib & AM_DIR)
			{
				globalData[len+1] = '>';
				globalData[len+2] = 0;
				len += 2; // brackets
			}

			// just for giggles put the attribute & filesize in the buffer
			//
			globalData[len+1] = filinfo->fattrib;
			memcpy(&globalData[len+2], (void*)&(filinfo->fsize), sizeof(DWORD));

			WriteDataPort(STATUS_OK);
			return;
		}
	}

#if 0
   while (1)
   {
      char n = 0;

      res = f_readdir(&dir, &filinfo);
      if (res != FR_OK || !filinfo->fname[0])
      {
         // done
         WriteDataPort(STATUS_COMPLETE | res);
         return;
      }

      // no LFNs here ;)
      //
      len = (char)strlen(filinfo->fname);

      if (filinfo->fattrib & AM_DIR)
      {
         n = 1;
         globalData[0] = '<';
      }

      strcpy((char*)&globalData[n], (const char*)filinfo->fname);

      if (filinfo->fattrib & AM_DIR)
      {
         globalData[len+1] = '>';
         globalData[len+2] = 0;
         len += 2; // brackets
      }

      // just for giggles put the attribute & filesize in the buffer
      //
      globalData[len+1] = filinfo->fattrib;
      memcpy(&globalData[len+2], (void*)(&filinfo->fsize), sizeof(DWORD));

      WriteDataPort(STATUS_OK);
      return;
   }
#endif
}



void wfnSetCWDirectory(void)
{
   WriteDataPort(STATUS_COMPLETE | f_chdir((const XCHAR*)globalData));
}




static BYTE fileOpen(BYTE mode)
{
  int ret;
  if (filenum == 0) {
    // The scratch file is fixed, so we are backwards compatible with 2.9 firmware
    ret = f_open(&fildata[0], (const char*)globalData, mode);
  } else {
    // If a random access file is being opened, search for the first available FIL
    filenum = 0;
    if (!fildata[1].fs) {
      filenum = 1;
    } else if (!fildata[2].fs) {
      filenum = 2;
    } else if (!fildata[3].fs) {
      filenum = 3;
    }
    if (filenum > 0) {
      ret = f_open(&fildata[filenum], (const char*)globalData, mode);
      if (!ret) { 
	// No error, so update the return value to indicate the file num
	ret = FILENUM_OFFSET | filenum;
      }
    } else {
      // All files are open, return too many open files
      ret = ERROR_TOO_MANY_OPEN;
    } 
  }
  return STATUS_COMPLETE | ret;
}

void wfnFileOpenRead(void)
{
   res = fileOpen(FA_OPEN_EXISTING|FA_READ);
   if (filenum < 4) { 
     FILINFO *filinfo = &filinfodata[filenum];
     get_fileinfo_special(filinfo);
   }
   WriteDataPort(STATUS_COMPLETE | res);
}

void wfnFileOpenWrite(void)
{
   WriteDataPort(STATUS_COMPLETE | fileOpen(FA_CREATE_NEW|FA_WRITE));
}

void wfnFileOpenRAF(void)
{
   WriteDataPort(STATUS_COMPLETE | fileOpen(FA_OPEN_ALWAYS|FA_WRITE));
}




void wfnFileGetInfo(void)
{
   FIL *fil = &fildata[filenum];
   FILINFO *filinfo = &filinfodata[filenum];
   union
   {
      DWORD dword;
      char byte[4];
   }
   dwb;

   dwb.dword = fil->fsize;
   globalData[0] = dwb.byte[0];
   globalData[1] = dwb.byte[1];
   globalData[2] = dwb.byte[2];
   globalData[3] = dwb.byte[3];

   dwb.dword = (DWORD)(fil->org_clust-2) * fatfs.csize + fatfs.database;
   globalData[4] = dwb.byte[0];
   globalData[5] = dwb.byte[1];
   globalData[6] = dwb.byte[2];
   globalData[7] = dwb.byte[3];

   dwb.dword = fil->fptr;
   globalData[8] = dwb.byte[0];
   globalData[9] = dwb.byte[1];
   globalData[10] = dwb.byte[2];
   globalData[11] = dwb.byte[3];

   globalData[12] = filinfo->fattrib & 0x3f;

   WriteDataPort(STATUS_OK);
}

void wfnFileRead(void)
{
   int ret;
   FIL *fil = &fildata[filenum];
   UINT read;
   if (globalAmount == 0)
   {
      globalAmount = 256;
   }
   ret = f_read(fil, globalData, globalAmount, &read);
   if (filenum > 0 && ret == 0 &&  globalAmount != read) {
      WriteDataPort(STATUS_EOF);
   } else {
      WriteDataPort(STATUS_COMPLETE | ret);
   }
}

void wfnFileWrite(void)
{
   FIL *fil = &fildata[filenum];
   UINT written;
   if (globalAmount == 0)
   {
      globalAmount = 256;
   }

   WriteDataPort(STATUS_COMPLETE | f_write(fil, (void*)globalData, globalAmount, &written));
}




void wfnFileClose(void)
{
   FIL *fil = &fildata[filenum];
   WriteDataPort(STATUS_COMPLETE | f_close(fil));
}






void wfnFileDelete(void)
{
   WriteDataPort(STATUS_COMPLETE | f_unlink((const XCHAR*)&globalData[0]));
}

void wfnFileSeek(void)
{
   FIL *fil = &fildata[filenum];

   union
   {
      DWORD dword;
      char byte[4];
   }
   dwb;
   
   dwb.byte[0] = globalData[0]; 
   dwb.byte[1] = globalData[1]; 
   dwb.byte[2] = globalData[2]; 
   dwb.byte[3] = globalData[3]; 

   WriteDataPort(STATUS_COMPLETE | f_lseek(fil, dwb.dword));
}



#ifdef INCLUDE_SDDOS

int switchDrive(int driveNo) {
   int res = 0;
   if (driveNo != lastDriveNo) {
      if (lastDriveNo >= 0) {
         f_close(&fildata[0]);
      }
      lastDriveNo = -1;
      if (driveNo >= 0) {
         res = f_open(&fildata[0], (const XCHAR*)&driveInfo[driveNo].filename,(FA_READ | FA_WRITE));
         if (!res) {
            lastDriveNo = driveNo;
         }
      }
   }
   return res;
}


BYTE tryOpenImage(int driveNo)
{
   FIL *fil = &fildata[0];
   FILINFO *filinfo = &filinfodata[0];
   imgInfo* imginf = &driveInfo[driveNo];
   BYTE i;

   res = switchDrive(driveNo);
   if (FR_OK != res)
   {
      return STATUS_COMPLETE | res;
   }

   // disallow multiple mounts of the same image
   //
   for (i = 0; i < 4; ++i)
   {
      if (imginf == &driveInfo[i])
      {
         continue;
      }

      if (memcmp((void*)imginf, (void*)&driveInfo[i], sizeof(imgInfo)) == 0)
      {
         // warning - already mounted
         return STATUS_COMPLETE + ERROR_ALREADY_MOUNT; // 0x4a;
      }
   }

   // all good - should only call "get_fileinfo_special" if no other file operations
   // have occurred since the last open.
   //
   get_fileinfo_special(filinfo);
   imginf->attribs = filinfo->fattrib;

   return imginf->attribs;
}



void saveDrivesImpl(void)
{
   FIL *fil = &fildata[3];
#if (PLATFORM==PLATFORM_PIC)
   strcpypgm2ram((char*)&globalData[0], (const rom far char*)"BOOTDRV.CFG");
#elif (PLATFORM==PLATFORM_AVR)
	strcpy_P((char*)&globalData[0],PSTR("BOOTDRV.CFG"));
#elif (PLATFORM==PLATFORM_ATMU)
	strcpy((char*)&globalData[0],"BOOTDRV.CFG");
#endif
   res = f_open(fil, (const XCHAR*)globalData, FA_OPEN_ALWAYS|FA_WRITE);
   if (FR_OK == res)
   {
      UINT temp;
      f_write(fil, (const void*)&driveInfo[0], 4 * sizeof(imgInfo), &temp);
      f_close(fil);
   }
}


void wfnOpenSDDOSImg(void)
{
   // globalData[0] = drive number 0..3
   // globalData[1]... image filename

   BYTE error;
   BYTE id = globalData[0] & 3;

   imgInfo* image = &driveInfo[id];

   memset(image, 0, sizeof(imgInfo));
   strncpy((char*)&image->filename, (const char*)&globalData[1], 13);

   error = tryOpenImage(id);
   if (error >= STATUS_COMPLETE)
   {
      // fatal error range
      //
      memset(image, 0xff, sizeof(imgInfo));
   }

   // always save - even if there was an error
   // we may have nullified a previously valid slot.
   //
   saveDrivesImpl();

   WriteDataPort(error);
}


BYTE SDDOS_seek()
{
   DWORD fpos = globalLBAOffset * SDOS_SECTOR_SIZE;
   return f_lseek(&fildata[0], fpos);
}

void wfnReadSDDOSSect(void)
{
   BYTE returnCode = STATUS_COMPLETE | ERROR_INVALID_DRIVE;
   UINT bytes_read;

   if (driveInfo[globalCurDrive].attribs != 0xff)
   {
      switchDrive(globalCurDrive);
      if(FR_OK==SDDOS_seek())
      {
         returnCode = f_read(&fildata[0], globalData, SDOS_SECTOR_SIZE, &bytes_read);
      }

      if (RES_OK == returnCode)
      {
         WriteDataPort(STATUS_OK);
         return;
      }

      driveInfo[globalCurDrive].attribs = 0xff;
      returnCode |= STATUS_COMPLETE;
   }

   WriteDataPort(returnCode);
}


void wfnWriteSDDOSSect(void)
{
   BYTE returnCode = STATUS_COMPLETE | ERROR_INVALID_DRIVE;
   UINT bytes_written;
   
   if (driveInfo[globalCurDrive].attribs != 0xff)
   {
      if (driveInfo[globalCurDrive].attribs & 1)
      {
         // read-only
         //
         WriteDataPort(STATUS_COMPLETE | ERROR_READ_ONLY);
         return;
      }
      
      switchDrive(globalCurDrive);

      if(FR_OK==SDDOS_seek())
      {
         returnCode = f_write(&fildata[0], globalData, SDOS_SECTOR_SIZE, &bytes_written);
      }

      if(FR_OK==returnCode)
      {
         returnCode = f_sync(&fildata[0]);
      }

      // invalidate the drive on error
      if(FR_OK==returnCode)
      {
         WriteDataPort(STATUS_OK);
         return;
      }

      driveInfo[globalCurDrive].attribs = 0xff;
      WriteDataPort(STATUS_COMPLETE);
   }

   WriteDataPort(returnCode);
}

void wfnValidateSDDOSDrives(void)
{
   FIL *fil = &fildata[0];
   BYTE i;
   BYTE* ii = (BYTE*)driveInfo;

   // read the imgInfo structures back out of eeprom,
   // or 'BOOTDRV.CFG' if present (gets precidence)
#if (PLATFORM==PLATFORM_PIC)
   strcpypgm2ram((char*)globalData, (const rom far char*)"BOOTDRV.CFG");
#elif (PLATFORM==PLATFORM_AVR)
   strcpy_P((char*)&globalData[0],PSTR("BOOTDRV.CFG"));
#endif


   // try to read the boot config file
   //
   res = f_open(fil, (const char*)globalData, FA_READ|FA_OPEN_EXISTING);
   if (!res)
   {
      UINT temp;
      res = f_read(fil, (void*)(&ii[0]), 4 * sizeof(imgInfo), &temp);
      f_close(fil);
   }
   else
   {
      memset(&ii[0], 0xff, 4 * sizeof(imgInfo));
   }

   for (i = 0; i < 4; ++i)
   {
      if (driveInfo[i].attribs == 0xff || (tryOpenImage(i) & 0x40))
      {
         memset(&driveInfo[i], 0xff, sizeof(imgInfo));
      }
   }

   saveDrivesImpl();

   WriteDataPort(STATUS_OK);
}


void wfnSerialiseSDDOSDrives(void)
{
   saveDrivesImpl();
   WriteDataPort(STATUS_OK);
}


// slightly uneasy about using this var, but it should be fine.
//
extern BYTE byteValueLatch;

void wfnUnmountSDDOSImg(void)
{
   int driveNo = byteValueLatch & 3; 
   imgInfo* image = &driveInfo[driveNo];
   switchDrive(driveNo);
   f_close(&fildata[driveNo]);
   lastDriveNo = -1;
   memset(image, 0xff, sizeof(imgInfo));

   saveDrivesImpl();
   WriteDataPort(STATUS_OK);
}


void wfnGetSDDOSImgNames(void)
{
   BYTE i;
   BYTE m, n = 0;
   for (i = 0; i < 4; ++i)
   {
      if (driveInfo[i].attribs != 0xff)
      {
         m = 0;

         while(driveInfo[i].filename[m] && m < 12)
         {
            globalData[n] = driveInfo[i].filename[m];
            ++m;
            ++n;
         }
      }
      globalData[n] = 0;
      ++n;
   }

   WriteDataPort(STATUS_OK);
}


#endif



#define MK_WORD(x,y) ((WORD)(x)<<8|(y))

// Read Eeprom
#define COM_RE MK_WORD('R','E')

// Write Eeprom
#define COM_WE MK_WORD('W','E')


void wfnExecuteArbitrary(void)
{
   if (globalAmount == 0 && globalDataPresent == 0)
   {
      WriteDataPort(STATUS_COMPLETE | ERROR_NO_DATA);
      return;
   }

   switch (LD_WORD(&globalData[0]))
   {
   case COM_RE: // read eeprom
      {
         // globalData[2] = start offset, [3] = count

         WORD start = (WORD)globalData[2];
         WORD end = start + (WORD)globalData[3];

         WORD i, n = 0;
         for (i = start; i < end; ++i, ++n)
         {
            globalData[n] = ReadEEPROM(i);
         }

         WriteDataPort(STATUS_OK);
      }
      break;

   case COM_WE: // write eeprom
      {
         // globalData[2] = start offset, [3] = count

         WORD start = (WORD)globalData[2];
         WORD end = start + (WORD)globalData[3];

         WORD i, n = 4;
         for (i = start; i < end; ++i, ++n)
         {
            WriteEEPROM(i,globalData[n]);
         }

         WriteDataPort(STATUS_OK);
      }
      break;
   }
}
