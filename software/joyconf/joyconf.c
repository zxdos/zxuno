/*
Compilar con:
sdcc -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node 10000
--nostdlib --nostdinc --no-std-crt0 --code-loc 8192 joyconf.c
*/

typedef unsigned char BYTE;
typedef unsigned short WORD;

enum {IBLACK=0, IBLUE, IRED, IMAG, IGREEN, ICYAN, IYELLOW, IWHITE};
enum {PBLACK=0, PBLUE=8, PRED=16, PMAG=24, PGREEN=32, PCYAN=40, PYELLOW=48, PWHITE=56};
#define BRIGHT 64
#define FLASH 128

__sfr __at (0xfe) ULA;
__sfr __at (0xff) ATTR;
__sfr __at (0x1f) KEMPSTONADDR;
__sfr __at (0x7f) FULLERADDR;

__sfr __banked __at (0xf7fe) SEMIFILA1;
__sfr __banked __at (0xeffe) SEMIFILA2;
__sfr __banked __at (0xfbfe) SEMIFILA3;
__sfr __banked __at (0xdffe) SEMIFILA4;
__sfr __banked __at (0xfdfe) SEMIFILA5;
__sfr __banked __at (0xbffe) SEMIFILA6;
__sfr __banked __at (0xfefe) SEMIFILA7;
__sfr __banked __at (0x7ffe) SEMIFILA8;

#define ATTRP 23693
#define ATTRT 23695
#define BORDR 23624
#define LASTK 23560

#define WAIT_VRETRACE __asm halt __endasm
#define WAIT_HRETRACE while(ATTR!=0xff)
#define SETCOLOR(x) *(BYTE *)(ATTRP)=(x)
#define LASTKEY *(BYTE *)(LASTK)
#define ATTRPERMANENT *((BYTE *)(ATTRP))
#define ATTRTEMPORARY *((BYTE *)(ATTRT))
#define BORDERCOLOR *((BYTE *)(BORDR))

__sfr __banked __at (0xfc3b) ZXUNOADDR;
__sfr __banked __at (0xfd3b) ZXUNODATA;
#define MASTERCONF 0
#define SCANCODE 4
#define KEYBSTAT 5
#define JOYCONF 6
#define COREID 255

void __sdcc_enter_ix (void) __naked;
void cls (BYTE);
void border (BYTE);
void locate (BYTE, BYTE);

void puts (BYTE *);
void putdec (WORD);
void u16todec (WORD, char *);
void u16tohex (WORD, char *);
void u8tohex (BYTE, char *);

void memset (BYTE *, BYTE, WORD);
void memcpy (BYTE *, BYTE *, WORD);

int abs (int);
signed char sgn (int);

long frames (void) __naked;
void pause (BYTE);

void wait_key (void);
BYTE inkey (BYTE, BYTE);

void beep (WORD, BYTE) __critical;

/* --------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------- */
BYTE printconf (void);
void printstatictext (void);
void getcoreid(BYTE *s);
void interactivemode (void);
void usage (void);
void commandlinemode (char *p);

BYTE main (char *p);

void init (void) __naked
{
     __asm
     push hl
     call _main
     pop af
     or a  ;reset carry: clean exit
     ld b,h
     ld c,l
     ret
     __endasm;
}

BYTE main (char *p)
{
  if (!p)
     interactivemode();
  else
      commandlinemode(p);
  return 0;
}

void commandlinemode (char *p)
{
  BYTE kbdconf, db9conf;

  ZXUNOADDR = JOYCONF;
  kbdconf = ZXUNODATA & 0xf;
  db9conf = (ZXUNODATA>>4) & 0xf;
  while (*p!=0 && *p!=0xd && *p!=':')
  {
    if (*p==' ')
    {
      p++;
      continue;
    }
    if (*p=='-')
    {
      p++;
      if (*p=='k')
      {
        p++;
        kbdconf &= 0x8;
        switch (*p)
        {
          case 'd': kbdconf |= 0; break;
          case 'k': kbdconf |= 1; break;
          case '1': kbdconf |= 2; break;
          case '2': kbdconf |= 3; break;
          case 'c': kbdconf |= 4; break;
          case 'f': kbdconf |= 5; break;
          default: usage(); return;
        }
        p++;
        if (*p=='1')
        {
           kbdconf |= 0x8;
           p++;
        }
        else if (*p=='0')
        {
           kbdconf &= 0x7;
           p++;
        }
      }
      else if (*p=='j')
      {
        p++;
        db9conf &= 0x8;
        switch (*p)
        {
          case 'd': db9conf |= 0; break;
          case 'k': db9conf |= 1; break;
          case '1': db9conf |= 2; break;
          case '2': db9conf |= 3; break;
          case 'c': db9conf |= 4; break;
          case 'f': db9conf |= 5; break;
		  case 'o': db9conf |= 6; break;          
          default: usage(); return;
        }
        p++;
        if (*p=='1')
        {
           db9conf |= 0x8;
           p++;
        }
        else if (*p=='0')
        {
           db9conf &= 0x7;
           p++;
        }
      }
    }
    else
    {
      usage();
      return;
    }
  }
  ZXUNODATA = db9conf<<4 | kbdconf;
}

