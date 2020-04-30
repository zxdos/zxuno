/* GETPUT v1.1 - LIBRARY */
/* LAST UPDATE : 2011-09-02 (YYYY-MM-DD) */


/* ============================= */
/* === NEW ADDITIONS in 2009 === */
/* ============================= */

/* gpm3pget.s */
byte pget (byte x,byte y);
/* gpm3pset.s */
void pset (byte x,byte y,byte c);
/* gpscrmo4.s */
void screen_mode_1_text(void);
/* gpscrmo3.s */
void screen_mode_3_bitmap(void);

/* ============================= */
/* === NEW ADDITIONS in 2005 === */
/* ============================= */

/* gputoa0.as */
void utoa0(unsigned value,void *buffer); /* Derived from Marcel's deKogel library */

/* gplascii.as */
void load_ascii(void); /* call Coleco bios LOAD_ASCII */

/* gpdiv256.as */
int intdiv256(int value);
/* char intdiv256(int value); */

/* gp2rlej.as */
void *rlej2vram (void *rledata,unsigned offset);

/* === score_type : 2 unsigned values === */
/* gpstrsc.as */
typedef struct { 
 unsigned lo; 
 unsigned hi; 
} score_t;
/* gpscoreN.as */
void score_reset (score_t *s);
int score_cmp_equ (score_t *s1,score_t *s2); /* compare score (equal) */
int score_cmp_lt (score_t *s1,score_t *s2); /* compare score (less than) */
int score_cmp_gt (score_t *s1,score_t *s2); /* compare score (greater than) */
void score_add(score_t *s, unsigned value); /* add unsigned value to score */
char *score_str(score_t *s, unsigned nb_digits);
void score_copy (score_t *score_source, score_t *score_destination); /* copy score */


/* ============================= */
/* === NEW ADDITIONS in 2004 === */
/* ============================= */
/*********************************/
/***  FUSION : gprnd + gprndb  ***/
/*********************************/

/* gpchoice.as */
unsigned char choice_keypad (unsigned char min,unsigned char max);

/* gprnd.as */
unsigned rnd(unsigned A, unsigned B); /* return pseudo random within A and B */
unsigned char rnd_byte(unsigned char A,unsigned char B); /* return pseudo random within A and B */
unsigned absdiff(unsigned A, unsigned B); /* return |A-B| */
unsigned char absdiff_byte(unsigned char A,unsigned char B); /* return |A-B| */

/* gpsqrt16.as : optimized square-root function for unsigned value */
unsigned char sqrt16(unsigned value);

/* gpputat.as */
void put_at (char x, char y, void *s, unsigned size);

/* gpfilat.as */
void fill_at (char x, char y, char c, unsigned size);
/* gpfila0.as */
void fill_at0 (char x, char y, unsigned size, char c);

/* gpscreen.as : to select screen NAME to edit and to show */
#define	name_table1	0x1800
#define	name_table2	0x1c00
void screen(unsigned name1, unsigned name2);
void swap_screen(void);

/* gpstrlen.as : to avoid using LIBC */
unsigned char strlen0(void *table);

/* gpframe0.as : (FAST VERSION) no check for border screen and negative values */
void put_frame0(void *table, char x, char y, unsigned char width, unsigned char height);

/* ============================= */
/* === NEW ADDITIONS in 2003 === */
/* ============================= */

/* gpcolrle.as */
void load_colorrle(void *colorrle);

/* gpdsound.as */
void play_dsound (void *sound, unsigned char delay);

/* gpfram0.as */
void put_frame(void *table, char x, char y, unsigned char width, unsigned char height);
/* gpfram1.as */
void get_bkgrnd(void *table, char x, char y, unsigned char width, unsigned char height);

/* ============================= */

/* gpascii.as */
char get_char (unsigned char x,unsigned char y);
void put_char (unsigned char x,unsigned char y,char s);

/* gpcenter.as */
void center_string (unsigned char l,char *s);
/* gpcente0.as */
void center_string0 (char *s, unsigned char l);

/* gpcls.as */
void cls(void);

/* gppause.as */
void pause (void);

/* gppaused.as */
void pause_delay(unsigned i);

/* gp9print.as */
void print_at (unsigned char x, unsigned char y,char *s);

/* gpstr.as */
char *str(unsigned value);

/* ============================= */

/* gpscrtxt.as */
void screen_mode_2_text(void);

/* gpscrbmp.as */
void screen_mode_2_bitmap(void);

/* gpicture.as */
void show_picture(void *picture);

/* gpchar.as */
void upload_default_ascii(unsigned char flags);

/* gppaper.as */
void paper(unsigned char color);

/* ============================= */

/* gpcolor.as !!OBSOLETE!! */
void load_color(void *color);

/* gpnamrle.as */
void load_namerle(void *namerle);

/* gppatrle.as */
void load_patternrle(void *patternrle);

/* gpsptrle.as */
void load_spatternrle(void *spatternrle);

/* ============================= */

/* gp2chg.s */
void change_pattern(unsigned char c, void *pattern, unsigned char l);
/* gp2chg0.s */
void change_pattern0(void *pattern, unsigned char c, unsigned char l);

/* gp2chgs.s */
void change_spattern(unsigned char s, void *pattern, unsigned char N);
/* gp2chgs0.s */
void change_spattern0(void *pattern, unsigned char s, unsigned char N);

/* gp2colr.s */
void change_color(unsigned char c, void *color, unsigned char l);
/* gp2colr0.s */
void change_color0(void *color, unsigned char c, unsigned char l);

/* gp2fill.as */
void fill_color(unsigned char c, unsigned char color, unsigned char n);

/* gp2mlt0.s */
void change_multicolor(unsigned char c, void *color);
/* gp2mlt00.s */
void change_multicolor0(void *color, unsigned char c);

/* gp2mlt1.s */
void change_multicolor_pattern(unsigned char c, void *color, unsigned char n);
/* gp2mlt10.s */
//void change_multicolor_pattern(void *color, unsigned char c, unsigned char n);

/* gp2choic1.as */
unsigned char choice_keypad_1(unsigned char min, unsigned char max);

/* gp2choic2.as */
unsigned char choice_keypad_2(unsigned char min, unsigned char max);

/* gpupdats.as */
void updatesprites(unsigned char first, unsigned char count);

/* gpspritm.as */
void sprites_simple(void);
void sprites_double(void);

/* gpsprits.as */
void sprites_8x8(void);
void sprites_16x16(void);

/* ============================= */

/* Joystick Axes */

#define	UP	1
#define	RIGHT	2
#define	DOWN	4
#define	LEFT	8
#define	FIRE4	16
#define	FIRE3	32
#define	FIRE2	64
#define	FIRE1	128

/* ============================= */
/* ===    SPECIAL EFFECTS    === */
/* ============================= */

/* gpwipedn.as */
void wipe_off_down(void);

/* gpwipeup.as */
void wipe_off_up(void);

