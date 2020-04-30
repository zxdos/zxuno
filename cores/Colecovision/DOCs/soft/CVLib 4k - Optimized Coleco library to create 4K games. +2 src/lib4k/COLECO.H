/****************************************************************************/
/**                                                                        **/
/**                                coleco.h                                **/
/**                                                                        **/
/** C-Prototypes of functions in coleco.as                                 **/
/**                                                                        **/
/** Copyright (C) Marcel de Kogel 1997                                     **/
/**     You are not allowed to distribute this software commercially       **/
/**     Please, notify me, if you make any changes to this file            **/
/****************************************************************************/

/* Lite version by Daniel Bienvenu       */
/* August 5, 2004                        */
/* ===================================== */
/* - Using Coleco BIOS sound functions   */
/* - No more spinner values and calls    */
/* - No 3rd and 4th fire buttons support */
/* - Only 32 (not 64) sprites table      */
/* ===================================== */
/* Warning: Don't work for old           */
/*          coleco projects in C like    */
/*          those based on Cosmo games   */
/*          by Marcel de Kogel           */

/*
   Following #defines can be used:
   NO_OS7       - Don't define the OS7() function
   NO_VDP       - Don't define VDP and VRAM functions
   NO_NMI       - Don't define enable_nmi() and disable_nmi()
   NO_SCREEN    - Don't define screen_on() and screen_off()
   NO_DELAY     - Don't define delay()
   NO_SPRITES   - Don't define sprite structure and sprite functions
                  Implies NO_COLLISION
   NO_COLLISION - Don't define check_collision()
   NO_UTOA      - Don't define utoa()
   NO_RLE       - Don't define RLE functions
   NO_RANDOM    - Don't define get_random()
   NO_MEMCPY    - Don't define memory copying functions
   NO_ASCII     - Don't define upload_ascii()
*/

#ifdef NO_SPRITES
#define NO_COLLISION
#endif

typedef unsigned char byte;

/* If 1, the nmi function will not be called */
extern byte no_nmi;
/* VDP status byte at beginning of NMI */
extern byte vdp_status;
/* Decoded joypad and keypad values */
extern byte joypad_1,joypad_2,keypad_1,keypad_2;
/* Set to 1 if NMI occurs */
extern byte nmi_flag;

#ifndef NO_OS7
/* Call an OS-7 function, AF,BC,DE and HL may be supplied. Please note this
   function does not save IX and IY, so do not use it to call OS functions
   that change these registers */
void os7 (unsigned addr,...);
#endif

#ifndef NO_VDP
/* Write specified VDP register */
void vdp_out (byte reg,byte val);
/* Upload RAM to VRAM. count should be a multiple of 256 */
void put_vram (unsigned offset,void *ptr,unsigned count);
/* Get array of VRAM bytes. count should be a multiple of 256 */
void get_vram (unsigned offset,void *ptr,unsigned count);
/* Fill VRAM area with specified value */
void fill_vram (unsigned offset,byte value,unsigned count);
/* Upload RAM to VRAM, applying specified AND and XOR masks */
void put_vram_ex (unsigned offset,void *ptr,unsigned count,
                  byte and_mask,byte xor_mask);
/* Upload pattern to VRAM */
void put_vram_pattern (unsigned offset,void *pattern,
                       byte psize,unsigned count);
/* Upload default name table */
void set_default_name_table (unsigned offset);
#endif

#ifndef NO_NMI
/* Enable NMI */
void enable_nmi (void);
/* Disable NMI */
void disable_nmi (void);
#endif

#ifndef NO_SCREEN
/* Turn display on */
void screen_on (void);
/* Turn display off */
void screen_off (void);
#endif

#ifndef NO_DELAY
/* wait specified VBLANKs */
void delay (unsigned count);
#endif

typedef struct
{
 void *sound_data;
 unsigned sound_area;
} sound_t;

#define SOUNDAREA1  0x702b
#define SOUNDAREA2  0x702b+10
#define SOUNDAREA3  0x702b+20
#define SOUNDAREA4  0x702b+30
#define SOUNDAREA5  0x702b+40
#define SOUNDAREA6  0x702b+50
#define SOUNDAREA7  0x702b+60

/* Play sound */
void play_sound (byte number);
/* Stop sound */
void stop_sound (byte number);

#ifndef NO_SPRITES
typedef struct
{
 byte y;
 byte x;
 byte pattern;
 byte colour;
} sprite_t;
extern sprite_t sprites[32];
/* Upload sprites to VRAM. Arguments are maximum number of sprites to upload
   (normally 32) and the sprite attribute table offset */
void update_sprites (byte numsprites,unsigned sprtab);
#endif

#ifndef NO_COLLISION
/* Check collision between two sprites. Sizes decode as follows:
 lobyte - first pixel set
 hibyte - number of pixels set */
byte check_collision (sprite_t *sprite1,sprite_t *sprite2,
                      unsigned sprite1_size_hor,unsigned sprite1_size_vert,
                      unsigned sprite2_size_hor,unsigned sprite2_size_vert);
#endif

#ifndef NO_UTOA
/* Convert unsigned integer to ASCII. Leading zeros _are_ put in buffer */
void utoa (unsigned value,void *buffer,byte null_character);
#endif

#ifndef NO_RLE
/* RLE decode specified data to specified RAM area. Returns pointer to
   first unused free */
void *rle2ram (void *rledata,void *dest);
/* RLE decode specified data to specified VRAM area. Returns pointer to
   first unused free */
void *rle2vram (void *rledata,unsigned dest);
#endif

#ifndef NO_RANDOM
/* Get random value. Much faster than rand() */
byte get_random (void);
#endif

#ifndef NO_MEMCPY
/* Copy overlapping memory */
void memcpyb (void *dest,void *src,unsigned n);
void memcpyf (void *dest,void *src,unsigned n);
#endif

#ifndef NO_ASCII
/* Upload ASCII characters */
void upload_ascii (byte first,byte count,unsigned offset,byte flags);
#define NORMAL          0
#define ITALIC          1
#define BOLD            2
#define BOLD_ITALIC     (ITALIC | BOLD)
#endif

void reflect_vertical (byte table_code, unsigned source, unsigned destination, unsigned count);
void reflect_horizontal (byte table_code, unsigned source, unsigned destination, unsigned count);
void rotate_90 (byte table_code, unsigned source, unsigned destination, unsigned count);