void usage (void)
{
        // 01234567890123456789012345678901
    puts ("Configures/tests protocols for\xd"
          "keyb joystick and DB9 joystick\xd\xd"
          "Usage: JOYCONF [-kAx] [-jBx]\xd"
          "  where A,B can be:\xd"
          "    d: Disabled\xd"
          "    k: Kempston\xd"
          "    1: Sinclair port 1\xd"
          "    2: Sinclair port 2\xd"
          "    c: Cursor/Protek/AGF\xd"
          "    f: Fuller\xd"
          "    o: OPQA-SPACE-M (DB9 only)\xd"          
          "  where x can be:\xd"
          "    0: disable autofire\xd"
          "    1: enable autofire\xd"
          "    other/none: keep setting\xd"
          "  No arguments: interactive mode\xd\xd"
          "Example: .joyconf -kc0 -jk1\xd"
          "Sets Cursor, no autofire for the"
          "keyboard joystick, and Kempston\xd"
          "w/autofire for the DB9 joystick.\xd");
}

void interactivemode (void)
{
  BYTE bkbor, bkattr;

  bkbor = BORDERCOLOR;
  bkattr = ATTRPERMANENT;

  border(IBLACK);
  cls(BRIGHT|PBLACK|IWHITE);
  printstatictext();
  while(!printconf());

  border(bkbor);
  cls(bkattr);
}


void printstatictext (void)
{
  char coreid[32];

  locate(0,0);
  puts ("\x4\x78JOYSTICK CONFIGURATION AND TEST ");

  locate(2,0);
  puts ("KBD joystick: ");

  locate(3,0);
  puts ("DB9 joystick: ");

  locate(5,0);
  puts("\x4\x45T/G to change KBD/DB9 protocol");

  locate(6,0);
  puts("\x4\x45W/S to change KBD/DB9 autofire");

  locate(20,0);
  puts("\x4\x47ZX-UNO Core ID: ");
  coreid[0]=0x4;
  coreid[1]=0x46;
  getcoreid(coreid+2);
  if (coreid[2]==0)
    puts("\x4\x46NOT AVAILABLE");
  else
    puts(coreid);

  locate(21,0);
  puts("\x4\x70      Press 'E'   to exit       ");
}

void getcoreid(BYTE *s)
{
  BYTE cont;
  volatile BYTE letra;

  s[0]='\0';
  ZXUNOADDR = COREID;
  cont=0;
  while (ZXUNODATA!=0 && cont<32) cont++;
  if (cont==32)
     return;
  cont=0;
  do
  {
    letra = ZXUNODATA;
    cont++;
  }
  while (letra==0 && cont<32);
  if (cont==32)
     return;
  *(s++) = letra;
  do
  {
    letra = ZXUNODATA;
    *(s++) = letra;
  }
  while (letra!=0);
}

void printjoystat (char *proto, BYTE joy)  // FUDLR
{
  puts (proto);
  if (joy&0x8)
    puts ("\x4\x78 U ");
  else
    puts (" U ");
  if (joy&0x4)
    puts ("\x4\x78 D ");
  else
    puts (" D ");
  if (joy&0x2)
    puts ("\x4\x78 L ");
  else
    puts (" L ");
  if (joy&0x1)
    puts ("\x4\x78 R ");
  else
    puts (" R ");
 if (joy&0x10)
    puts ("\x4\x78 F ");
  else
    puts (" F ");
 if (joy&0x20)
    puts ("\x4\x78 B2 ");
  else
    puts (" B2 ");
}

