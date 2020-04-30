/****************************************************************************/
/**                                                                        **/
/**                                 cch.c                                  **/
/**                                                                        **/
/** ColecoVision Cosmo Challenge game main module                          **/
/**                                                                        **/
/** Copyright (C) Marcel de Kogel 1997                                     **/
/**     You are not allowed to distribute this software commercially       **/
/**     Please, notify me, if you make any changes to this file            **/
/****************************************************************************/

#include "coleco.h"
#include <string.h>

/* VDP table addresses */
#define chrtab  0x1800
#define chrgen  0x0000
#define coltab  0x2000
#define sprtab  0x3800
#define sprgen  0x1b00

/* various RLE-encoded tables (in cch_tabl.c) */
extern byte title_screen[];
extern byte intro_screen[];
extern byte stone_characters[];
extern byte sprite_patterns[];

/* sound priorities */
#define shoot_sound_priority            5
#define kill_sound_priority             10
#define block_sound_priority            4
#define hit_sound_priority              5
#define bg_sound_priority               1
#define low_health_sound_priority       9

/* when his health bar reaches 0, one dies */
static byte player1_health,player2_health;
/* incremented every interrupt */
static byte nmi_count;
/* if 1, the title and intro screens have been displayed */
static byte game_running;
/* 0=one player, 1=two players */
static byte game_mode;

/* scrolling stones buffer */
static byte stone_vram[96*2];
/* next stone type to put in buffer */
static byte stonea,stoneb;

/* sound definitions */
static byte bg_sound[]=
{
 0,
 0x63,0x03,0x01,
 0x81,0xe0, 0x99, 8,
 0x81,0x53, 0x99, 8,
 0x81,0xd4, 0x99, 8,
 0x82,0xa6, 0x99, 8,
 0,0,0
};
static byte low_health_sound[]=
{
 0,
 0x80,0x60, 0x95, 0x60,0x01,0xfe, 0x40,0x02,0xff,
 20,
 0x80,0x60, 0x95,
 20,
 0x80,0x60, 0x95,
 20,
 0x80,0x60, 0x95,
 20,
 0x80,0x60, 0x95,
 0,0,0
};
static byte shoot_sound[]=
{
 1,
 0xf8,0xe4, 1,0xf2, 1,0xe4, 1,0x63,0x02,0x01,0xe5, 1,0xe4,
 1,0xe5, 1,0xe4, 1,0xe5, 1,0xe4,
 1,0xe5, 1,0xe4, 1,0xe5, 1,0xe4,
 5,
 0,0,0
};
static byte kill_sound[]=
{
 1,
 0xe4, 0xf8,
 1,0xf4,0xe5, 1,0xf0,0xe4, 1,0xe5, 1,0xe4,
 1,0xe5, 1,0xe4, 0x63,0x05,0x01,
 1,0xe5, 1,0xe4, 1,0xe5, 1,0xe4, 1,0xe5,
 1,0xe6, 1,0xe5, 1,0xe6, 1,0xe5, 1,0xe6,
 63,63,
 0,0,0
};
static byte block_sound[]=
{
 0,
 0x83,0xff,0x90, 2, 0x9f,1,
 0x83,0x00,0x94, 2,
 0,0,0
};
static byte hit_sound[]=
{
 0,
 0x80,0x20, 0x96,1,0x92, 5, 0x94,1,0x96,1,0x98,1,
 0,0,0
};


/* scroll stone stuff one character */
static void scroll_stones (void)
{
 register byte a;
 /* scroll old buffer */
 memcpyb (stone_vram,stone_vram+1,95);
 memcpyf (stone_vram+97,stone_vram+96,95);
 /* check new stones */
 if (!stonea)
 {
  a=get_random();
  if (a<16) stonea=((a&3)<<2)+128+16+32;
 }
 if (!stoneb)
 {
  a=get_random();
  if (a<16) stoneb=((a&3)<<2)+3+32;
 }
 /* put new stones in buffer */
 if (stonea)
 {
  stone_vram[31]=stonea-32;
  stone_vram[31+32]=stonea;
  stone_vram[31+64]=stonea+32;
  stonea++;
  if ((stonea&3)==0) stonea=0;
 }
 else
  stone_vram[31]=stone_vram[31+32]=stone_vram[31+64]=96;
 if (stoneb)
 {
  stone_vram[96]=stoneb-32;
  stone_vram[128]=stoneb;
  stone_vram[160]=stoneb+32;
  stoneb--;
  if ((stoneb&3)==3) stoneb=0;
 }
 else
  stone_vram[96]=stone_vram[128]=stone_vram[160]=96;
}

