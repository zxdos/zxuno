#include "spi.h"
#include "osd.h"

int SDHCtype;

// #define SPI_WAIT(x) while(HW_PER(PER_SPI_CS)&(1<<PER_SPI_BUSY));
// #define SPI(x) {while((HW_PER(PER_SPI_CS)&(1<<PER_SPI_BUSY))); HW_PER(PER_SPI)=(x);}
// #define SPI_READ(x) (HW_PER(PER_SPI)&255)

#define SPI(x) HW_SPI(HW_SPI_DATA)=(x)
// #define SPI_PUMP(x) HW_SPI(HW_SPI_PUMP)
#define SPI_READ(x) (HW_SPI(HW_SPI_DATA)&255)

#define SPI_CS(x) {while((HW_SPI(HW_SPI_CS)&(1<<HW_SPI_BUSY))); HW_SPI(HW_SPI_CS)=(x);}

#define cmd_reset(x) cmd_write(0x950040,0) // Use SPI mode
#define cmd_init(x) cmd_write(0xff0041,0)
#define cmd_read(x) cmd_write(0xff0051,x)
#define cmd_writesector(x) cmd_write(0xff0058,x)
#define cmd_CMD8(x) cmd_write(0x870048,0x1AA)
#define cmd_CMD16(x) cmd_write(0xFF0050,x)
#define cmd_CMD41(x) cmd_write(0x870069,0x40000000)
#define cmd_CMD55(x) cmd_write(0xff0077,0)
#define cmd_CMD58(x) cmd_write(0xff007A,0)

#define puts OSD_Puts
#define putchar OSD_Putchar

#ifdef SPI_DEBUG
#define DBG(x) puts(x)
#else
#define DBG(X)
#endif

unsigned char SPI_R1[6];


static int SPI_PUMP()
{
	int r=0;
	SPI(0xFF);
	r=SPI_READ();
	SPI(0xFF);
	r=(r<<8)|SPI_READ();
	SPI(0xFF);
	r=(r<<8)|SPI_READ();
	SPI(0xFF);
	r=(r<<8)|SPI_READ();
	return(r);
}

static int cmd_write(unsigned long cmd, unsigned long lba)
{
	int ctr;
	int result=0xff;

	DBG("In cmd_write\n");

	SPI(cmd & 255);

	DBG("Command sent\n");

	if(!SDHCtype)	// If normal SD then we have to use byte offset rather than LBA offset.
		lba<<=9;

	DBG("Sending LBA!\n");

	SPI((lba>>24)&255);
	DBG("Sent 1st byte\n");
	SPI((lba>>16)&255);
	DBG("Sent 2nd byte\n");
	SPI((lba>>8)&255);
	DBG("Sent 3rd byte\n");
	SPI(lba&255);
	DBG("Sent 4th byte\n");

	DBG("Sending CRC - if any\n");

	SPI((cmd>>16)&255); // CRC, if any

	ctr=40000;

	result=SPI_READ();
	while(--ctr && (result==0xff))
	{
		SPI(0xff);
		result=SPI_READ();
	}
	#ifdef SPI_DEBUG
	putchar('0'+(result>>4));
	putchar('0'+(result&15));
	#endif
//	printf("Got result %d \n",result);

	return(result);
}


static void spi_spin()
{
//	puts("SPIspin\n");
	int i;
	for(i=0;i<200;++i)
		SPI(0xff);
//	puts("Done\n");
}


static int wait_initV2()
{
	int i=2000;
	int r;
	spi_spin();
	while(--i)
	{
		if((r=cmd_CMD55())==1)
		{
//			printf("CMD55 %d\n",r);
			SPI(0xff);
			if((r=cmd_CMD41())==0)
			{
//				printf("CMD41 %d\n",r);
				SPI(0xff);
				return(1);
			}
//			else
//				printf("CMD41 %d\n",r);
			spi_spin();
		}
//		else
//			printf("CMD55 %d\n",r);
	}
	return(0);
}


static int wait_init()
{
	int i=20;
	int r;
	SPI(0xff);
//	puts("Cmd_init\n");
	while(--i)
	{
		if((r=cmd_init())==0)
		{
//			printf("init %d\n  ",r);
			SPI(0xff);
			return(1);
		}
//		else
//			printf("init %d\n  ",r);
		spi_spin();
	}
	return(0);
}


