
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "joy.h"
#include "vdp.h"
#include "mmc.h"
#include "fat.h"

#define peek16(A) (*(volatile unsigned int*)(A))
#define poke16(A,V) *(volatile unsigned int*)(A)=(V)

/* I/O ports */
__sfr __at 0x50 STATUS;
__sfr __at 0x52 CONFIG;
__sfr __at 0x53 MACHID;

/* Constants */

static const char biosfiles[3][12] = {
	"COLECO  BIO",
	"ONYX    BIO",
	"SPLICE  BIO"
};
static const char * mcfile    = "MULTCARTROM";

//                                     11111111112222222222333
//                            12345678901234567890123456789012
static const char TITULO[] = "      COLECOVISION LOADER       ";

/* Variables */

static unsigned char mach_id;

/* Functions */

/*******************************************************************************/
void printCenter(unsigned char y, unsigned char *msg)
{
	unsigned char x;

	x = 16 - strlen(msg)/2;
	vdp_gotoxy(x, y);
	vdp_putstring(msg);
}

/*******************************************************************************/
void erro(unsigned char *erro)
{
	DisableCard();
	vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);
	printCenter(12, erro);
	for(;;);
}

/*******************************************************************************/
void startMulticart()
{
	unsigned char *cp    = (unsigned char *)0x7100;

	// Disable loader and start BIOS
	*cp++=0x3e;		// LD A, 2
	*cp++=0x02;
	*cp++=0xd3;		// OUT (0x52), A
	*cp++=0x52;
	*cp++=0xc3;		// JP 0
	*cp++=0x00;
	*cp++=0x00;
	__asm__("jp 0x7100");
}

/*******************************************************************************/
void startExtCart()
{
	unsigned char *cp    = (unsigned char *)0x7100;

	// Disable loader and start BIOS
	*cp++=0x3e;		// LD A, 4
	*cp++=0x04;
	*cp++=0xd3;		// OUT (0x52), A
	*cp++=0x52;
	*cp++=0xc3;		// JP 0
	*cp++=0x00;
	*cp++=0x00;
	__asm__("jp 0x7100");
}

/*******************************************************************************/
void main()
{
	unsigned char *pbios = (unsigned char *)0x0000;
	unsigned char *pcart = (unsigned char *)0x8000;
	unsigned char i, joybtns, bi;
	unsigned int  ext_cart_id = 0xFFFF;
	char *biosfile       = NULL;
	char msg[32];
	fileTYPE file;

	mach_id = MACHID;
	
	if (mach_id == 8) {
		if ((STATUS & 0x01) == 0x01) {
			startExtCart();
		}
	}

	vdp_init();
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);
	vdp_putstring(TITULO);
//	vdp_gotoxy(10, 10);
//	vdp_putstring("Loading... ");
	joybtns = ReadJoy();
	if ((joybtns & JOY_UP) != 0) {
		bi = 1;
	} else if ((joybtns & JOY_DOWN) != 0) {
		bi = 2;
	} else {
		bi = 0;
	}
	biosfile = (char *)biosfiles[bi];
	strcpy(msg, "Loading ");
	strcat(msg, biosfile);
	printCenter(9, msg);

	if (!MMC_Init()) {										// Initialize SD Card
		erro("Error on SD card initialization!");
	}
	if (!FindDrive()) {										// Find partition
		erro("Error monting SD card!");
	}
	if (!FileOpen(&file, biosfile)) {						// Open file
		erro("BIOS file not found!");
	}
	if (file.size != 8192) {
		erro("BIOS file size is not 8192!");
	}
	for (i = 0; i < 16; i++) {								// Read 16 blocks of 512 bytes (8192 bytes)
		if (!FileRead(&file, pbios)) {
			erro("Error reading BIOS file!");
		}
		pbios += 512;
	}
	// Test if external cartridge exists
	ext_cart_id = peek16(0x8000);
	if (ext_cart_id == 0x55AA || ext_cart_id == 0xAA55) {
		// Has external cartridge
		startExtCart();
	} else {
		// Do not has external cartridge
		CONFIG = 0x03;
		strcpy(msg, "Loading MULTCART ROM");
		printCenter(10, msg);
	
		if (!FileOpen(&file, mcfile)) {							// Open file
			erro("MULTCART.ROM file not found!");
		}
		if (file.size != 16384) {
			erro("MULTCART.ROM file size wrong!");
		}
		for (i = 0; i < 32; i++) {								// Read 32 blocks of 512 bytes (16384 bytes)
			if (!FileRead(&file, pcart)) {
				erro("Error reading file MULTCART.ROM");
			}
			pcart += 512;
		}
		vdp_putstring("OK");
		startMulticart();
	}
}
