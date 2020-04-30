/*----------------------------------------------------------------------*/
/* Petit FatFs sample project for generic uC  (C)ChaN, 2010             */
/*----------------------------------------------------------------------*/
/*
  Working for T80SOC on ASK2CB board ..lak 06/12
  Removed re-entrant keyword on send_spi()
  
*/

#include <intrz80.h>
#include <stdio.h>

#include "pff.h"
//#include "delay.h"

// Lak working on 6-12-2012:  Set USE_LSEEK to 0 in PFF.h
// Do not use printf()
// For PFF, file must exist (create on PC first) and size bigger than the bytes to be written


static void __low_level_put(char c) {
 while ((input(0x05) & 0x20) == 0);
output(0x00,c);
}

int putchar(int val)
{
  if (val == '\n')		/* Convert EOL to CR/LF */
    __low_level_put('\r');
  __low_level_put(val);
  return val;
}


unsigned char send_cmd(unsigned char cmd, /* Command byte */unsigned long arg		/* Argument */) ;


void UART_Init (void)
{
//Init Uart16450
// 9600,8,n,1
 output(0x01,0x00);
 output(0x03,0x80);
 output(0x00,42);
 output(0x01,0x00);
 output(0x03,0x03);
 output(0x04,0x0b);	
 
}


void die (		/* Stop with dying message */
	FRESULT rc	/* FatFs return value */
)
{
//	printf("Failed with rc=%u.\n", rc);
    puts("Error");
	for (;;) ;
}


/*-----------------------------------------------------------------------*/
/* Program Main                                                          */
/*-----------------------------------------------------------------------*/

int main (void)
{
	FATFS  fatfs;			/* File system object */
	DIR  dir;				/* Directory object */
	FILINFO  fno;			/* File information object */
	WORD  bw, br, i;
	BYTE  buff[128]; // ? T80SOC error reading if buff > ~300?
	BYTE  rc;
        unsigned char *cp;	
	
	//UART_Init();
	puts("\nMount a volume.\n");
	rc = pf_mount(&fatfs);
	if (rc) die(rc);

#if _USE_DIR
//	printf("\nOpen root directory.\n");
	rc = pf_opendir(&dir, "");
	if (rc) die(rc);

	puts("\nDirectory listing...\n");
	for (;;) {
		rc = pf_readdir(&dir, &fno);	/* Read a directory item */
		if (rc || !fno.fname[0]) break;	/* Error or end of dir */
		if (fno.fattrib & AM_DIR)
		//	printf("   <dir>  %s\n", fno.fname);
		    puts(fno.fname);
		else
		//	printf("%8lu  %s\n", fno.fsize, fno.fname);
		    puts(fno.fname);
	}
	if (rc) die(rc);
#endif

	puts("\nLoading BIN file (SI_COLL.ROM).\n");
	rc = pf_open("SI_COLL.ROM");
	if (rc) die(rc);

	puts("\nLoading BIN file...\n");
	
	cp= (unsigned char *)0x8000; //cartram ptr;
	for (;;) {
	//	rc = pf_read(buff, sizeof(buff), &br);	/* Read a chunk of file */
		rc = pf_read(cp, 32768, &br);	/* Read a chunk of file */
		if (rc || !br) break;			/* Error or end of file */
//		for (i = 0; i < br; i++)		/* Read the data */
		//putchar(buff[i]);
//		    *cp++ = buff[i];
	}
	if (rc) die(rc);

#if _USE_WRITE
	puts("\nOpen a file to write (write.txt).\n");
	rc = pf_open("WRITE.TXT");
	if (rc) die(rc);

	puts("\nWrite a text data. (Hello world!)\n"); // WRITE.TXT must exist with > bytes to be written!
//	for (;;) {
		rc = pf_write("Hello world! 123\r\n", 17, &bw);
//		if (rc || !bw) break;
//	}
	if (rc) die(rc);
	printf("%u bytes written.\n", bw);

	printf("\nTerminate the file write process.\n");
	rc = pf_write(0, 0, &bw);
	if (rc) die(rc);
#endif



	puts("\nTest completed.\n");
	for (;;) ;
}



/*---------------------------------------------------------*/
/* User Provided Timer Function for FatFs module           */
/*---------------------------------------------------------*/

DWORD get_fattime (void)
{
	return	  ((DWORD)(2010 - 1980) << 25)	/* Fixed to Jan. 1, 2010 */
			| ((DWORD)1 << 21)
			| ((DWORD)1 << 16)
			| ((DWORD)0 << 11)
			| ((DWORD)0 << 5)
			| ((DWORD)0 >> 1);
}