static int is_sdhc()
{
	int i,r;

	spi_spin();

	r=cmd_CMD8();		// test for SDHC capability
//	printf("cmd_CMD8 response: %d\n",r);
	if(r!=1)
	{
		wait_init();
		return(0);
	}

	r=SPI_PUMP();
	if((r&0xffff)!=0x01aa)
	{
//		printf("CMD8_4 response: %d\n",r);
		wait_init();
		return(0);
	}

	SPI(0xff);

	// If we get this far we have a V2 card, which may or may not be SDHC...

	i=50;
	while(--i)
	{
		if(wait_initV2())
		{
			if((r=cmd_CMD58())==0)
			{
//				printf("CMD58 %d\n  ",r);
				SPI(0xff);
				r=SPI_READ();
//				printf("CMD58_2 %d\n  ",r);
				SPI(0xff);
				SPI(0xff);
				SPI(0xff);
				SPI(0xff);
				if(r&0x40)
					return(1);
				else
					return(0);
			}
//			else
//				printf("CMD58 %d\n  ",r);
		}
		if(i==2)
		{
			puts("SDHC error!\n");
			return(0);
		}
	}
	return(0);
}


int sd_init()
{
	int j;
	int i;
	int r;
	SDHCtype=1;
	j=5;
	while(--j)
	{
		SPI_CS(0);	// Disable CS
		spi_spin();
		puts("SD init...\n");
	//	puts("SPI Init()\n");
		DBG("Activating CS\n");
		SPI_CS(1);
		i=50;
		while(--i)
		{
			if(cmd_reset()==1) // Enable SPI mode
			{
				i=1;
				j=1;
			}
			DBG("Sent reset command\n");
			if(i==2)
			{
				puts("SD card reset failed!\n");
				return(0);
			}
		}
	}
	DBG("Card responded to reset\n");
	SDHCtype=is_sdhc();
	if(SDHCtype)
		DBG("SDHC card detected\n");
	else 	// Not SDHC? Set blocksize to 512.
	{
		DBG("Sending cmd16\n");
		cmd_CMD16(1);
	}
	SPI(0xFF);
	SPI_CS(0);
	SPI(0xFF);
	DBG("Init done\n");

	return(1);
}


#ifndef DISABLE_WRITE
int sd_write_sector(unsigned long lba,unsigned char *buf) // FIXME - Stub
{
    int i,t,timeout;

	SPI(0xff);
	SPI_CS(1|(1<<HW_SPI_FAST));
	SPI(0xff);

	t=cmd_writesector(lba);
	if(t!=0)
	{
		puts("Write failed\n");
//		printf("Read command failed at %d (%d)\n",lba,r);
		return(1);
	}

    SPI(0xFF); // one byte gap
    SPI(0xFE); // send Data Token

    // send sector bytes
    for (i = 0; i < 128; i++)
	{
		int t=*(int *)buf;
		SPI((t>>24)&255);
		SPI((t>>16)&255);
		SPI((t>>8)&255);
		SPI(t&255);
		buf+=4;
	}

    SPI(0xFF); // send CRC lo byte
    SPI(0xFF); // send CRC hi byte
    SPI(0xFF); // Pump the response byte

    timeout = 100000;
	do
	{
	    SPI(0xFF);
		i=SPI_READ();
	}
	while((i==0) && --timeout);
	SPI(0xff);
	SPI_CS(0);
	return(0);
}
#endif


int sd_read_sector(unsigned long lba,unsigned char *buf)
{
	int result=0;
	int i;
	int r;
//	printf("sd_read_sector %d, %d\n",lba,buf);
	SPI(0xff);
	SPI_CS(1|(1<<HW_SPI_FAST));
	SPI(0xff);

	r=cmd_read(lba);
	if(r!=0)
	{
		puts("Read failed\n");
//		printf("Read command failed at %d (%d)\n",lba,r);
		return(result);
	}

	i=1500000;
	while(--i)
	{
		int v;
		SPI(0xff);
//		SPI_WAIT();
		v=SPI_READ();
		if(v==0xfe)
		{
			int j;

			for(j=0;j<128;++j)
			{
				int t,v;

				t=SPI_PUMP();
				*(int *)buf=t;
//				printf("%d: %d\n",buf,t);
				buf+=4;
			}

			i=1; // break out of the loop
			result=1;
		}
	}
	SPI(0xff);
	SPI(0xff); 	// Discard Two CRC bytes
	SPI_CS(0);
	return(result);
}

int sd_ishc()
{
	return(SDHCtype);
}