BYTE printconf (void)
{
  BYTE kbconf, db9conf, kbdis=0, db9dis=0;
  BYTE joy, joy1, joy2, joyb2, joyOP, joyQ, joyA, joySPCM;

  WAIT_VRETRACE;
  ZXUNOADDR = JOYCONF;
  kbconf = ZXUNODATA & 0x0f;
  db9conf = (ZXUNODATA >> 4) & 0x0f;
  locate(2,14);
  switch (kbconf&0x7)
  {
    case 1:  puts("\x4\x46""KEMPSTON"); break;
    case 2:  puts("\x4\x46""SINCL P1"); break;
    case 3:  puts("\x4\x46""SINCL P2"); break;
    case 4:  puts("\x4\x46""CURSOR  "); break;
    case 5:  puts("\x4\x46""FULLER  "); break;
    default: puts("\x4\x46""DISABLED"); kbdis=1; break;
  }
  if (!kbdis && kbconf&0x8)
    puts("\x4\x45 AUTOFIRE");
  else
    puts("         ");

  locate(3,14);
  switch (db9conf&0x7)
  {
    case 1:  puts("\x4\x46""KEMPSTON"); break;
    case 2:  puts("\x4\x46""SINCL P1"); break;
    case 3:  puts("\x4\x46""SINCL P2"); break;
    case 4:  puts("\x4\x46""CURSOR  "); break;
    case 5:  puts("\x4\x46""FULLER  "); break;
    case 6:  puts("\x4\x46""OPQASPCM"); break;    
    default: puts("\x4\x46""DISABLED"); db9dis=1; break;
  }
  if (!db9dis && db9conf&0x8)
    puts("\x4\x45 AUTOFIRE");
  else
    puts("         ");

  if (LASTKEY == 't' || LASTKEY == 't')
  {
    kbconf = kbconf&0x8 | (((kbconf&7)+1==6)? 0 : (kbconf&7)+1);
    LASTKEY = 0;
  }
  else if (LASTKEY == 'g' || LASTKEY == 'G')
  {
    db9conf = db9conf&0x8 | (((db9conf&7)+1==7)? 0 : (db9conf&7)+1); //q
    LASTKEY = 0;
  }
  else if (LASTKEY == 'w' || LASTKEY == 'W')
  {
    kbconf ^= 0x8;
    LASTKEY = 0;
  }
  else if (LASTKEY == 's' || LASTKEY == 'S')
  {
    db9conf ^= 0x8;
    LASTKEY = 0;
  }
  ZXUNODATA = db9conf<<4 | kbconf;

  joy = KEMPSTONADDR;
  locate(8,0); printjoystat("\x4\x7Kempston  : ", joy);

  joyb2 = ~SEMIFILA7; // -----2-- a --2FUDLR
  joy = ~SEMIFILA2;  // LRDUF    a --2FUDLR
  joy = (joyb2&4)<<3 | (joy&1)<<4 | (joy&2)<<2 | (joy&4) | (joy&0x10)>>3 | (joy&8)>>3;
  locate(10,0); printjoystat("\x4\x7Sinclair 1: ", joy);

  joyb2 = ~SEMIFILA7; // ------2- a --2FUDLR
  joy = ~SEMIFILA1;  // FUDRL    a --2FUDLR
  joy = (joyb2&2)<<4 | (joy&0x1c) | (joy&2)>>1 | (joy&1)<<1;
  locate(12,0); printjoystat("\x4\x7Sinclair 2: ", joy);

  joy1 = ~SEMIFILA2;  // DUR2F a --2FUDLR
  joy2 = ~SEMIFILA1;  // L---- a --2FUDLR
  joy = (joy1&2)<<4 | (joy1&1)<<4 | (joy1&8) | (joy1&0x10)>>2 | (joy2&0x10)>>3 | (joy1&4)>>2;
  locate(14,0); printjoystat("\x4\x7""Cursor    : ", joy);

  joy = ~FULLERADDR;  // F2--RLDU a --2FUDLR
  joy =  (joy&0x40)>>1 | (joy&0x80)>>3 | (joy&1)<<3 | (joy&2)<<1 | (joy&4)>>1 | (joy&8)>>3;
  locate(16,0); printjoystat("\x4\x7""Fuller    : ", joy);

  //Nuevo modo joy OPQASPCM
  joyOP = ~SEMIFILA4;    // ------LR a --2FUDLR
  joyQ = ~SEMIFILA3;     // -------U a --2FUDLR
  joyA = ~SEMIFILA5;     // -------D a --2FUDLR
  joySPCM = ~SEMIFILA8;  // -----2-F a --2FUDLR
  joy = (joySPCM&4)<<3 | (joySPCM&1)<<4 | (joyQ&1)<<3 | (joyA&1)<<2 | (joyOP&2) | (joyOP&1);
  locate(18,0); printjoystat("\x4\x7""OPQASPCM  : ", joy);

  //if (LASTKEY==' ')
if (LASTKEY == 'e' || LASTKEY == 'E')
    return 1;
  else
    return 0;
}

/* --------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------- */
#pragma disable_warning 85
int abs (int n)
{
  return (n>=0)?n:-n;
}

signed char sgn (int n)
{
  return (n>=0)?1:-1;
}

