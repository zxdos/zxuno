/****************************************************************************/
/**                                                                        **/
/**                              ctrainer.c                                **/
/**                                                                        **/
/** ColecoVision Cosmo Trainer game main module                            **/
/**                                                                        **/
/** Copyright (C) Marcel de Kogel 1997                                     **/
/**     You are not allowed to distribute this software commercially       **/
/**     Please, notify me, if you make any changes to this file            **/
/****************************************************************************/

#define NO_SPRITES
#define NO_SOUND
#include "coleco.h"
#include <string.h>
#include <sys.h>

#define sound(a)                outp(0xff,a)
#define sound_volume(c,v)       ( sound((c<<5)|0x90|(15-v)) )
#define sound_frequency(c,f)    ( sound((c<<5)|0x80|(f&15)),sound(f>>4) )

/* VDP table addresses */
#define name_table              0x1800
#define pattern_table           0x0000
#define colour_table            0x2000
#define sprite_pattern_table    0x3800
#define sprite_attribute_table  0x1b00

/* various RLE-encoded tables (in ctr_tabl.c) */
extern byte title_screen[];
extern byte intro_screen[];
extern byte stone_characters[];
extern byte sprite_patterns[];
extern byte stone_table[];

static byte collision;

typedef struct
{
 byte y;
 byte x;
 byte pattern;
 byte colour;
} sprite_t;

#define NUM_SPRITES     14
static sprite_t sprites[NUM_SPRITES];

/* joystick response */
#define ship_speed      3

/* indices to stone_table currently on screen */
static byte stone_line_count;
static byte stones[7][2];

/* stone speed control */
static unsigned speriod;
static unsigned scount;
#define speriod_default 0x040
#define speriod_max     0x200

/* incremented every interrupt */
static byte nmi_count;
/* if 1, the title and intro screens have been displayed */
static byte game_running;
/* 0=one player, 1=two players */
static byte game_mode;

/* status bar */
static byte status_bar[32];
/* health bar */
static byte health_bar[32];
/* scores */
static unsigned score_a,score_b;
/* if 0, player dies */
static byte shield_a,shield_b;

static void scroll_stones (void)
{
 register byte i;
 if (!stone_line_count)
 {
  memcpyf (stones[1],stones[0],12);
  i=get_random ();
  stones[0][0]=(i&128)? (i&31) : 32;
  stones[0][1]=128+((get_random()&3)<<2)+3;
  stone_line_count=4;
 }
 --stone_line_count;
}

static void clear_stones (void)
{
 register byte i;
 for (i=0;i<7;++i)
 {
  stones[i][0]=32;
  stones[i][1]=128+3;
 }
}

static void display_stones (void)
{
 byte i,k,_xor;
 register byte *j;
 unsigned offset;
 _xor=(scount&0x80)? 16:0;
 offset=name_table+32;
 j=stone_table+stones[0][0]*32;
 k=stones[0][1]+stone_line_count*32+32;
 for (i=3-stone_line_count;i;--i,offset+=32,k+=32)
  put_vram_ex (offset,j,32,k,_xor);
 for (i=1;i<6;++i)
 {
  j=stone_table+stones[i][0]*32;
  k=stones[i][1];
  put_vram_ex (offset,j,32,k,_xor); offset+=32;
  put_vram_ex (offset,j,32,k+32,_xor); offset+=32;
  put_vram_ex (offset,j,32,k+64,_xor); offset+=32;
  if (i!=5 || stone_line_count)
   put_vram_ex (offset,j,32,k+96,_xor); offset+=32;
 }
 j=stone_table+stones[6][0]*32;
 k=stones[6][1];
 for (i=1;i<stone_line_count;++i,offset+=32,k+=32)
  put_vram_ex (offset,j,32,k,_xor);
}

