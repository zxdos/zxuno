/* *************************** *
 *                             *
 *     DIAMOND DASH            *
 *     by Daniel Bienvenu      *
 *                             *
 *     Minigame compo 2004     *
 *                             *
 * *************************** */

/* No need for sprites support from Coleco library */
#define NO_SPRITES
/* Include Marcel de Kogel's Coleco library */
#include <coleco.h>
/* Include my own toolkit library */
#include <getput1.h>

/* Sprites table */
typedef struct
{
 byte y;
 byte x;
 byte pattern;
 byte colour;
} sprite_t;
sprite_t sprites[2];

/* Data from "tiles.c" to initialise graphics */
extern byte NAMERLE[];
extern byte PATTERNRLE[];
extern byte COLORRLE[];

/* Char array for "GAME OVER" */
static byte game_over[] = {33,34,35,36,37,38};
/* Char array for "DIAMOND DASH!!" */
static byte game_title[] = {40,41,42,43,44,45,46,47};

/* Data from "holes.c" to draw holes */
extern char *holes_dx[];
extern char *holes_dy[];
extern char holes_size;

/* Number of dynamite */
int dynamite;
/* Score */
unsigned int diamant;
/* Timer */
unsigned int timer;
/* Diamonds value */
unsigned int diamant_score[] = {1,3,5};
/* Number of diamonds needed to finish the level */
byte nombre_diamants;

byte minimum_diamants[]={85,75,60,45,35};

/* Classic coordinate structure */
typedef struct {
	char x;
	char y;
	char dx;
	char dy;
} coorxy;

/* Player : coordinate */
static coorxy player;

/* Dynamite : coordinate */
static coorxy one_dynamite;
/* Dynamite : countdown before explosion */
static byte dynamite_countdown;

/* Initialise characters graphics in VideoRAM */
static void init_graphics(void)
{
 /* Load characters pattern and color */ 
 rle2vram(PATTERNRLE,0x0000);
 rle2vram(COLORRLE,0x2000);
 /* Set sprites pattern as characters pattern */
 vdp_out(6,0);
}

/* Show score, timer and number of dynamites */
static show_score(void)
{
 put_at(6,23,str(diamant),5);
 put_at(14,23,str(timer),4);
 put_at(23,23,str(dynamite),5);
}

/* Add diamonds function */
static void add_diamond(byte nombre, byte diamond_type)
{

   char x,y,k;
   char dx,dy;
loop2:
   x = rnd_byte(1,30);
   y = rnd_byte(4,21);
   if (get_char(x,y)!=1) goto loop2;
   for (dx=-1;dx<2;dx++)
   {
    for (dy=-1;dy<2;dy++)
    {
     k = get_char(x+dx,y+dy);
     if (k==2) goto loop2;
    }
   }
   put_char(x,y,2+diamond_type);
   nombre--;
   if (nombre!=0) goto loop2;
}

/* Add holes function */
static void add_holes(byte nombre)
{
   char x,y,k,type;
   char dx,dy,size;
loop3:
   x = rnd_byte(3,28);
   y = rnd_byte(8,21);
   type = get_random()&1;
   size=holes_size;
   while(size--!=0)
   {
    dx=(holes_dx[type])[size];
    dy=(holes_dy[type])[size];
    k = get_char(x+dx,y+dy);
    if (k!=1) goto loop3;
   }
   size=holes_size;
   while(size--!=0)
   {
    dx=(holes_dx[type])[size];
    dy=(holes_dy[type])[size];
    put_char(x+dx,y+dy,2);
   }
   nombre--;
   /* add dynamite pack in the last two holes */
   if (nombre==2) put_char(x,y,7);
   if (nombre<2) put_char(x,y,31);
   /* loop */
   if (nombre!=0) goto loop3;
}

/* Draw a new mountain */
static new_mountain(void)
{
 /* Blank screen */
 screen_off();
 /* Load default mountain screen */
 rle2vram(NAMERLE,0x1800);
 /* Initialise player's coordinate and sprite pattern */
 player.x = 22;
 player.y = 2;
 player.dx = 0;
 player.dy = 0;
 sprites[0].pattern = 64;
 sprites[0].colour = 15;
 /* Add 6 holes */
 add_holes(6);
 /* Add 51 green diamonds */
 add_diamond(51,1);
 /* Add 23 red diamonds */
 add_diamond(23,2);
 /* Add 11 white diamonds */
 add_diamond(11,3);
 /* Show screen */
 screen_on();
}

