// This file must be compiled without the -mnoshortop -mnobyteop flags, since it
// performs byte-oriented accesses to the Character RAM.


#include "osd.h"

int osd_cursory, osd_cursorx;

void OSD_Clear()
{
	volatile unsigned char *p;
	p=OSD_CHARBUFFER;
	
	for(osd_cursory=OSD_ROWS-1;osd_cursory>=0;--osd_cursory)
	{
		for(osd_cursorx=OSD_COLS-1;osd_cursorx>=0;--osd_cursorx)
		{
			*p++=' ';
		}
	}
	osd_cursorx=0;
	osd_cursory=0;
}


void OSD_Scroll()
{
	int i;
	volatile unsigned char *p1,*p2;
	p1=OSD_CHARBUFFER;
	p2=OSD_CHARBUFFER+32;
	for(i=0;i<(512-(2*32));++i) // Leave last row for progress bar
	{
		*p1++=*p2++;
	}
	for(i=0;i<32;++i)
		*p1++=' ';
}


void OSD_Putchar(int c)
{
	while(osd_cursory>14)
	{
		OSD_Scroll();
		--osd_cursory;
	}
	if(c=='\n')
	{
		for(;osd_cursorx<32;++osd_cursorx)
			OSD_CHARBUFFER[(osd_cursory<<5)+osd_cursorx]=' ';
		osd_cursorx=0;
		++osd_cursory;
	}
	else
	{
		OSD_CHARBUFFER[(osd_cursory<<5)+osd_cursorx]=c;
		osd_cursorx++;
	}
	if(osd_cursorx==32)
	{
		osd_cursorx=0;
		++osd_cursory;
	}
}


void OSD_ProgressBar(int v,int bits)
{
	int i,j;
	int x=8;
	int row=15;
	j=(v>>(bits-4))&15;
	for(i=0;i<j;++i)
		OSD_CHARBUFFER[(row<<5)+(x++)]=7;
	j=v>>(bits-7)&7;
	if(j)
		OSD_CHARBUFFER[(row<<5)+(x++)]=j;
	for(;i<15;++i)
		OSD_CHARBUFFER[(row<<5)+(x++)]=32;
}


static int pixelclock=2;
static int osd_syncpolarity;

void OSD_Show(int visible)
{
	int hf, vf;
	int hh,hl,vh,vl;

	osd_syncpolarity=0;
	hf=HW_OSD(REG_OSD_HFRAME);
	vf=HW_OSD(REG_OSD_VFRAME);

//	printf("%x, %x\n",hf, vf);

	// Extract width of frame (hh) and sync pulse (hl)
	hh=hf>>8;
	hl=hf&0xff;
	if(hh<hl)	// Might need to swap, depending on sync polarity
	{
		hl=hh;
		hh=hf&0xff;
		osd_syncpolarity|=2; // Flip HSync polarity
	}

	
	// Extract height of frame (vh) and sync pulse (vl)
	vh=vf>>8;
	vl=vf&0xff;
	if(vh<vl)	// Might need to swap, depending on sync polarity
	{
		vl=vh;
		vh=vf&0xff;
		osd_syncpolarity|=4; // Flip VSync polarity
	}

	hh<<=4;
	vh<<=3;

	if(hh>800)
		pixelclock=3;
	else
		pixelclock=2;

	HW_OSD(REG_OSD_PIXELCLOCK)=(1<<pixelclock)-1;

//	printf("Frame width is %d, frame height is %d\n",hh,vh);

	hl=((hh-100)-160)>>(pixelclock-1);
	vl=((vh-60)-48)/2;

//	printf("OSD Offsets: %d, %d\n",hl,vl);

	HW_OSD(REG_OSD_ENABLE)=osd_syncpolarity|(visible ? 1 : 0);
	HW_OSD(REG_OSD_XPOS)=-hl;
	HW_OSD(REG_OSD_YPOS)=-vl;
}