long frames (void) __naked
{
  __asm
  ld a,(#23672)
  ld l,a
  ld a,(#23673)
  ld h,a
  ld a,(#23674)
  ld e,a
  ld d,#0
  ret
  __endasm;
}

void pause (BYTE frames)
{
  BYTE i;

  for (i=0;i!=frames;i++)
  {
    WAIT_VRETRACE;
  }
}

void memset (BYTE *dir, BYTE val, WORD nby)
{
  __asm
  push bc
  push de
  ld l,4(ix)
  ld h,5(ix)
  ld a,6(ix)
  ld c,7(ix)
  ld b,8(ix)
  ld d,h
  ld e,l
  inc de
  dec bc
  ld (hl),a
  ldir
  pop de
  pop bc
  __endasm;
}

void memcpy (BYTE *dst, BYTE *fue, WORD nby)
{
  __asm
  push bc
  push de
  ld e,4(ix)
  ld d,5(ix)
  ld l,6(ix)
  ld h,7(ix)
  ld c,8(ix)
  ld b,9(ix)
  ldir
  pop de
  pop bc
  __endasm;
}

void cls (BYTE attr)
{
  memset((BYTE *)16384,0,6144);
  memset((BYTE *)22528,attr,768);
  SETCOLOR(attr);
}

void border (BYTE b)
{
  ULA=(b>>3)&0x7;
  *((BYTE *)BORDR)=b;
}

void puts (BYTE *str)
{
  __asm
  push bc
  push de
  ld a,(#ATTRT)
  push af
  ld a,(#ATTRP)
  ld (#ATTRT),a
  ld l,4(ix)
  ld h,5(ix)
buc_print:
  ld a,(hl)
  or a
  jp z,fin_print
  cp #4
  jr nz,no_attr
  inc hl
  ld a,(hl)
  ld (#ATTRT),a
  inc hl
  jr buc_print
no_attr:
  rst #16
  inc hl
  jp buc_print

fin_print:
  pop af
  ld (#ATTRT),a
  pop de
  pop bc
  __endasm;
}

void locate (BYTE row, BYTE col)
{
  __asm
  push bc
  push de
  ld a,#22
  rst #16
  ld a,4(ix)
  rst #16
  ld a,5(ix)
  rst #16
  pop de
  pop bc
  __endasm;
}

// void putdec (WORD n)
// {
//   BYTE num[6];
//
//   u16todec (n,num);
//   puts (num);
// }
//
// void u16todec (WORD n, char *s)
// {
//   BYTE i=4;
//   WORD divisor=10, resto;
//
//   memset(s,' ',5);
//   do
//   {
//     resto=n%divisor;
//     n/=divisor;
//     s[i--]=resto+'0';
//   }
//   while (n);
//   s[5]='\0';
// }

void u16tohex (WORD n, char *s)
{
  u8tohex((n>>8)&0xFF,s);
  u8tohex(n&0xFF,s+2);
}

void u8tohex (BYTE n, char *s)
{
  BYTE i=1;
  BYTE resto;

  resto=n&0xF;
  s[1]=(resto>9)?resto+55:resto+48;
  resto=n>>4;
  s[0]=(resto>9)?resto+55:resto+48;
  s[2]='\0';
}

void wait_key (void)
{
  while ((ULA&0x1f)==0x1f);
}

BYTE inkey (BYTE semif, BYTE pos)
{
  BYTE teclas;
  BYTE posbit;

  switch (semif)
  {
    case 1: teclas=SEMIFILA1; break;
    case 2: teclas=SEMIFILA2; break;
    case 3: teclas=SEMIFILA3; break;
    case 4: teclas=SEMIFILA4; break;
    case 5: teclas=SEMIFILA5; break;
    case 6: teclas=SEMIFILA6; break;
    case 7: teclas=SEMIFILA7; break;
    case 8: teclas=SEMIFILA8; break;
    default: teclas=ULA; break;
  }
  posbit=1<<(pos-1);
  return (teclas&posbit)?0:1;
}

void beep (WORD durmili, BYTE freq) __critical
{
  volatile BYTE cborde;

  cborde=(*(BYTE *)(BORDR));
  __asm
  push bc
  push de

  ld l,6(ix)  ;se desplaza dos byte por ser "critical".
  ld h,7(ix)
  ld d,-1(ix)

  ld b,8(ix)
  xor a
  sub b
  ld b,a
  ld c,a

bucbeep:
  ld a,d
  xor #0x18
  ld d,a
  out (#254),a

  ld b,c
bucperiodobeep:
  djnz bucperiodobeep

  dec hl
  ld a,h
  or l
  jr nz,bucbeep

  pop de
  pop bc
  __endasm;
}

void __sdcc_enter_ix (void) __naked
{
    __asm
    pop	hl	; return address
    push ix	; save frame pointer
    ld ix,#0
    add	ix,sp	; set ix to the stack frame
    jp (hl)	; and return
    __endasm;
}
