#ifndef SPI_H
#define SPI_H

#define SPIBASE 0xFFFFFFD0
#define HW_SPI(x) *(volatile unsigned int *)(SPIBASE+x)

/* SPI registers */
#define HW_SPI_CS 0x0	/* CS bits are write-only, but bit 15 reads as the SPI busy signal */
#define HW_SPI_DATA 0x04 /* Blocks on both reads and writes, making BUSY signal redundant. */

#define HW_SPI_CS_SD 0
#define HW_SPI_FAST 8
#define HW_SPI_BUSY 15


int sd_init();
int sd_read_sector(unsigned long lba,unsigned char *buf);
int sd_write_sector(unsigned long lba,unsigned char *buf);

int sd_ishc();

#endif
