#include "coleco.h"
#include "getput1.h"

#define sprgen  0x1b00 /* sprite_attribute_table */

#define MAXVITESSE 8

extern byte sprites_pattern_rle[];

static int sinus_y[] = {                                        0xff00,
                                                         0xff08,
                                                  0xff22,
                                           0xff4a,
                                    0xff80,
                             0xffbd,
                      0x0000,0x0042,0x007f,0x00b5,0x00dd,0x00f7,0x0100,
                                                         0x00f7,
                                                  0x00dd,
                                           0x00b5,
                                    0x007f,
                             0x0042,
                      0x0000,0xffbd,0xff80,0xff4a,0xff22,0xff08,0xff00,
                                                         0xff08,
                                                  0xff22,
                                           0xff4a,
                                    0xff80,
                             0xffbd};

static int *sinus_x = &sinus_y[6];

typedef struct
{
 unsigned int yy;
 unsigned int xx;
 int step_yy;
 int step_xx;
 byte y;
 byte x;
 char orientation;
} vaisseau;

vaisseau players[2];

static char bulle_sens;
static int timer_bulle;

unsigned score[2];

static unsigned int min_xx = 0x1000;
static unsigned int min_yy = 0x1000;
static unsigned int max_xx = 0xe000;
static unsigned int max_yy = 0xa000;

static void init_vaisseau(void)
{
    byte i;
    for (i=0;i<2;i++)
    {
        players[i].step_yy = 0;
        players[i].step_xx = 0;
        players[i].orientation = rnd_byte(0,23);
    }
    players[0].yy = min_yy;
    players[0].xx = min_xx;
    players[1].yy = max_yy;
    players[1].xx = max_xx;
}

static void update_vaisseau(void)
{
    byte i;
    for (i=0;i<2;i++)
    {
        players[i].yy += players[i].step_yy;
        if (players[i].yy < min_yy)
        {
         players[i].yy += max_yy;
         players[i].yy -= min_yy;
        } 
        if (players[i].yy > max_yy)
        {
         players[i].yy -= max_yy;
         players[i].yy += min_yy;
        } 
        players[i].xx += players[i].step_xx;        
        if (players[i].xx < min_xx)
        {
         players[i].xx += max_xx;
         players[i].xx -= min_xx;
        } 
        if (players[i].xx > max_xx)
        {
         players[i].xx -= max_xx;
         players[i].xx += min_xx;
        } 
        sprites[i].y  = intdiv256(players[i].yy);
        sprites[i].x  = intdiv256(players[i].xx);
        sprites[i].pattern  = players[i].orientation<<2;
    }
    put_vram(sprgen, sprites, 13);
}

static void update_propulsion(byte i)
{
    int stepy, stepx;
    int y = players[i].step_yy; 
    int x = players[i].step_xx; 
    stepy = sinus_y[players[i].orientation];
    stepx = sinus_x[players[i].orientation];
    y += stepy;
    x += stepx;
    if (y > -2048 && y < 2048)
    {
     if (x > -2048 && x < 2048)
     {
      players[i].step_yy = y;
      players[i].step_xx = x;
     }
    }
}

static int reduce_speed = 8;

static void reduce_step(int *step)
{
    int s = *step;
    if (s<0)
    {
        if ( s > -reduce_speed ) s = 0; else s += reduce_speed;
    }
    if (s>0)
    {
        if ( s < reduce_speed ) s = 0; else s -= reduce_speed;
    }    
    *step = s;
}

static void ralentir()
{
    byte i;
    for (i=0;i<2;i++)
    {
        reduce_step(&players[i].step_yy);
        reduce_step(&players[i].step_xx);
    }    
}

static void update_orientation(byte i, char step)
{
    players[i].orientation += step;
    while (players[i].orientation<0) players[i].orientation +=24;
    while (players[i].orientation>23) players[i].orientation -=24;
}

extern byte got_bulle(byte i);

static void init_bulle()
{
    bulle_sens = get_random() & 8;
    bulle_sens -= 4;
    sprites[2].x = intdiv256(rnd(min_xx,max_xx));
    sprites[2].y = intdiv256(rnd(min_yy,max_yy));
    timer_bulle = 600;
    if (got_bulle(0)||got_bulle(1)) sprites[2].y = 207;
}

static void update_bulle(void)
{
    byte i = sprites[2].pattern;
    i += bulle_sens;
    if (i<96) i=112;
    if (i>112) i=96;
    sprites[2].pattern = i;
    timer_bulle -= 10;
    if (timer_bulle<=0) init_bulle();
}

static void show_score(void)
{
    print_at(4,0,str(score[0]));
    print_at(22,0,str(score[1]));
}

static void check_player_bulle(void)
{
    byte i;
    for (i=0;i<2;i++)
    {
        if (got_bulle(i))
        {
            score[i] += timer_bulle;
            show_score();
            play_sound(1);
            init_bulle();
        }
    }        
}

static void init_ciel(void)
{
    byte i,x,y;
    disable_nmi();
    for (i=0;i<3;i++)
    {
     for (y=2;y<22;y++)
     {
      x = rnd_byte(2,29);
      put_char(x,y,'.');
     }
    }
    enable_nmi();
   
    /* Show screen */
    screen_on();

}

void update_player(byte j, byte k)
{
  if (j&RIGHT)
  {
    update_orientation(k,1); 
  }

  if (j&LEFT)
  {
    update_orientation(k,-1); 
  }

  if (j&0xf0)
  {
    update_propulsion(k);
  }
}

void main(void)
{
 /* Default Screen Mode 2 is done in crtcv.as */
 /* Sprites already set to 16x16 pixels */
 
 /* Init score */
 score[0] = 0;
 score[1] = 0;

 /* Upload Data to VRAM */
 load_ascii();
 load_spatternrle(sprites_pattern_rle);
 fill_color(0x20,0xf0,0x60);
 
 /* Init Sprites Table */
 sprites[0].colour=5;
 sprites[1].colour=9;
 sprites[2].colour=7;
 sprites[2].pattern=24;
 sprites[3].y = 0xd0;

 /* Init Game Screen and Parameters */
 init_ciel();
 init_vaisseau();
 init_bulle();
 
 /* start_bgsound */
 play_sound(2);
 play_sound(3);

 /* Game Loop */
 while(score[0]<10000 && score[1]<10000)
 {
  delay(2);
  disable_nmi();
  update_vaisseau();
  update_bulle();
  check_player_bulle();
  enable_nmi();
  
  update_player(joypad_1,0);
  update_player(joypad_2,1);
 }

 /* Move "bulle" offscreen */
 sprites[2].y=207;
 
 /* Slowdown animation */
 timer_bulle = 250;
 while(--timer_bulle>0)
 {
  delay(2);
  disable_nmi();
  update_vaisseau();
  ralentir();
  enable_nmi();
 }
 
 /* stop_bgsound */
 stop_sound(2);
 stop_sound(3);
 
 pause();
}

void nmi(void)
{
}