/* The NMI routine. Gets called 50 or 60 times per second */
void nmi (void)
{
 register byte i;
 static byte sound_count;
 nmi_count++;
 /* update sprites */
 put_vram (sprite_attribute_table,sprites,sizeof(sprites));
 /* don't scroll stones if no game is in progress */
 if (!game_running) return;
 /* beep if ship hit a stone */
 if (collision) sound_volume(0,15);
 /* update stone display */
 scount+=speriod;
 /* update buffer */
 for (i=scount>>8;i;--i)
 {
  if (!sound_count)
  {
   sound_volume (1,15);
   sound_count=8;
  }
  --sound_count;
  scroll_stones ();
 }
 scount&=0xff;
 /* upload stuff to vram */
 display_stones ();
 /* Update status bar */
 put_vram (name_table,status_bar,32);
 /* Update health bar */
 put_vram (name_table+768-32,health_bar,32);
 sound_volume (0,0);
 sound_volume (1,0);
 collision=0;
}

static sprite_t sprites_init_1[]=
{
 /* ship A */
 { 164,120,0,15 },
 { 164,120,4,4 },
};

static sprite_t sprites_init_2[]=
{
 /* ship A */
 { 164,60,0,15 },
 { 164,60,4,4 },
 /* ship B */
 { 164,180,0,15 },
 { 164,180,4,8 }
};

static sprite_t sprites_init_3[]=
{
 /* ship A */
 { 164,60,0,15 },
 { 164,60,4,4 },
 /* ship B */
 { 164,180,0,15 },
 { 164,180,4,8 },
 /* division line */
 {  8,120,8,11 },
 { 24,120,8,11 },
 { 40,120,8,11 },
 { 56,120,8,11 },
 { 72,120,8,11 },
 { 88,120,8,11 },
 { 104,120,8,11 },
 { 120,120,8,11 },
 { 136,120,8,11 },
 { 148,120,8,11 }
};

static void wait_nmi (void)
{
 nmi_flag=0;
 while (nmi_flag==0);
}

static void centre_string (byte l,char *s)
{
 register unsigned i;
 disable_nmi ();
 i=strlen (s);
 put_vram (name_table+l*32+(32-i)/2,s,i);
 enable_nmi ();
}

static void show_picture (void *picture)
{
 /* turn display off */
 screen_off ();
 /* disable NMI */
 disable_nmi ();
 /* initialise name table */
 set_default_name_table (name_table);
 /* enable extended pattern and colour tables */
 vdp_out (3,0xff);
 vdp_out (4,0x03);
 /* Upload picture */
 rle2vram (rle2vram(picture,colour_table),pattern_table);
 /* turn display on */
 screen_on ();
 /* enable NMI */
 enable_nmi ();
}

static void wait_fire_button (void)
{
 /* wait until fire button is released */
 while ((joypad_1 | joypad_2)&0xf0);
 /* now wait until it's pressed */
 while (((joypad_1 | joypad_2)&0xf0)==0);
}

static void init_vdp (void)
{
 static byte red_font[8]= { 0x61,0x61,0x81,0x81,0x81,0x91,0x91,0x91 };
 static byte yellow_font[8]= { 0xa1,0xa1,0xb1,0xb1,0xb1,0xf1,0xf1,0xf1 };
 static byte score_font[8]= { 0xe0,0xe0,0xe0,0xe0,0xf0,0xf0,0xf0,0xf0 };
 static byte health_patterns[8*4] =
 {
  0x00,0x55,0x55,0x55,0x55,0x55,0x55,0x00,
  0x00,0x54,0x54,0x54,0x54,0x54,0x54,0x00,
  0x00,0x50,0x50,0x50,0x50,0x50,0x50,0x00,
  0x00,0x40,0x40,0x40,0x40,0x40,0x40,0x00
 };
 /* turn display off */
 screen_off ();
 /* disable NMI */
 disable_nmi ();
 /* clear VRAM */
 fill_vram (0,0,0x4000);
 /* Fill colour table */
 put_vram_pattern (colour_table,yellow_font,8,256);
 put_vram_pattern (colour_table+'A'*8,red_font,8,26);
 put_vram_pattern (colour_table+1*8,score_font,8,15);
 /* Upload ASCII character patterns */
 upload_ascii (29,128-29,pattern_table+29*8,BOLD);
 upload_ascii ('A',26,pattern_table+'a'*8,0);
 upload_ascii ('0',10,pattern_table+2*8,BOLD);
 /* Health indicator */
 put_vram (pattern_table+12*8,health_patterns,sizeof(health_patterns));
 /* Upload stones character definitions */
 rle2vram (rle2vram(stone_characters,colour_table+128*8),pattern_table+128*8);
 /* Upload sprite patterns */
 rle2vram (sprite_patterns,sprite_pattern_table);
 /* disable extended pattern and colour tables */
 vdp_out (3,0x9f);
 vdp_out (4,0x00);
 /* Blue screen border */
 vdp_out (7,0xf4);
 /* turn display on */
 screen_on ();
 /* enable NMI */
 enable_nmi ();
}

