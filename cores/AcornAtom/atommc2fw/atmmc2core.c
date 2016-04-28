#include "atmmc2.h"

#include "atmmc2io.h"
#include "atmmc2wfn.h"
#include "atmmc2def.h"
#include "ff.h"

//#include "status.h"

#include <string.h>


extern unsigned char configByte;
extern unsigned char blVersion;
extern unsigned char portBVal;

extern BYTE globalIndex;
extern WORD globalAmount;
extern BYTE globalDataPresent;
extern int filenum;

#if (PLATFORM==PLATFORM_PIC)
#define LatchedData		PORTD
#elif (PLATFORM==PLATFORM_AVR)
static BYTE LatchedData;
#endif

static BYTE LatchedAddress;
static BYTE LatchedAddressLast;

#ifdef INCLUDE_SDDOS

extern BYTE globalCurDrive;
extern DWORD globalLBAOffset;

extern void unmountImg(BYTE drive);

extern imgInfo driveInfo[];

#endif

extern unsigned char CardType;
extern /*DSTATUS*/ unsigned char disk_initialize (BYTE);


// cache of the value written to port 0x0e
//
BYTE byteValueLatch;


void at_process(void)
{
   unsigned char received;
   void (*worker)(void) = NULL;

   static unsigned char heartbeat = 0x55;
    	
   ACTIVITYSTROBE(0);

   // port a holds the latched contents of the address bus a0-a3
   //
   LatchAddressIn();
   if (WASWRITE)
		LatchedAddress=LatchedAddressLast;
		
   //log0("%02X\n",LatchedAddress & ADDRESS_MASK);
			
   switch (LatchedAddress & ADDRESS_MASK)
   {
   case CMD_REG:
      {
         if (WASWRITE)
         {
			ReadDataPort();
            received = LatchedData;
	    // File Group 0x10-0x17, 0x30-0x37, 0x50-0x57, 0x70-0x77
	    // filenum = bits 6,5
	    // mask1 = 10011000 (test for file group command)
	    // mask2 = 10011111 (remove file number)
	    if ((received & 0x98) == 0x10) {
	      filenum = (received >> 5) & 3;
	      received &= 0x9F;
	    }
	    
	    // Data Group 0x20-0x23, 0x24-0x27, 0x28-0x2B, 0x2C-0x2F
	    // filenum = bits 3,2
	    // mask1 = 11110000 (test for data group command)
	    // mask2 = 11110011 (remove file number)
	    if ((received & 0xf0) == 0x20) {
	      filenum = (received >> 2) & 3;
	      received &= 0xF3;
	    }
#if (PLATFORM!=PLATFORM_AVR)
            WriteDataPort(STATUS_BUSY);		// Busy handled in CPLD.
#endif
			//log0("%02X\n",LatchedData);
			
			// Directory group, moved here 2011-05-29 PHS.
			//
            if (received == CMD_DIR_OPEN)
            {
               // reset the directory reader
               //
               // when 0x3f is read back from this register it is appropriate to
               // start sending cmd 1s to get items.
               //
               worker = WFN_DirectoryOpen;
            }
            else if (received == CMD_DIR_READ)
            {
               // get next directory entry
               //
               worker = WFN_DirectoryRead;
            }
            else if (received == CMD_DIR_CWD)
            {
               // set CWD
               //
               worker = WFN_SetCWDirectory;
            }
			
			// File group.
			//
            else if (received == CMD_FILE_CLOSE)
            {
               // close the open file, flushing any unwritten data
               //
               worker = WFN_FileClose;
            }
            else if (received == CMD_FILE_OPEN_READ)
            {
               // open the file with name in global data buffer
               //
               worker = WFN_FileOpenRead;
            }
#ifdef INCLUDE_SDDOS
            else if (received == CMD_FILE_OPEN_IMG)
            {
               // open the file as backing image for virtual floppy drive
               // drive number in globaldata[0] followed by asciiz name.
               //
               worker = WFN_OpenSDDOSImg;
            }
#endif
            else if (received == CMD_FILE_OPEN_WRITE)
            {
               // open the file with name in global data buffer for write
               //
               worker = WFN_FileOpenWrite;
            }
            else if (received == CMD_FILE_OPEN_RAF)
            {
               // open the file with name in global data buffer for write/append
               //
               worker = WFN_FileOpenRAF;
            }
            else if (received == CMD_FILE_DELETE)
            {
               // delete the file with name in global data buffer
               //
               worker = WFN_FileDelete;
            }
            else if (received == CMD_FILE_GETINFO)
            {
               // return file's status byte
               //
               worker = WFN_FileGetInfo;
            }
            else if (received == CMD_FILE_SEEK)
            {
               // seek to a location within the file
               //
               worker = WFN_FileSeek;
            }
            else if (received == CMD_INIT_READ)
            {
			   // All data read requests must send CMD_INIT_READ before beggining reading
			   // data from READ_DATA_PORT. After execution of this command the first byte 
			   // of data may be read from the READ_DATA_PORT.
			   //
               WriteDataPort(globalData[0]);
			   globalIndex = 1;
			   LatchedAddress=READ_DATA_REG;
            }
			else if (received == CMD_INIT_WRITE)
            {
               // all data write requests must send CMD_INIT_WRITE here before poking data at 
			   // WRITE_DATA_REG	
               // globalDataPresent is a flag to indicate whether data is present in the bfr.
               //
               globalIndex = 0;
               globalDataPresent = 0;
            }
			else if (received == CMD_READ_BYTES)
			{	
				// Replaces READ_BYTES_REG
				// Must be previously written to latch reg.
				globalAmount = byteValueLatch;
				worker = WFN_FileRead;
			}
			else if (received == CMD_WRITE_BYTES)
			{
				// replaces WRITE_BYTES_REG
				// Must be previously written to latch reg.
				globalAmount = byteValueLatch;	
				worker = WFN_FileWrite;
			}

			// 
			// Exec a packet in the data buffer.
            else if (received == CMD_EXEC_PACKET)
            {
               worker = WFN_ExecuteArbitrary;
            }

#ifdef INCLUDE_SDDOS
         // SDDOS/LBA operations
         //
            else if (received == CMD_LOAD_PARAM)
            {
               // load sddos parameters for read/write
               // globalData[0] = img num
               // globalData[1..4 incl] = 256 byte sector number
               globalCurDrive = globalData[0] & 3;
               globalLBAOffset = LD_DWORD(&globalData[1]);
            }
            if (received == CMD_GET_IMG_STATUS)
            {
               // retrieve sddos image status
               // globalData[0] = img num
               WriteDataPort(driveInfo[byteValueLatch & 3].attribs);
            }
            if (received == CMD_GET_IMG_NAME)
            {
               // retrieve sddos image names
               //
               worker = WFN_GetSDDOSImgNames;
            }
            else if (received == CMD_READ_IMG_SEC)
            {
               // read image sector
               //
               worker = WFN_ReadSDDOSSect;
            }
            else if (received == CMD_WRITE_IMG_SEC)
            {
               // write image sector
               //
               worker = WFN_WriteSDDOSSect;
            }
            else if (received == CMD_SER_IMG_INFO)
            {
               // serialise the current image information
               //
               worker = WFN_SerialiseSDDOSDrives;
            }
            else if (received == CMD_VALID_IMG_NAMES)
            {
               // validate the current sddos image names
               //
               worker = WFN_ValidateSDDOSDrives;
            }
            else if (received == CMD_IMG_UNMOUNT)
            {
               // unmount the selected drive
               //
               worker = WFN_UnmountSDDOSImg;
            }
#endif

			//
			// Utility commands.
			// Moved here 2011-05-29 PHS
            else if (received == CMD_GET_CARD_TYPE)
            {
               // get card type - it's a slowcmd despite appearance
               disk_initialize(0);
               WriteDataPort(CardType);
            }
            else if (received == CMD_GET_PORT_DDR) // get portb direction register
            {
				WriteDataPort(IODDR);
            }
            else if (received == CMD_SET_PORT_DDR) // set portb direction register
            {
               IODDR = byteValueLatch;

               WriteEEPROM(EE_PORTBTRIS, byteValueLatch);
               WriteDataPort(STATUS_OK);
            }
            else if (received == CMD_READ_PORT) // read portb
            {
               WriteDataPort(IOPORT_R);
            }
            else if (received == CMD_WRITE_PORT) // write port B value
            {
               IOPORT_W = byteValueLatch;

               WriteEEPROM(EE_PORTBVALU, byteValueLatch);
               WriteDataPort(STATUS_OK);
            }
            else if (received == CMD_GET_FW_VER) // read firmware version
            {
               WriteDataPort(VSN_MAJ<<4|VSN_MIN);
            }
            else if (received == CMD_GET_BL_VER) // read bootloader version
            {
               WriteDataPort(blVersion);
            }
            else if (received == CMD_GET_CFG_BYTE) // read config byte
            {
               WriteDataPort(configByte);
            }
            else if (received == CMD_SET_CFG_BYTE) // write config byte
            {
               configByte = byteValueLatch;

               WriteEEPROM(EE_SYSFLAGS, configByte);
               WriteDataPort(STATUS_OK);
            }
            else if (received == CMD_READ_AUX) // read porta - latch & aux pin on dongle
            {
               WriteDataPort(LatchedAddress);
            }
            else if (received == CMD_GET_HEARTBEAT)
            {
               // get heartbeat - this may be important as we try and fire
               // an irq very early to get the OS hooked before its first
               // osrdch call. the psp may not be enabled by that point,
               // so we have to wait till it is.
               //
               WriteDataPort(heartbeat);
               heartbeat ^= 0xff;
            }
         }
      }
      break;

#if 0
   case READ_BYTES_REG:
      {
         if (WASWRITE)
         {
			ReadDataPort();
            received = LatchedData;
            WriteDataPort(STATUS_BUSY);

            // read the next N (received) bytes into the data buffer
            // received=0 = 256 to read.
            //
            globalAmount = received;
            worker = WFN_FileRead;
         }
      }
      break;

   case WRITE_BYTES_REG:
      {
         // write the next N bytes from the global data buffer
         // received=0 = 256 to write.
         //
         if (WASWRITE)
         {
			ReadDataPort();
            received = LatchedData;
            WriteDataPort(STATUS_BUSY);

            globalAmount = received;
            worker = WFN_FileWrite;
         }
      }
      break;
#endif 

   case READ_DATA_REG:
      {
         // read data port.
         //
         // any data read requests must be primed by writing CMD_INIT_READ (0x3f) here
         // before the 1st read.
         //
		 // this has to be done this way as the PIC hardware only latches the address 
		 // on a WRITE.
//         if (WASWRITE)
//         {
//			ReadDataPort();
//            received = LatchedData;
//            if (received == CMD_INIT_READ)
//            {
//               WriteDataPort(globalData[0]);
//               globalIndex = 1;
//            }
//         }
//         else
//         {
            WriteDataPort((globalData[(int)globalIndex]));
            ++globalIndex;
//         }
      }
      break;

   case WRITE_DATA_REG:
      {
         // write data port.
         // must have poked 255 at port 3 before starting to poke data here.
         //
         if (WASWRITE)
         {
			ReadDataPort();
            received = LatchedData;

            globalData[globalIndex] = received;
            ++globalIndex;

            globalDataPresent = 1;
         }
      }
      break;

   case LATCH_REG:
      {
         // latch the written value
         if (WASWRITE)
         {
			ReadDataPort();
            received = LatchedData;
            byteValueLatch = received;
            WriteDataPort(byteValueLatch);
         }
      }
      break;
   }

   if (worker)
   {
      worker();
   }
}
