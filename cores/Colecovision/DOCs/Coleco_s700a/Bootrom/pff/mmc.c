/*------------------------------------------------------------------------/
/  Bitbanging MMCv3/SDv1/SDv2 (in SPI mode) control module for PFF
/-------------------------------------------------------------------------/
/
/  Copyright (C) 2010, ChaN, all right reserved.
/
/ * This software is a free software and there is NO WARRANTY.
/ * No restriction on use. You can use, modify and redistribute it for
/   personal, non-profit or commercial products UNDER YOUR RESPONSIBILITY.
/ * Redistributions of source code must retain the above copyright notice.
/
/--------------------------------------------------------------------------/
 Features:

 * Very Easy to Port
   It uses only 4-6 bit of GPIO port. No interrupt, no SPI port is used.

 * Platform Independent
   You need to modify only a few macros to control GPIO ports.

/-------------------------------------------------------------------------*/


#include "diskio.h"


/*-------------------------------------------------------------------------*/
/* Platform dependent macros and functions needed to be modified           */
/*-------------------------------------------------------------------------*/

#include <intrz80.h>		/* Include hardware specific declareation file here */

//#define OPORT 0x50
//#define IPORT   0x50

//#define CS  5  

// for software SPI      SD Pin 3,6 = GND , SD Pin 4=VCC
//#define MOSI 4 // Master Out / Slave In (output)	SD Pin 2
//#define MISO 3 // Master In / Slave Out (input)	SD Pin 7
//#define  SCK 2 // Serial Clock (output)		SD Pin 5
//#define  NSS 5 // Slave Select				SD Pin 1


#define	INIT_PORT()	init_port()	/* Initialize MMC control port (CS/CLK/DI:output, DO:input) */
#define DLY_US(n)	delay_us(n)	/* Delay n microseconds */
//#define	FORWARD(d)	forward(d)	/* Data in-time processing function (depends on the project) */

//#define	CS_H()	output(OPORT,OUTBYTE |= (1<<CS))  
//#define CS_L()	output(OPORT,OUTBYTE &= ~(1<<CS))   /* Set MMC CS "low" */
//#define CK_H()	output(OPORT,OUTBYTE |= (1<<SCK))  /* Set MMC SCLK "high" */
//#define	CK_L()	output(OPORT,OUTBYTE &= ~(1<<SCK)) /* Set MMC SCLK "low" */
//#define DI_H()	output(OPORT,OUTBYTE=OUTBYTE | (1<<MOSI))   /* Set MMC DI "high" */
//#define DI_L()	output(OPORT,OUTBYTE=OUTBYTE & ~(1<<MOSI))  /* Set MMC DI "low" */
//#define DO	input(IPORT) & (1<<MISO)
//#define DO			btest(P3)	/* Get MMC DO value (high:true, low:false) */



//#define OPORT 0x50
//#define IPORT 0x50

#define SPI_SS 0x50
#define SPI_WR 0x51
#define SPI_RD 0x50

#define CS_L() output(SPI_SS,0)
#define CS_H() output(SPI_SS,1)


/*--------------------------------------------------------------------------

   Module Private Functions

---------------------------------------------------------------------------*/

/* Definitions for MMC/SDC command */
#define CMD0	(0x40+0)	/* GO_IDLE_STATE */
#define CMD1	(0x40+1)	/* SEND_OP_COND (MMC) */
#define	ACMD41	(0xC0+41)	/* SEND_OP_COND (SDC) */
#define CMD8	(0x40+8)	/* SEND_IF_COND */
#define CMD16	(0x40+16)	/* SET_BLOCKLEN */
#define CMD17	(0x40+17)	/* READ_SINGLE_BLOCK */
#define CMD24	(0x40+24)	/* WRITE_BLOCK */
#define CMD55	(0x40+55)	/* APP_CMD */
#define CMD58	(0x40+58)	/* READ_OCR */

/* Card type flags (CardType) */
#define CT_MMC				0x01	/* MMC ver 3 */
#define CT_SD1				0x02	/* SD ver 1 */
#define CT_SD2				0x04	/* SD ver 2 */
#define CT_SDC				(CT_SD1|CT_SD2)	/* SD */
#define CT_BLOCK			0x08	/* Block addressing */


void delay_us (UINT delay) {
UINT d,i;
 for (d=0; d < delay/10; d++) i++;		  // delay*2 for AT89C52

}


static
BYTE CardType;			/* b0:MMC, b1:SDv1, b2:SDv2, b3:Block addressing */





/*-----------------------------------------------------------------------*/
/* Transmit a byte to the MMC (bitbanging)                               */
/*-----------------------------------------------------------------------*/

