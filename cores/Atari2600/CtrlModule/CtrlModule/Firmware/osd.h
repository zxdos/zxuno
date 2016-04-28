#ifndef OSD_H
#define OSD_H

/* Hardware registers for an on screen display module. */

#define OSDBASE 0xFFFFFB00

#define HW_OSD(x) *(volatile unsigned int *)(OSDBASE+x)

#define REG_OSD_XPOS 0
#define REG_OSD_YPOS 4
#define REG_OSD_PIXELCLOCK 8
#define REG_OSD_HFRAME 12
#define REG_OSD_VFRAME 16
#define REG_OSD_ENABLE 20

#define OSDCHARBUFFERBASE 0xFFFFFC00
#define OSD_CHARBUFFER ((volatile unsigned char *)(OSDCHARBUFFERBASE)) // Byte accesses only

#define OSD_ROWS 16
#define OSD_COLS 32

extern int osd_cursory, osd_cursorx;

void OSD_Scroll();
void OSD_Clear();
#define OSD_SetX(x) (osd_cursorx=(x&(OSD_COLS-1)))
#define OSD_SetY(x) (osd_cursory=(x&(OSD_ROWS-1)))
void OSD_Putchar(int c);
void OSD_ProgressBar(int v,int bits);

void OSD_Show(int visible);

#endif