static void strupr (char *s)
{
 while (*s)
 {
  if (*s>='a' && *s<='z') *s+='A'-'a';
  ++s;
 }
}

static byte get_choice (char *a,char *b,char *c,byte _default)
{
 byte old_joypad_1,old_joypad_2,new_joypad,choice;
 char s[20];
 choice=_default;
 /* clear all stones */
 clear_stones ();
 disable_nmi ();
 display_stones ();
 enable_nmi ();
 old_joypad_1=joypad_1;
 old_joypad_2=joypad_2;
 new_joypad=0;
 while ((new_joypad&0xf0)==0)
 {
  wait_nmi ();
  strcpy (s,a);
  if (choice==0) strupr(s);
  centre_string (11,s);
  strcpy (s,b);
  if (choice==1) strupr(s);
  centre_string (12,s);
  strcpy (s,c);
  if (choice==2) strupr(s);
  centre_string (13,s);
  new_joypad=((joypad_1^old_joypad_1)&joypad_1) |
             ((joypad_2^old_joypad_2)&joypad_2);
  old_joypad_1=joypad_1;
  old_joypad_2=joypad_2;
  if (new_joypad&1)
   if (--choice==255) choice=2;
  if (new_joypad&4)
   if (++choice==3) choice=0;
 }
 return choice;
}

static byte check_collision (byte x)
{
 register byte *i;
 i=stone_table+((stone_line_count)? stones[6][0]:stones[5][0])*32;
 i+=x>>3;
 if (i[0]==255) return 0;
 if (i[0]) return 1;
 if (i[1]) return 1;
 if (i[2] && (x&7)) return 1;
 return 0;
}

static void add_shield_a (char n)
{
 register char i,j;
 i=shield_a+n;
 if (i>56) i=56;
 if (i<0) i=0;
 shield_a=i;
 i>>=2;
 for (j=0;j<i;++j) health_bar[j+1]=12;
 i=shield_a&3;
 if (i) health_bar[(j++)+1]=16-i;
 for (;j<14;++j) health_bar[j+1]=1;
}

static void add_shield_b (char n)
{
 register char i,j;
 i=shield_b+n;
 if (i>56) i=56;
 if (i<0) i=0;
 shield_b=i;
 i>>=2;
 for (j=0;j<i;++j) health_bar[j+17]=12;
 i=shield_b&3;
 if (i) health_bar[(j++)+17]=16-i;
 for (;j<14;++j) health_bar[j+17]=1;
}

