
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "vdp.h"
#include "font.h"

// __xdata __at (0x7ffe) unsigned int chksum;

uint8 cx, cy, fg, bg;

//------------------------------------------------------------------------------
void vdp_writereg(uint8 reg, uint8 val)
{
	VDP_CMD = val;
	VDP_CMD = (reg & 0x07) | 0x80;
}

//------------------------------------------------------------------------------
void vdp_setaddr(uint16 addr, uint8 rw)
{
	VDP_CMD = addr & 0xFF;
	VDP_CMD = ((addr >> 8) & 0x3F) | ((rw & 0x01) << 6);
}

//------------------------------------------------------------------------------
void vdp_writedata(uint8 *source, uint16 addr, uint16 count)
{
	uint8 i;
	uint16 c;

	vdp_setaddr(addr, 1);
	for (c = 0; c < count; c++) {
		VDP_DATA = source[c];
		for (i=0; i < 10; i++) ;
	}
}

//------------------------------------------------------------------------------
static void vdp_cursorinc()
{
	++cx;
	if (cx > 31) {
		cx = 0;
		++cy;
		if (cy > 23) {
			cy = 23;
//			vdp_rolatela();
		}
	}
}

/*
Control Registers:

Reg/Bit	7	6	5	4	3	2	1	0
0	-	-	-	-	-	-	M2	EXTVID
1	4/16K	BL	GINT	M1	M3	-	SI	MAG
2	-	-	-	-	PN13	PN12	PN11	PN10			L=0x0300(768)		S=0x0800(2048)	E=0x0AFF(2815)
3	CT13	CT12	CT11	CT10	CT9	CT8	CT7	CT6			L=0x0020(32)		S=0x0B00(2816)	E=0x0B20(2836)
4	-	-	-	-	-	PG13	PG12	PG11				L=0x0800(2048)		S=0x0000(000)	E=0x07FF(2047)
5	-	SA13	SA12	SA11	SA10	SA9	SA8	SA7
6	-	-	-	-	-	SG13	SG12	SG11
7	TC3	TC2	TC1	TC0	BD3	BD2	BD1	BD0
*/
/*
	PG = Pattern Gen 	S=0x0000 L=0x0800
	PN = Pattern Name	S=0x0800 L=0x0300
	CT = Color Table	S=0x0B00 L=0x0020
*/
//------------------------------------------------------------------------------
void vdp_init()
{
	uint8 i;
	uint16 c;
	const uint8 init[8] = {0x00, 0xC0, 0x02, 0x2C, 0x00, 0x00, 0x00, 0xF7};

	for (i=0; i < 8; i++) {
		vdp_writereg(i, init[i]);
	}
	vdp_setaddr(0, 1);
	for (c=0; c < 256; c++)
		VDP_DATA = 0;
	vdp_writedata(font, 256, 768);		// 32-7F
	vdp_setaddr(1024, 1);
	for (c=0; c < 1024; c++)
		VDP_DATA = 0;
	cx = cy = 0;
	fg = 15;
	bg = 7;
	vdp_setaddr(2048, 1);
	for (c=0; c < 768; c++)
		VDP_DATA = ' ';
}

//------------------------------------------------------------------------------
void vdp_setcolor(uint8 border, uint8 background, uint8 foreground)
{
	uint8 i;
	uint8 v = ((foreground & 0x0F) << 4) | (background & 0x0F);

	vdp_writereg(7, ((foreground & 0x0F) << 4) | (border & 0x0F));
	vdp_setaddr(0xB00, 1);
	for (i=0; i < 32; i++) {
		VDP_DATA = v;
	}
	fg = foreground;
	bg = background;
}

//------------------------------------------------------------------------------
void vdp_cls()
{
	uint16 c;
	vdp_setaddr(2048, 1);
	for (c=0; c < 768; c++)
		VDP_DATA = ' ';
}

//------------------------------------------------------------------------------
void vdp_gotoxy(uint8 x, uint8 y)
{
	cx = x & 31;
	cy = y;
	if (cy > 23) cy = 23;
}

//------------------------------------------------------------------------------
void vdp_putcharxy(uint8 x, uint8 y, uint8 c)
{
	uint16 addr;

	cx = x & 31;
	cy = y;
	if (cy > 23) cy = 23;
	addr = 0x800 + cy*32 + cx;
	vdp_setaddr(addr, 1);
	VDP_DATA = c;
	vdp_cursorinc();
}

//------------------------------------------------------------------------------
void vdp_putchar(uint8 c)
{
	vdp_putcharxy(cx, cy, c);
}

//------------------------------------------------------------------------------
void vdp_putcharcolor(uint8 c, uint8 color)
{
	uint16 addr = 0xB00 + cx;
	uint8 v = ((color & 0x0F) << 4) | bg;
	vdp_setaddr(addr, 1);
	VDP_DATA = v;
	vdp_putcharxy(cx, cy, c);
}

//------------------------------------------------------------------------------
void vdp_putstring(char *s)
{
	do {
		vdp_putchar(*s);
	} while(*++s);
}