/* The NMI routine. Gets called 50 or 60 times per second */
void nmi (void)
{
 static byte stone_count;
 register byte i;
 nmi_count++;
 /* if intro screen is being displayed, return immediately */
 if (!game_running) return;
 /* Update sprites */
 update_sprites (32-8,sprgen+8*4);
 /* update stone display */
 switch (stone_count)
 {
  case 6:
   /* scroll 2 pixels */
   put_vram_ex (chrtab+256,stone_vram,96,0xff,128);
   put_vram_ex (chrtab+384,stone_vram+96,96,0xff,128);
   break;
  case 4:
   /* scroll 4 pixels */
   put_vram_ex (chrtab+256,stone_vram,96,0xff,16);
   put_vram_ex (chrtab+384,stone_vram+96,96,0xff,16);
   break;
  case 2:
   /* scroll 6 pixels */
   put_vram_ex (chrtab+256,stone_vram,96,0xff,128|16);
   put_vram_ex (chrtab+384,stone_vram+96,96,0xff,128|16);
   break;
  case 1:
   /* update buffer, will be uploaded next call */
   scroll_stones ();
   break;
  case 0:
   /* upload stone stuff to vram */
   put_vram (chrtab+256,stone_vram,96);
   put_vram (chrtab+384,stone_vram+96,96);
   stone_count=8;
   break;
 }
 stone_count--;
 /* update stars */
 if ((nmi_count&1)==0)
 {
  i=((nmi_count>>1)&7)+16;
  sprites[i].y=get_random();
  sprites[i].x=get_random();
  sprites[i].pattern=28+(get_random()&4);
  sprites[i].colour=get_random()&15;
 }
 /* Update sound */
 update_sound ();
}

static sprite_t sprites_init[]=
{
 /* ship A */
 { 166,60,4,15 },
 { 166,60,8,4 },
 { 166,60,12,8 },
 /* ship B */
 { 8,180,16,15 },
 { 8,180,20,4 },
 { 8,180,24,8 },
 /* 5 bullets each */
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 { 207,0,0,11 },
 /* 8 stars */
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 },
 { 207,0,28,14 }
};

/* to prevent sprites being displayed on the status bar */
static sprite_t default_sprgen[8]=
{
 { -9,0,0,0 },
 { -9,0,0,0 },
 { -9,0,0,0 },
 { -9,0,0,0 },
 { 183,0,0,0 },
 { 183,0,0,0 },
 { 183,0,0,0 },
 { 183,0,0,0 }
};

static void show_player1_health_bar (byte n)
{
 register byte i;
 if (n && player1_health)
 {
  fill_vram (chrtab+736,1,player1_health);
  i=32-player1_health;
  if (i)
   fill_vram (chrtab+736+player1_health,2,i);
 }
 else
  fill_vram (chrtab+736,2,32);
}

static void show_player2_health_bar (byte n)
{
 register byte i;
 if (n && player2_health)
 {
  fill_vram (chrtab,1,player2_health);
  i=32-player2_health;
  if (i)
   fill_vram (chrtab+player2_health,2,i);
 }
 else
  fill_vram (chrtab,2,32);
}

static void player1_is_hit (int spritenr)
{
 sprites[spritenr].y=207;
 if (player1_health)
 {
  if ((player1_health-=4)!=0)
  {
   start_sound (hit_sound,hit_sound_priority);
   if (player1_health<5)
    start_sound (low_health_sound,low_health_sound_priority);
  }
  else
   start_sound (kill_sound,kill_sound_priority);
  show_player1_health_bar(1);
 }
}

static void player2_is_hit (int spritenr)
{
 sprites[spritenr].y=207;
 if (player2_health)
 {
  if ((player2_health-=4)!=0)
  {
   start_sound (hit_sound,hit_sound_priority);
   if (player2_health<5)
    start_sound (low_health_sound,low_health_sound_priority);
  }
  else
   start_sound (kill_sound,kill_sound_priority);
  show_player2_health_bar(1);
 }
}

