/*
Compilar con:
sdcc -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node X
--alow-unsafe-reads --nostdlib --nostdinc --no-std-crt0 --out-fmt-s19
--port-mode=z80 --code-loc 8192 --data-loc 0 --stack-loc 65535 joyconf.sdcc
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

__sfr __banked __at (0xf7fe) SEMIFILA1;
__sfr __banked __at (0xeffe) SEMIFILA2;
__sfr __banked __at (0xfbfe) SEMIFILA3;
__sfr __banked __at (0xdffe) SEMIFILA4;
__sfr __banked __at (0xfdfe) SEMIFILA5;
__sfr __banked __at (0xbffe) SEMIFILA6;
__sfr __banked __at (0xfefe) SEMIFILA7;
__sfr __banked __at (0x7ffe) SEMIFILA8;

#define COORDS 23296
#define SPOSN 23298
#define ATTRP 23300
#define BORDR 23301
#define CHARS 23606
#define LASTK 23560

#define COLUMN (SPOSN)
#define ROW (SPOSN+1)

#define WAIT_VRETRACE __asm halt __endasm
#define WAIT_HRETRACE while(ATTR!=0xff)
#define SETCOLOR(x) *(BYTE *)(ATTRP)=(x)
#define LASTKEY *(BYTE *)(LASTK)

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

void main (void)
{
  border(IBLACK);
  cls(BRIGHT|PBLACK|IWHITE);
  printstatictext();
  while(!printconf());
  
  border(*(BYTE *)(23624));
  cls(*(BYTE *)(23693));
}

void printstatictext (void)
{
  char coreid[32];

  locate(0,0);
  puts ("\x4\x78\x6JOYSTICK CONFIGURATION AND TEST ");

  locate(2,0);
  puts ("KBD joystick: ");

  locate(3,0);
  puts ("DB9 joystick: ");

  locate(5,0);
  puts("\x4\x45Q/A to change KBD/DB9 protocol");

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

  locate(22,0);
  puts("\x4\x70      Press SPACE to exit       ");
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
}

BYTE printconf (void)
{
  BYTE kbconf, db9conf, kbdis=0, db9dis=0;
  BYTE joy, joy1, joy2;

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
    default: puts("\x4\x46""DISABLED"); db9dis=1; break;
  }
  if (!db9dis && db9conf&0x8)
    puts("\x4\x45 AUTOFIRE");
  else
    puts("         ");

  if (LASTKEY == 'q' || LASTKEY == 'Q')
  {
    kbconf = kbconf&0x8 | (((kbconf&7)+1==5)? 0 : (kbconf&7)+1);
    LASTKEY = 0;
  }
  else if (LASTKEY == 'a' || LASTKEY == 'A')
  {
    db9conf = db9conf&0x8 | (((db9conf&7)+1==5)? 0 : (db9conf&7)+1);
    LASTKEY = 0;
  }
  else if (LASTKEY == 'w' || LASTKEY == 'W')
  {
    kbconf ^= 0x8;
    LASTKEY = 0;
  }
  else if (LASTKEY == 's' || LASTKEY == 's')
  {
    db9conf ^= 0x8;
    LASTKEY = 0;
  }
  ZXUNODATA = db9conf<<4 | kbconf;

  joy = KEMPSTONADDR;
  locate(9,0); printjoystat("\x4\x7Kempston  : ", joy);

  joy = ~SEMIFILA2;  // LRDUF a FUDLR
  joy = (joy&1)<<4 | (joy&2)<<2 | (joy&4) | (joy&0x10)>>3 | (joy&8)>>3;
  locate(11,0); printjoystat("\x4\x7Sinclair 1: ", joy);

  joy = ~SEMIFILA1;  // FUDRL a FUDLR
  joy = (joy&0x1c) | (joy&2)>>1 | (joy&1)<<1;
  locate(13,0); printjoystat("\x4\x7Sinclair 2: ", joy);

  joy1 = ~SEMIFILA2;  // DUR-F a FUDLR
  joy2 = ~SEMIFILA1;  // L---- a FUDLR
  joy = (joy1&1)<<4 | (joy1&8) | (joy1&0x10)>>2 | (joy2&0x10)>>3 | (joy1&4)>>2;
  locate(15,0); printjoystat("\x4\x7""Cursor    : ", joy);
  
  if (LASTKEY==' ')
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
#ifdef USEROM
  __asm
  push bc
  push de
  ld a,4(ix)
  ld (#ATTRP),a
  call #0x0d6b
  ld a,#0xfe
  call #0x1601
  pop de
  pop bc
  __endasm;
#else
  memset((BYTE *)16384,0,6144);
  memset((BYTE *)22528,attr,768);
  SETCOLOR(attr);
  *((WORD *)SPOSN)=0;
#endif
}

void border (BYTE b)
{
  ULA=(b>>3)&0x7;
  *((BYTE *)BORDR)=b;
}

void puts (BYTE *str)
{
  volatile BYTE over=0;
  volatile BYTE bold=0;
  volatile BYTE backup_attrp = *(BYTE *)(ATTRP);

  __asm
  push bc
  push de
  ld l,4(ix)
  ld h,5(ix)
buc_print:
  ld a,(hl)
  or a
  jr nz,no_fin_print
  jp fin_print
no_fin_print:
  cp #22
  jr nz,no_at
  inc hl
  ld a,(hl)
  ld (#ROW),a
  inc hl
  ld a,(hl)
  ld (#COLUMN),a
  inc hl
  jr buc_print
no_at:
  cp #13
  jr nz,no_cr
  xor a
  ld (#COLUMN),a
  ld a,(#ROW)
  inc a
  ld (#ROW),a
  inc hl
  jr buc_print
no_cr:
  cp #4
  jr nz,no_attr
  inc hl
  ld a,(hl)
  ld (#ATTRP),a
  inc hl
  jr buc_print
no_attr:
  cp #5
  jr nz,no_pr_over
  ld -1(ix),#0xff
  inc hl
  jr buc_print
no_pr_over:
  cp #6
  jr nz,no_pr_bold
  ld -2(ix),#0xff
  inc hl
  jr buc_print
no_pr_bold:
  cp #32
  jr nc,imprimible
  ld a,#32
imprimible:
  push hl
  ld hl,(#COLUMN)
  push hl
  push af
  ld de,#16384
  add hl,de
  ld a,h
  and #7
  rrca
  rrca
  rrca
  or l
  ld l,a
  ld a,#248
  and h
  ld h,a
  pop af
  push hl
  ld de,(#CHARS)
  ld l,a
  ld h,#0
  add hl,hl
  add hl,hl
  add hl,hl
  add hl,de
  pop de

  ld b,#8
print_car:
  ld a,(hl)
  sra a
  and -2(ix)
  or (hl)
  ld c,a
  ld a,(de)
  and -1(ix)
  xor c
  ld (de),a
  inc hl
  inc d
  djnz print_car

  pop hl
  push hl
  ld de,#22528
  ld b,h
  ld h,#0
  add hl,de
  xor a
  or b
  jr z,fin_ca_attr
  ld de,#32
calc_dirat:
  add hl,de
  djnz calc_dirat
fin_ca_attr:
  ld a,(#ATTRP)
  ld (hl),a
  pop hl
  inc l
  bit 5,l
  jr z,no_inc_fila
  res 5,l
  inc h
no_inc_fila:
  ld (#COLUMN),hl
  pop hl
  inc hl
  jp buc_print

fin_print:
  pop de
  pop bc
  __endasm;

  SETCOLOR(backup_attrp);
}

void locate (BYTE row, BYTE col)
{
  *((BYTE *)ROW)=row;
  *((BYTE *)COLUMN)=col;
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