/* Show sprite */
static show_sprite(void)
{
 /* wait 3 vertical retrace to slowdown the execution */
   enable_nmi();
   delay(3);
   disable_nmi();
 /* Put sprites table directly in VideoRAM */
   put_vram(0x1b00,sprites,8);
}

/* Update player on screen */
static void show_player(byte n)
{
 byte x,y;
 /* convert player's x and y position for normal sprite's position */
 x = player.x<<3;
 y = (player.y<<3)-1;
 /* Switch player's sprite pattern */
 sprites[0].pattern ^=1;
 /* If it's during game */
 if (n==0)
 {
  /* Then animate sprites player movement */
  byte j;
  for (j=0;j<2;j++)
  {
   if (sprites[0].x<x) sprites[0].x +=4;
   if (sprites[0].x>x) sprites[0].x -=4;
   if (sprites[0].y<y) sprites[0].y +=4;
   if (sprites[0].y>y) sprites[0].y -=4;
   show_sprite();
  }
 }
 else
 {
  /* Otherwise, simply set sprites table with player's coordinate */
  sprites[0].x=x;
  sprites[0].y=y;
  show_sprite();
 }
}

static char move_player(void)
{
 byte j,k;
 char x,y;
 /* Animate player */
 show_player(0);
 /* Put a "cavern" character on player */
 put_char(player.x, player.y,2);
 /* Get joystick in port#1 */
 j = joypad_1;
 /* Reset player's direction x and y */
 player.dx = 0;
 player.dy = 0;
 /* Set new player's direction x and y */ 
 if (j & UP) player.dy=-1;
 if (j & DOWN) player.dy=1;
 if (j & LEFT) player.dx=-1;
 if (j & RIGHT) player.dx=1;
 /* If player doesn't move then set 2nd player's sprite pattern, otherwise, set 1st player's sprite pattern */
 if (player.dx==0 && player.dy==0) sprites[0].pattern |= 2; else sprites[0].pattern &= 0xfd; 
 /* If player press fire */
 if (j & FIRE1 && dynamite_countdown==0)
 {
   /* Set new countdown and dynamite coordinate */
   dynamite_countdown=10;
   one_dynamite.x=player.x;
   one_dynamite.y=player.y;
   /* Decrease number of player's dynamite */
   dynamite--;
   /* If player had no dynamite then return "stop game" flag */
   if (dynamite<0) return 0;
   /* Play sound#4 : "schhhhhh" */
   play_sound(4);
 }
 /* Check if there is something in front of the player */
 x = player.x + player.dx;
 y = player.y + player.dy;
 k = get_char(x,y);
 if ((k>1 && k<7)|| k==31)
 {
  /* Update player's coordinate */
  player.x = x; player.y=y;
  /* If it's a diamond, increase score and play sound #1 : "beep" */
  if (k>2 && k<6)
  {
   diamant += diamant_score[k-3]; play_sound(1);
   if (--nombre_diamants==0) {put_char(23,2,6); play_sound(5); play_sound(6);} 
  }
  /* If it's a dynamite pack, increase number of player's dynamite by 3 and play sound #2 */
  if (k==31)
  {
   dynamite += 3; play_sound(2);
  }
  /* If it's the exit, return "stop game" flag */
  if (k==6)
  {
   return 0;
  }
 }
 /* Return "continue game" flag */
 return -1;
}