static
void xmit_mmc (
	BYTE d			/* Data to be sent */
)
{
// BYTE j=0;
 
//unsigned char SPI_count; // counter for SPI transaction
//SCK=0;
//for (SPI_count = 8; SPI_count > 0; SPI_count--) // single byte SPI loop
//{
//MOSI = d & 0x80; // put current outgoing bit on MOSI
//d = SPI_byte << 1; // shift next bit into MSB
//SCK = 1; // set SCK high
//d |= MISO; // capture current bit on MISO
//SCK = 0; // set SCK low
//}


//	if (d & 0x80) DI_H(); else DI_L();	/* bit7 */
//	CK_H();   CK_L();  
//	if (d & 0x40) DI_H(); else DI_L();	/* bit6 */
//	CK_H();   CK_L();  
//	if (d & 0x20) DI_H(); else DI_L();	/* bit5 */
//	CK_H();   CK_L(); 
//	if (d & 0x10) DI_H(); else DI_L();	/* bit4 */
//	CK_H();  CK_L();	 
//	if (d & 0x08) DI_H(); else DI_L();	/* bit3 */
//	CK_H();  CK_L();	 
//	if (d & 0x04) DI_H(); else DI_L();	/* bit2 */
//	CK_H();  CK_L();	   
//	if (d & 0x02) DI_H(); else DI_L();	/* bit1 */
//	CK_H();  CK_L();	  
//	if (d & 0x01) DI_H(); else DI_L();	/* bit0 */
//	CK_H();  CK_L();

output(SPI_WR,d);

}



/*-----------------------------------------------------------------------*/
/* Receive a byte from the MMC (bitbanging)                              */
/*-----------------------------------------------------------------------*/

static
BYTE rcvr_mmc (void)
{
	BYTE r;


//	DI_H();	/* Send 0xFF */

//	r = 0;   if (DO) r++;	/* bit7 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit6 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit5 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit4 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit3 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit2 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit1 */
//	CK_H(); CK_L();
//	r <<= 1; if (DO) r++;	/* bit0 */
//	CK_H(); CK_L();
        
        output(SPI_WR,0xff);
    r = input(SPI_RD);
	return r;
}


/*---------------------*/
/* Wait for card ready */

//static
//BYTE wait_ready()
//{
//	BYTE data res;
//
//UINT	Timer = 5000;			/* Wait for ready in timeout of 500ms */
//	rcvr_mmc ();
//	do
//	{
//		res = rcvr_mmc ();
//	}
//	while ((res != 0xFF) && Timer--);
//
//	return res;
//}


/*-----------------------------------------------------------------------*/
/* Skip bytes on the MMC (bitbanging)                                    */
/*-----------------------------------------------------------------------*/

static
void skip_mmc (
	WORD n		/* Number of bytes to skip */
)
{
//	DI_H();	/* Send 0xFF */

	do {
	output(SPI_WR,0xff);
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
//		CK_H(); CK_L();
	} while (--n);

}


/*-----------------------------------------------------------------------*/
/* Deselect the card and release SPI bus                                 */
/*-----------------------------------------------------------------------*/

static
void release_spi (void)
{
	CS_H();
	rcvr_mmc();
}


/*-----------------------------------------------------------------------*/
/* Send a command packet to MMC                                          */
/*-----------------------------------------------------------------------*/
// RE-ENTRANT !
static
BYTE send_cmd (
	BYTE cmd,		/* Command byte */
	DWORD arg		/* Argument */
)  
{
	BYTE n, res;


//   if (wait_ready() != 0xFF)
//	{
//		return 0xFF;
//	}


	if (cmd & 0x80) {	/* ACMD<n> is the command sequense of CMD55-CMD<n> */
		cmd &= 0x7F;
		res = send_cmd(CMD55, 0);
		if (res > 1) return res;
	}

	/* Select the card */
	CS_H(); rcvr_mmc();
	CS_L(); rcvr_mmc();

	/* Send a command packet */
	xmit_mmc(cmd);					/* Start + Command index */
	xmit_mmc((BYTE)(arg >> 24));	/* Argument[31..24] */
	xmit_mmc((BYTE)(arg >> 16));	/* Argument[23..16] */
	xmit_mmc((BYTE)(arg >> 8));		/* Argument[15..8] */
	xmit_mmc((BYTE)arg);			/* Argument[7..0] */
	n = 0x01;						/* Dummy CRC + Stop */
	if (cmd == CMD0) n = 0x95;		/* Valid CRC for CMD0(0) */
	if (cmd == CMD8) n = 0x87;		/* Valid CRC for CMD8(0x1AA) */
	xmit_mmc(n);

	/* Receive a command response */
	n = 10;								/* Wait for a valid response in timeout of 10 attempts */
	do {
		res = rcvr_mmc();
	} while ((res & 0x80) && --n);

	return res;			/* Return with the response value */
}



