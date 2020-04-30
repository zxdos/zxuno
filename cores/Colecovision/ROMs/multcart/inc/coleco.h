
#ifndef _COLECO_H
#define _COLECO_H

// UP  0x0001; RIGHT 0x0002; DOWN 0x0004 LEFT 0x0008  RFIRE 0x8000 LFIRE 0x4000
#define _UP    0x0001
#define _DOWN  0x0004
#define _LEFT  0x0008
#define _RIGHT 0x0002
#define _LFIRE 0x4000
#define _RFIRE 0x8000

typedef unsigned char byte;

/*
typedef struct
{
	const void *sound_data;  // added const to void ptr for IAR
	unsigned sound_area;
} sound_t;

#define SOUNDAREA1  (0x702b)
#define SOUNDAREA2  (0x702b+10)
#define SOUNDAREA3  (0x702b+20)
#define SOUNDAREA4  (0x702b+30)
#define SOUNDAREA5  (0x702b+40)
#define SOUNDAREA6  (0x702b+50)
#define SOUNDAREA7  (0x702b+60)
*/

/* Set to 1 if NMI occurs */
extern byte nmi_flag;

void vdp_init(void);
void cls(void);
void delay (unsigned count);
void load_ascii(void); 
void enable_nmi(void);
void disable_nmi(void);
void print_at(unsigned char x, unsigned char y, char *text);
unsigned int read_joy(unsigned char H);
void screen_on (void);
void screen_off (void);
void set_mode1(void);
void set_color(unsigned char color);
void fill_vram(unsigned char x);
//void init_sound(const sound_t *snd_table);
//void play_sound (byte number);
//void stop_sound (byte number);

#endif /*_COLECO_H*/