/* Do a square hole */
static square_hole(byte x, byte y, byte size)
{
 char i,j,k;
 char dx,dy;
 char n = size >> 1;

/* Play sound #2 : "bonk" */
   play_sound(2);

/* Add rocks in mountain */ 
   enable_nmi();
   for (k=0;k<5;k++)
   {
loop1:
    dx = rnd_byte(0,31);
    dy = rnd_byte(2,22);
    if (get_char(dx,dy)!=2) goto loop1; 
    disable_nmi();
    put_char(dx,dy,1);
    enable_nmi();
   }
   disable_nmi();

 dx = 0;
/* Erase whatever it was directly in the center of this futur hole */
 put_char(x,y,2);
/* Do square hole */ 
 x -= n;
 y -= n;
   for (i=0;i<size;i++)
   {
    for (j=0;j<size;j++)
    {
     k = get_char(x,y);
     /* If detect a barrel of powder, keep note of its coordinate */
     if (k==7) {dx=x; dy=y;}
     if (k==1) put_char(x,y,2);
     y++;
    }
    x++;
    y-=size;
   }

 /* If a barrel of powder was detected, do a big square hole */
 if (dx!=0) square_hole(dx, dy, 7);
}

/* Update dynamite countdown and effect */
static void update_dynamite(void)
{
 /* If a dynamite is on screen */
 if (dynamite_countdown!=0)
 {
  /* Decrease countdown counter */
  dynamite_countdown--;

  /* Update dynamite animation on screen */
  if (dynamite_countdown&1)
  {
   put_char(one_dynamite.x,one_dynamite.y,29);
  }
  else
  {
   put_char(one_dynamite.x,one_dynamite.y,30);
  }
  /* If dynamite countdown = 0, then do a small square hole */
  if (dynamite_countdown==0)
  {
   square_hole(one_dynamite.x,one_dynamite.y,3);
  }
 }
}

/* Game engine */
static void game(void)
{
 byte mountains_limit = 5;
 dynamite=0; diamant=0;
next_mountain:
 dynamite = 20;
 new_mountain();
 /* Decrease number of mountain to do */
 mountains_limit--;
 /* Set number of diamonds needed to exit level */
 nombre_diamants = minimum_diamants[mountains_limit];
 timer=2000;
 show_player(1);

 /* Game loop */
 while(move_player())
 {
  if (timer!=0) timer--;
  show_score();
  update_dynamite();
 }

 /* Animate player for the last time */
 show_player(0);

 /* "Game Over" when player had no more dynamite */
 if (dynamite<0)
 {
  play_sound(3); 
  put_at(13,11,game_over,6);
  enable_nmi();
  pause();
  disable_nmi();
 }
 else
 {
  /* If there still a timer bonus */
  while (timer>9)
  {
   /* Update timer and score */
   timer-=10;
   diamant++;
   /* Play sound#1 : "beep" */
   play_sound(1);
   /* Update score and timer on screen */
   show_score();
   /* Wait a short time to slowdown the execution and to let the "beep" sound playing a bit */
   enable_nmi();
    delay(2);
   disable_nmi();
  } 

  /* If there still a timer bonus */
  while (dynamite--!=0)
  {
   /* Update score */
   diamant+=5;
   /* Play sound#1 : "bonk" */
   play_sound(2);
   /* Update score and timer on screen */
   show_score();
   /* Wait a short time to slowdown the execution and to let the "beep" sound playing a bit */
   enable_nmi();
    delay(12);
   disable_nmi();
  }

  /* Play winner music */
  play_sound(5);
  play_sound(6); 

  /* Wait until music ends */
  enable_nmi();
  delay(75);
  disable_nmi(); 

  /* Go to next mountain : if it's the last mountain, redo the last one */
  if (mountains_limit==0) mountains_limit++;
  goto next_mountain;
 }
}

/* main function : starting point of any C program */
void main(void)
{
 /* Default screen mode 2 setting is done in crtcv.as file */
 /* Set Sprites to 8x8 pixels */
 sprites_8x8(); 
 /* Initialise graphics and sounds */
 init_graphics();
 /* Set a "stop point" to let the Video Chip knows that there is only 1 sprite to show */ 
 sprites[1].y=208;
 /* Show a new mountain */
 new_mountain(); 
 /* Show "DIAMOND DASH!!" in center screen */
 put_at(12,11,game_title,8);
 /* Wait until player press fire */
 enable_nmi(); pause(); disable_nmi();
 /* Play game */
 game();
 /* END */
}

/* Non Maskable Interrupt */
void nmi(void)
{
}