static void stone_is_hit (int spritenr)
{
 sprites[spritenr].y=207;
 start_sound (block_sound,block_sound_priority);
}

static byte check_stone (byte spritenr)
{
 register unsigned n;
 n=(sprites[spritenr].y)>>3;
 n-=8;
 if (n&0xf8) return 0;
 if (n==3 || n==7) return 0;
 if (n&4) --n;
 n<<=5;
 n+=(sprites[spritenr].x>>3);
 return stone_vram[n]!=96;
}

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
 put_vram (chrtab+l*32+(32-i)/2,s,i);
 enable_nmi ();
}

static void _fill_vram (unsigned offset,byte value,unsigned count)
{
 disable_nmi ();
 fill_vram (offset,value,count);
 enable_nmi ();
}

static void show_picture (void *picture)
{
 /* turn display off */
 screen_off ();
 /* disable NMI */
 disable_nmi ();
 /* Upload picture */
 rle2vram (rle2vram(picture,coltab),chrgen);
 /* turn display on */
 screen_on ();
 /* enable NMI */
 enable_nmi ();
 /* wait until fire button is pressed */
 while ((joypad_1 | joypad_2)&0xf0);
 while (((joypad_1 | joypad_2)&0xf0)==0);
}

static void title (void)
{
 /* initialise name table */
 set_default_name_table (chrtab);
 /* enable extended pattern and colour tables */
 vdp_out (3,0xff);
 vdp_out (4,0x03);
 /* show title screen */
 show_picture (title_screen);
 /* show intro screen */
 show_picture (intro_screen);
}

static void init_vdp (void)
{
 static byte red_font[8]= { 0x61,0x61,0x81,0x81,0x81,0x91,0x91,0x91 };
 static byte yellow_font[8]= { 0xa1,0xa1,0xb1,0xb1,0xb1,0xf1,0xf1,0xf1 };
 register byte i;
 /* turn display off */
 screen_off ();
 /* disable NMI */
 disable_nmi ();
 /* clear VRAM */
 fill_vram (0,0,0x4000);
 /* Upload first 8 sprites */
 put_vram (sprgen,default_sprgen,sizeof(default_sprgen));
 /* Fill colour table */
 put_vram_pattern (coltab,yellow_font,8,256);
 put_vram_pattern (coltab+'0'*8,red_font,8,10);
 /* Upload ASCII character patterns */
 upload_ascii (29,128-29,chrgen+29*8,BOLD_ITALIC);
 /* Health indicator */
 fill_vram (chrgen+9,0x55,6);
 fill_vram (coltab+8,0x90,16);
 /* Upload stones character definitions */
 rle2vram (rle2vram(stone_characters,coltab+256*8),chrgen+256*8);
 /* Upload sprite patterns */
 rle2vram (sprite_patterns,sprtab);
 /* Fill part 2 of name table */
 fill_vram (chrtab+256,96,256);
 /* Copy first pattern and colour tables to third ones */
 for (i=0;i<8;++i)
 {
  get_vram (chrgen+i*256,sprites,256);
  put_vram (chrgen+8*512+i*256,sprites,256);
  get_vram (coltab+i*256,sprites,256);
  put_vram (coltab+8*512+i*256,sprites,256);
 }
 clear_sprites (0,64);
 /* Scroll in stones */
 for (i=32;i;--i) scroll_stones ();
 /* Blue screen border */
 vdp_out (7,0xf4);
 /* turn display on */
 screen_on ();
 /* enable NMI */
 enable_nmi ();
}

static void choice (void)
{
 _fill_vram (chrtab+0,1,32);
 _fill_vram (chrtab+736,1,32);
 _fill_vram (chrtab+18*32,0,64);
 centre_string (18,"1 - One player ");
 centre_string (19,"2 - Two players");
 /* wait until all keys released */
 while (keypad_1!=0xff || keypad_2!=0xff);
 /* get choice */
 game_mode=255;
 while (game_mode==255)
 {
  if (keypad_1==1 || keypad_2==1) game_mode=0;
  if (keypad_1==2 || keypad_2==2) game_mode=1;
 }
 _fill_vram (chrtab+18*32,0,64);
}