/*--------------------------------------------------------------------------

   Public Functions

---------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (void)
{
	BYTE n, cmd, ty, buf[4];
	UINT tmr;


	CS_H();
	skip_mmc(100);			/* Dummy clocks */

	ty = 0;
	if (send_cmd(CMD0, 0) == 1) {			/* Enter Idle state */
		if (send_cmd(CMD8, 0x1AA) == 1) {	/* SDv2 */
			for (n = 0; n < 4; n++) buf[n] = rcvr_mmc();	/* Get trailing return value of R7 resp */
			if (buf[2] == 0x01 && buf[3] == 0xAA) {			/* The card can work at vdd range of 2.7-3.6V */
				for (tmr = 1000; tmr; tmr--) {				/* Wait for leaving idle state (ACMD41 with HCS bit) */
					if (send_cmd(ACMD41, 1UL << 30) == 0) break;
					DLY_US(1000);
				}
				if (tmr && send_cmd(CMD58, 0) == 0) {		/* Check CCS bit in the OCR */
					for (n = 0; n < 4; n++) buf[n] = rcvr_mmc();
					ty = (buf[0] & 0x40) ? CT_SD2 | CT_BLOCK : CT_SD2;	/* SDv2 (HC or SC) */
				}
			}
		} else {							/* SDv1 or MMCv3 */
			if (send_cmd(ACMD41, 0) <= 1) 	{
				ty = CT_SD1; cmd = ACMD41;	/* SDv1 */
			} else {
				ty = CT_MMC; cmd = CMD1;	/* MMCv3 */
			}
			for (tmr = 1000; tmr; tmr--) {			/* Wait for leaving idle state */
				if (send_cmd(ACMD41, 0) == 0) break;
				DLY_US(1000);
			}
			if (!tmr || send_cmd(CMD16, 512) != 0)			/* Set R/W block length to 512 */
				ty = 0;
		}
	}
	CardType = ty;
	release_spi();

	return ty ? 0 : STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Read partial sector                                                   */
/*-----------------------------------------------------------------------*/

DRESULT disk_readp (
	BYTE *buff,		/* Pointer to the read buffer (NULL:Read bytes are forwarded to the stream) */
	DWORD lba,		/* Sector number (LBA) */
	WORD ofs,		/* Byte offset to read from (0..511) */
	WORD cnt		/* Number of bytes to read (ofs + cnt mus be <= 512) */
)
{
	DRESULT res;
	BYTE d;
	WORD bc, tmr;


	if (!(CardType & CT_BLOCK)) lba *= 512;		/* Convert to byte address if needed */

	res = RES_ERROR;
	if (send_cmd(CMD17, lba) == 0) {		/* READ_SINGLE_BLOCK */

		tmr = 1000;
		do {							/* Wait for data packet in timeout of 100ms */
			DLY_US(100);
			d = rcvr_mmc();
		} while (d == 0xFF && --tmr);

		if (d == 0xFE) {				/* A data packet arrived */
			bc = 514 - ofs - cnt;

			/* Skip leading bytes */
			if (ofs) skip_mmc(ofs);

			/* Receive a part of the sector */
			if (buff) {	/* Store data to the memory */
				do
					*buff++ = rcvr_mmc();
				while (--cnt);
			} else {	/* Forward data to the outgoing stream */
				do {
					d = rcvr_mmc();
				//	FORWARD(d);
				} while (--cnt);
			}

			/* Skip trailing bytes and CRC */
			skip_mmc(bc);

			res = RES_OK;
		}
	}

	release_spi();

	return res;
}



/*-----------------------------------------------------------------------*/
/* Write partial sector                                                  */
/*-----------------------------------------------------------------------*/
#if _USE_WRITE

DRESULT disk_writep (
    const BYTE *buff,	/* Pointer to the bytes to be written (NULL:Initiate/Finalize sector write) */
	DWORD sa			/* Number of bytes to send, Sector number (LBA) or zero */
)
{
	DRESULT res;
	WORD bc, tmr;
	static WORD wc;


	res = RES_ERROR;

	if (buff) {		/* Send data bytes */
		bc = (WORD)sa;
		while (bc && wc) {		/* Send data bytes to the card */
			xmit_mmc(*buff++);
			wc--; bc--;
		}
		res = RES_OK;
	} else {
		if (sa) {	/* Initiate sector write process */
			if (!(CardType & CT_BLOCK)) sa *= 512;	/* Convert to byte address if needed */
			if (send_cmd(CMD24, sa) == 0) {			/* WRITE_SINGLE_BLOCK */
				xmit_mmc(0xFF); xmit_mmc(0xFE);		/* Data block header */
				wc = 512;							/* Set byte counter */
				res = RES_OK;
			}
		} else {	/* Finalize sector write process */
			bc = wc + 2;
			while (bc--) xmit_mmc(0);	/* Fill left bytes and CRC with zeros */
			if ((rcvr_mmc() & 0x1F) == 0x05) {	/* Receive data resp and wait for end of write process in timeout of 300ms */
				for (tmr = 10000; rcvr_mmc() != 0xFF && tmr; tmr--)	/* Wait for ready (max 1000ms) */
					DLY_US(100);
				if (tmr) res = RES_OK;
			}
			release_spi();
		}
	}

	return res;
}
#endif
