/****************************************************************************/
/**                                                                        **/
/**                                copt.c                                  **/
/**                                                                        **/
/** Coleco ADAM Cosmo Trainer/Cosmo Challenge game main module             **/
/**                                                                        **/
/** Copyright (C) Marcel de Kogel 1997                                     **/
/**     You are not allowed to distribute this software commercially       **/
/**     Please, notify me, if you make any changes to this file            **/
/****************************************************************************/

#include "coleco.h"
#include <string.h>
#include <sys.h>

/* VDP table addresses */
#define name_table              0x1800
#define pattern_table           0x0000
#define colour_table            0x2000
#define sprite_pattern_table    0x3800
#define sprite_attribute_table  0x1b00

/* Pictures in copttabl.c */
extern byte colours_1[];
extern byte colours_2[];
extern byte patterns[];

void nmi (void)
{
}

byte main (byte choice)
{
 byte old_choice;
 byte old_joypad_1,old_joypad_2,new_joypad;
 choice&=1;
 /* initialise name table */
 set_default_name_table (name_table);
 /* enable extended pattern and colour tables */
 vdp_out (3,0xff);
 vdp_out (4,0x03);
 /* Upload picture */
 rle2vram (patterns,pattern_table);
 rle2vram (choice? colours_2:colours_1,colour_table);
 /* turn display on */
 screen_on ();
 /* enable NMI */
 enable_nmi ();
 old_joypad_1=joypad_1;
 old_joypad_2=joypad_2;
 new_joypad=0;
 while ((new_joypad&0xf0)==0)
 {
  /* wait for a VBLANK */
  nmi_flag=0;
  while (nmi_flag==0);
  /* check for joypad events */
  old_choice=choice;
  new_joypad=((joypad_1^old_joypad_1)&joypad_1) |
             ((joypad_2^old_joypad_2)&joypad_2);
  old_joypad_1=joypad_1;
  old_joypad_2=joypad_2;
  if (new_joypad&15)
  {
   /* alter choice */
   choice^=1;
   /* upload new colour table */
   rle2vram (choice? colours_2:colours_1,colour_table);
  }
 }
 /* wait until all buttons etc. are released */
 do
 {
  new_joypad=joypad_1 | joypad_2;
  if (keypad_1!=255 || keypad_2!=255) new_joypad=1;
 }
 while (new_joypad);
 /* return selection */
 return choice;
}