void main (void)
{
 register byte i;
 byte old_joypad_1,old_joypad_2;
 title ();
 init_vdp ();
 /* set game_running flag, enables scrolling stones and blinking stars */
 game_running=1;
 /* clear NMI counter */
 nmi_count=255;
options:
 clear_sprites (0,64);
 choice ();
play_again:
 player1_health=player2_health=32;
 show_player1_health_bar(1);
 show_player2_health_bar(1);
 memcpy (sprites,sprites_init,sizeof(sprites_init));
 old_joypad_1=(get_random()&1)? 2:8;
 old_joypad_2=(get_random()&1)? 2:8;
 centre_string (18,"Get ready");
 delay (150);
 _fill_vram (chrtab+18*32,0,64);
 old_joypad_1=old_joypad_2=0;
 while (1)
 {
  /* Wait for a VBLANK */
  wait_nmi ();
  if ((nmi_count&31)==0)
  {
   start_sound (bg_sound,bg_sound_priority);
   if (player1_health<5 || player2_health<5)
   {
    if (player1_health<5) show_player1_health_bar(nmi_count&32);
    if (player2_health<5) show_player2_health_bar(nmi_count&32);
   }
  }
  /* Let computer play */
  if (!game_mode)
  {
   /* direction, slightly random */
   i=get_random();
   if (i<24) joypad_2=(sprites[0].x<sprites[3].x)? 8:2;
   else joypad_2=old_joypad_2&0x0f;
   /* fire ? */
   if ((nmi_count&7)==0) joypad_2|=0x10;
  }
  /* Parse joysticks */
  if (joypad_1&2)
  {
   if (sprites[0].x<241)
    sprites[1].x=sprites[2].x=(++sprites[0].x);
  }
  if (joypad_1&8)
  {
   if (sprites[0].x)
    sprites[1].x=sprites[2].x=(--sprites[0].x);
  }
  if (joypad_2&2)
  {
   if (sprites[3].x<241)
    sprites[4].x=sprites[5].x=(++sprites[3].x);
  }
  if (joypad_2&8)
  {
   if (sprites[3].x)
    sprites[4].x=sprites[5].x=(--sprites[3].x);
  }
  if ((joypad_1^old_joypad_1)&joypad_1&0xf0)
  {
   for (i=6;i<11;++i) if (sprites[i].y==207) break;
   if (i<11)
   {
    sprites[i].y=sprites[0].y;
    sprites[i].x=sprites[0].x+7;
    start_sound (shoot_sound,shoot_sound_priority);
   }
  }
  if ((joypad_2^old_joypad_2)&joypad_2&0xf0)
  {
   for (i=11;i<16;++i) if (sprites[i].y==207) break;
   if (i<16)
   {
    sprites[i].y=sprites[3].y+14;
    sprites[i].x=sprites[3].x+7;
    start_sound (shoot_sound,shoot_sound_priority);
   }
  }
  old_joypad_1=joypad_1;
  old_joypad_2=joypad_2;
  if (player1_health && player2_health)
  {
   for (i=6;i<11;++i)
   {
    if (sprites[i].y!=207)
    {
     if (check_stone(i))
      stone_is_hit (i);
     if (check_collision(sprites+i,sprites+3,0x303,0x303,0x1000,0x0e00))
      player2_is_hit (i);
     if ((sprites[i].y-=4)>192) sprites[i].y=207;
    }
   }
   for (i=11;i<16;++i)
   {
    if (sprites[i].y!=207)
    {
     if (check_stone(i))
      stone_is_hit (i);
     if (check_collision(sprites+i,sprites+0,0x303,0x303,0x1000,0x0e02))
      player1_is_hit (i);
     if ((sprites[i].y+=4)>192) sprites[i].y=207;
    }
   }
  }
  else break;
 }
 i=(player1_health)? 3:0;
 sprites[i].y=sprites[i+1].y=sprites[i+2].y=207;
 clear_sprites (6,10);
 centre_string (18,"1 - Play again");
 centre_string (19,"2 - Options   ");
 centre_string (20,"3 - Intro     ");
 while ((keypad_1==0 || keypad_1>3) &&
        (keypad_2==0 || keypad_2>3));
 if (keypad_1==0 || keypad_1>3) i=keypad_2;
 else i=keypad_1;
 _fill_vram (chrtab+18*32,0,3*32);
 if (i==1) goto play_again;
 if (i==2) goto options;
 /* startup module will issue a soft reboot */
}