void main (void)
{
 register byte i;
 int t;
 byte min_a,min_b,max_a,max_b;
 /* initialise sound chip */
 sound_frequency (0,256);
 sound_frequency (1,128);
 sound_frequency (2,128);
 /* intro pictures */
 show_picture (title_screen);
 wait_fire_button ();
 show_picture (intro_screen);
 wait_fire_button ();
 /* initialise VDP */
 init_vdp ();
options:
 /* clear status bar */
 fill_vram (name_table,1,32);
 memset (sprites,208,sizeof(sprites));
 game_running=0;
 /* get game mode choice */
 game_mode=get_choice ("game a","game b","two players",game_mode);
play_again:
 /* Wait until all buttons etc. are released */
 do
 {
  i=joypad_1|joypad_2;
  if (keypad_1!=0xff || keypad_2!=0xff) i=1;
 }
 while (i);
 /* clear all stones */
 clear_stones ();
 /* set default scrolling speed */
 scount=0;
 speriod=speriod_default;
 /* clear scores */
 score_a=score_b=0;
 /* initialise status bar */
 memset (status_bar,1,sizeof(status_bar));
 utoa (score_a,status_bar+1,2);
 if (game_mode==2)
  utoa (score_b,status_bar+27,2);
 /* set life flag */
 shield_a=99;
 if (game_mode) shield_b=99;
 /* set game_running flag */
 /* initialise health bar */
 memset (health_bar,1,sizeof(health_bar));
 add_shield_a (0);
 add_shield_b (0);
 game_running=1;
 /* clear NMI counter */
 nmi_count=255;
 /* initialise sprite table */
 switch (game_mode)
 {
  case 2:
   min_a=0; max_a=111;
   min_b=129; max_b=240;
   memcpy (sprites,sprites_init_3,sizeof(sprites_init_3));
   break;
  case 1:
   min_a=max_a=0;
   min_b=max_b=240;
   memcpy (sprites,sprites_init_2,sizeof(sprites_init_2));
   break;
  default:
   min_a=min_b=0;
   max_a=max_b=240;
   memcpy (sprites,sprites_init_1,sizeof(sprites_init_1));
   break;
 }
 while (1)
 {
  /* Wait for a VBLANK */
  wait_nmi ();
  if ((nmi_count&31)==0)
  {
   if (++speriod>speriod_max) speriod=speriod_max;
   if (shield_a)
    utoa (++score_a,status_bar+1,2);
   if (shield_b && game_mode!=1)
    utoa (++score_b,status_bar+27,2);
  }
  /* Parse joysticks */
  if (game_mode==1)
  {
   max_a=sprites[2].x-16;
   min_b=sprites[0].x+16;
  }
  if (shield_a)
  {
   t=sprites[0].x;
   t+=spinner_1<<3;
   if (joypad_1&2) t+=ship_speed;
   if (joypad_1&8) t-=ship_speed;
   if (t&0xff00)
   {
    if (t&0x8000) t=0;
    else t=255;
   }
   i=(byte)t;
   if (i<min_a) i=min_a;
   if (i>max_a) i=max_a;
   sprites[0].x=sprites[1].x=i;
   if (check_collision(sprites[0].x))
   {
    collision=1;
    add_shield_a (-1);
   }
  }
  if (game_mode && shield_b)
  {
   t=sprites[2].x;
   t+=spinner_2<<3;
   if (joypad_2&2) t+=ship_speed;
   if (joypad_2&8) t-=ship_speed;
   if (game_mode==1)
   {
    if (joypad_1&0x40) t+=ship_speed;
    if (joypad_1&0x80) t-=ship_speed;
   }
   if (t&0xff00)
   {
    if (t&0x8000) t=0;
    else t=255;
   }
   i=(byte)t;
   if (i<min_b) i=min_b;
   if (i>max_b) i=max_b;
   sprites[2].x=sprites[3].x=i;
   if (check_collision(sprites[2].x))
   {
    collision=1;
    add_shield_b (-1);
   }
  }
  /* Check if game has ended */
  if (!shield_a)
  {
   sprites[0].y=sprites[1].y=207;
   if (game_mode==0 || game_mode==1) break;
   if (game_mode==2 && !shield_b) break;
  }
  if (!shield_b)
  {
   sprites[2].y=sprites[3].y=207;
   if (game_mode==1) break;
  }
 }
 sprites[0].y=sprites[1].y=sprites[2].y=sprites[3].y=207;
 delay (100);
 memset (sprites,208,sizeof(sprites));
 delay (1);
 game_running=0;
 /* clear all stones */
 clear_stones ();
 disable_nmi ();
 display_stones ();
 enable_nmi ();
 i=get_choice ("play again","options","intro",0);
 if (i==0) goto play_again;
 if (i==1) goto options;
 /* startup module will issue a soft reboot */
}
