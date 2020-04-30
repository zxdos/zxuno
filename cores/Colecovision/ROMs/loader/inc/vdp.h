
#ifndef _VDP_H
#define _VDP_H

#define uint8 unsigned char
#define uint16 unsigned int

#define peek(A) (*(volatile unsigned int*)(A))
#define poke(A,V) *(volatile unsigned int*)(A)=(V)

__sfr __at 0xA0 VDP_DATA;
__sfr __at 0xA1 VDP_CMD;

enum {
	COLOR_TRANSP = 0,
	COLOR_BLACK,
	COLOR_MGREEN,
	COLOR_LGREEN,
	COLOR_BLUE,
	COLOR_LBLUE,
	COLOR_RED,
	COLOR_CYAN,
	COLOR_MRED,
	COLOR_LRED,
	COLOR_YELLOW,
	COLOR_LYELLOW,
	COLOR_GREEN,
	COLOR_MAGENTA,
	COLOR_GRAY,
	COLOR_WHITE	
};

void vdp_writereg(uint8 reg, uint8 val);
void vdp_setaddr(uint16 addr, uint8 rw);
void vdp_writedata(uint8 *source, uint16 addr, uint16 count);
void vdp_init();
void vdp_setcolor(uint8 border, uint8 background, uint8 foreground);
void vdp_cls();
void vdp_gotoxy(uint8 x, uint8 y);
void vdp_putcharxy(uint8 x, uint8 y, uint8 c);
void vdp_putchar(uint8 c);
void vdp_putcharcolor(uint8 c, uint8 color);
void vdp_putstring(char *s);

#endif	/* _VDP_H */