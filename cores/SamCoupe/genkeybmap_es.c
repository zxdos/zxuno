#include <stdio.h>
#include <stdlib.h>

typedef unsigned char BYTE;
/*
       12           12       3   3   2
AAAA DDDDDDDD AAAA DDDDDDDD MRN MMM XX

AAAA     = semifila del teclado a modificar                  | esta información está
DDDDDDDD = dato (AND negado con lo que haya) de esa semifila | repetida para dos teclas
MRN      = Master reset, Reset de usuario, NMI
MMM      = la tecla es un modificador
XX       = Reservado para uso futuro

Ej: en la dirección de memoria correspondiente al código de la tecla ESC,
que correspondería la tecla ESC del SAM, pondríamos:
1000 00100000 0000 00000000 000 000 00
En la dirección de memoria correspondiente al código de la tecla < que se
corresponde con la pulsación SYMBOL+Q pondríamos:
0111 00000010 0010 00000001 000 000 00

256 codigos + E0 = 512 codigos
SHIFT, CTRL, ALT = 8 combinaciones

512*8=4096 direcciones x 32 bits = 16384 bytes
En el core se dispondrá como una memoria de 16384x8 bits

Cada tecla ocupará cuatro direcciones consecutivas según el esquema anterior.
*/

// You shouldn't have to touch these defs unless your Spectrum has a different keyboard
// layout (because, for example, you are using a different ROM

//                          CCCC BBBBAAAA  -- hex digits for coding 
#define SAM_1      0x301 // 0011 00000001
#define SAM_2      0x302 // 0011 00000010
#define SAM_3      0x304 // 0011 00000100
#define SAM_4      0x308 // 0011 00001000
#define SAM_5      0x310 // 0011 00010000
#define SAM_ESC    0x320 // 0011 00100000
#define SAM_TAB    0x340 // 0011 01000000
#define SAM_CAPS   0x380 // 0011 10000000

#define SAM_0      0x401 // 0100 00000001
#define SAM_9      0x402 // 0100 00000010
#define SAM_8      0x404 // 0100 00000100
#define SAM_7      0x408 // 0100 00001000
#define SAM_6      0x410 // 0100 00010000
#define SAM_MINUS  0x420 // 0100 00100000
#define SAM_PLUS   0x440 // 0100 01000000
#define SAM_DELETE 0x480 // 0100 10000000

#define SAM_Q      0x201 // 0010 00000001
#define SAM_W      0x202 // 0010 00000010
#define SAM_E      0x204 // 0010 00000100
#define SAM_R      0x208 // 0010 00001000
#define SAM_T      0x210 // 0010 00010000
#define SAM_F7     0x220 // 0010 00100000
#define SAM_F8     0x240 // 0010 01000000
#define SAM_F9     0x280 // 0010 10000000

#define SAM_P      0x501 // 0101 00000001
#define SAM_O      0x502 // 0101 00000010
#define SAM_I      0x504 // 0101 00000100
#define SAM_U      0x508 // 0101 00001000
#define SAM_Y      0x510 // 0101 00010000
#define SAM_EQUAL  0x520 // 0101 00100000
#define SAM_QUOTE  0x540 // 0101 01000000
#define SAM_F0     0x580 // 0101 10000000

#define SAM_A      0x101 // 0001 00000001
#define SAM_S      0x102 // 0001 00000010
#define SAM_D      0x104 // 0001 00000100
#define SAM_F      0x108 // 0001 00001000
#define SAM_G      0x110 // 0001 00010000
#define SAM_F4     0x120 // 0001 00100000
#define SAM_F5     0x140 // 0001 01000000
#define SAM_F6     0x180 // 0001 10000000

#define SAM_RETURN 0x601 // 0110 00000001
#define SAM_L      0x602 // 0110 00000010
#define SAM_K      0x604 // 0110 00000100
#define SAM_J      0x608 // 0110 00001000
#define SAM_H      0x610 // 0110 00010000
#define SAM_SEMICOL 0x620 //0110 00100000 
#define SAM_COLON  0x640 // 0110 01000000
#define SAM_EDIT   0x680 // 0110 10000000

#define SAM_SHIFT  0x001 // 0000 00000001
#define SAM_Z      0x002 // 0000 00000010
#define SAM_X      0x004 // 0000 00000100
#define SAM_C      0x008 // 0000 00001000
#define SAM_V      0x010 // 0000 00010000
#define SAM_F1     0x020 // 0000 00100000
#define SAM_F2     0x040 // 0000 01000000
#define SAM_F3     0x080 // 0000 10000000

#define SAM_SPACE  0x701 // 0111 00000001
#define SAM_SYMBOL 0x702 // 0111 00000010
#define SAM_M      0x704 // 0111 00000100
#define SAM_N      0x708 // 0111 00001000
#define SAM_B      0x710 // 0111 00010000
#define SAM_COMMA  0x720 // 0111 00100000
#define SAM_DOT    0x740 // 0111 01000000
#define SAM_INV    0x780 // 0111 10000000

#define SAM_CTRL   0x801 // 1000 00000001
#define SAM_UP     0x802 // 1000 00000010
#define SAM_DOWN   0x804 // 1000 00000100
#define SAM_LEFT   0x808 // 1000 00001000
#define SAM_RIGHT  0x810 // 1000 00010000

#define SAM_BANG    ((SAM_SHIFT<<12) | SAM_1)
#define SAM_AT      ((SAM_SHIFT<<12) | SAM_2)
#define SAM_HASH    ((SAM_SHIFT<<12) | SAM_3)
#define SAM_DOLLAR  ((SAM_SHIFT<<12) | SAM_4)
#define SAM_PERCEN  ((SAM_SHIFT<<12) | SAM_5)
#define SAM_AMP     ((SAM_SHIFT<<12) | SAM_6)
#define SAM_APOSTRO ((SAM_SHIFT<<12) | SAM_7)
#define SAM_PAROPEN ((SAM_SHIFT<<12) | SAM_8)
#define SAM_PARCLOS ((SAM_SHIFT<<12) | SAM_9)
#define SAM_TILDE   ((SAM_SHIFT<<12) | SAM_0)
#define SAM_SLASH   ((SAM_SHIFT<<12) | SAM_MINUS)
#define SAM_STAR    ((SAM_SHIFT<<12) | SAM_PLUS)
#define SAM_LESS    ((SAM_SYMBOL<<12) | SAM_Q)
#define SAM_GREATER ((SAM_SYMBOL<<12) | SAM_W)
#define SAM_BRAOPEN ((SAM_SYMBOL<<12) | SAM_R)
#define SAM_BRACLOS ((SAM_SYMBOL<<12) | SAM_T)
#define SAM_UNDERSC ((SAM_SHIFT<<12) | SAM_EQUAL)
#define SAM_COPY    ((SAM_SHIFT<<12) | SAM_QUOTE)
#define SAM_PIPE    ((SAM_SYMBOL<<12) | SAM_9)
#define SAM_BACKSLA ((SAM_SYMBOL<<12) | SAM_INV)
#define SAM_CUROPEN ((SAM_SYMBOL<<12) | SAM_F)
#define SAM_CURCLOS ((SAM_SYMBOL<<12) | SAM_G)
#define SAM_CARET   ((SAM_SYMBOL<<12) | SAM_H)
#define SAM_POUND   ((SAM_SYMBOL<<12) | SAM_L)
#define SAM_QUEST   ((SAM_SYMBOL<<12) | SAM_X)

// END of SAM Coupé key definitions

// Definitions for additional signals generated by the keyboard core
// AAAADDDDDDDD AAAADDDDDDDD MRN MMM XX
#define MODIFIER1  0x04
#define MODIFIER2  0x08
#define MODIFIER3  0x10

#define MRESET     0x80
#define URESET     0x40
#define NMI        0x20

#define USER2      0x02
#define USER1      0x01
// End of additional signals

// A key can be pressed with up to three key modifiers
// which generates 8 combinations for each key
#define EXT        0x100
#define MD1        0x200
#define MD2        0x400
#define MD3        0x800

// Scan code 2 list. First, non localized keys
#define PC_A       0x1C
#define PC_B       0x32
#define PC_C       0x21
#define PC_D       0x23
#define PC_E       0x24
#define PC_F       0x2B
#define PC_G       0x34
#define PC_H       0x33
#define PC_I       0x43
#define PC_J       0x3B
#define PC_K       0x42
#define PC_L       0x4B
#define PC_M       0x3A
#define PC_N       0x31
#define PC_O       0x44
#define PC_P       0x4D
#define PC_Q       0x15
#define PC_R       0x2D
#define PC_S       0x1B
#define PC_T       0x2C
#define PC_U       0x3C
#define PC_V       0x2A
#define PC_W       0x1D
#define PC_X       0x22
#define PC_Y       0x35
#define PC_Z       0x1A

#define PC_0       0x45
#define PC_1       0x16
#define PC_2       0x1E
#define PC_3       0x26
#define PC_4       0x25
#define PC_5       0x2E
#define PC_6       0x36
#define PC_7       0x3D
#define PC_8       0x3E
#define PC_9       0x46

#define PC_F1      0x05
#define PC_F2      0x06
#define PC_F3      0x04
#define PC_F4      0x0C
#define PC_F5      0x03
#define PC_F6      0x0B
#define PC_F7      0x83
#define PC_F8      0x0A
#define PC_F9      0x01
#define PC_F10     0x09
#define PC_F11     0x78
#define PC_F12     0x07

#define PC_ESC     0x76
#define PC_SPACE   0x29
#define PC_LCTRL   0x14
#define PC_RCTRL   0x14 | EXT
#define PC_LSHIFT  0x12
#define PC_RSHIFT  0x59
#define PC_LALT    0x11
#define PC_RALT    0x11 | EXT
#define PC_LWIN    0x1F | EXT
#define PC_RWIN    0x27 | EXT
#define PC_APPS    0x2F | EXT

#define PC_TAB     0x0D
#define PC_CPSLOCK 0x58
#define PC_SCRLOCK 0x7E

#define PC_INSERT  0x70 | EXT
#define PC_DELETE  0x71 | EXT
#define PC_HOME    0x6C | EXT
#define PC_END     0x69 | EXT
#define PC_PGUP    0x7D | EXT
#define PC_PGDOWN  0x7A | EXT
#define PC_BKSPACE 0x66
#define PC_ENTER   0x5A
#define PC_UP      0x75 | EXT
#define PC_DOWN    0x72 | EXT
#define PC_LEFT    0x6B | EXT
#define PC_RIGHT   0x74 | EXT

#define PC_NUMLOCK  0x77
#define PC_KP_DIVIS 0x4A | EXT
#define PC_KP_MULT  0x7C
#define PC_KP_MINUS 0x7B
#define PC_KP_PLUS  0x79
#define PC_KP_ENTER 0x5A | EXT
#define PC_KP_DOT   0x71
#define PC_KP_0     0x70
#define PC_KP_1     0x69
#define PC_KP_2     0x72
#define PC_KP_3     0x7A
#define PC_KP_4     0x6B
#define PC_KP_5     0x73
#define PC_KP_6     0x74
#define PC_KP_7     0x6C
#define PC_KP_8     0x75
#define PC_KP_9     0x7D

// Localized keyboards start to differenciate from here

// Localized keyboard ES (Spain)
#define PC_BACKSLA 0x0E
#define PC_APOSTRO 0x4E
#define PC_OPNBANG 0x55
#define PC_GRAVEAC 0x54
#define PC_PLUS    0x5B
#define PC_EGNE    0x4C
#define PC_ACUTEAC 0x52
#define PC_CEDILLA 0x5D
#define PC_LESS    0x61
#define PC_COMMA   0x41
#define PC_DOT     0x49
#define PC_MINUS   0x4A

#define MAP(pc,sam,rmu) {                                                     \
                           rom[(pc)*4] = (((sam)>>16)&0xFF);                   \
                           rom[(pc)*4+1] = (((sam)>>8)&0xFF);                  \
                           rom[(pc)*4+2] = (((sam))&0xFF);                     \
                           rom[(pc)*4+3] = (rmu);                             \
                         }
                         
#define MAPANY(pc,sam,rmu) {                                                 \
                               MAP(pc,sam,rmu);                              \
                           	   MAP(MD1|pc,sam,rmu);                          \
                               MAP(MD2|pc,sam,rmu);                          \
							   MAP(MD3|pc,sam,rmu);                          \
                               MAP(MD1|MD2|pc,sam,rmu);                      \
                               MAP(MD1|MD3|pc,sam,rmu);                      \
                               MAP(MD2|MD3|pc,sam,rmu);                      \
                               MAP(MD1|MD2|MD3|pc,sam,rmu);                  \
                            }
                         
#define CLEANMAP {                                                            \
                    int i;                                                    \
                    for (i=0;i<(sizeof(rom)/sizeof(rom[0]));i++)              \
                      rom[i] = 0;                                             \
                 }
#define SAVEMAPHEX(name) {                                                      \
                           FILE *f;                                             \
                           int i;                                               \
                           f=fopen(name,"w");                                   \
                           for(i=0;i<(sizeof(rom)/sizeof(rom[0]));i++)          \
                             fprintf(f,"%.2X\n",rom[i]);                        \
                           fclose(f);                                           \
                         }

#define SAVEMAPBIN(name) {                                                      \
                           FILE *f;                                             \
                           int i;                                               \
                           f=fopen(name,"wb");                                  \
                           fwrite (rom, 1, sizeof(rom), f);                     \
                           fclose(f);                                           \
                         }


int main()
{
    BYTE rom[16384];

    CLEANMAP;

    MAPANY(PC_LSHIFT,0,MODIFIER1);  // MD1 is SHIFT
    MAPANY(PC_RSHIFT,0,MODIFIER1);  // MD1 is SHIFT
    MAPANY(PC_LCTRL,SAM_CTRL,MODIFIER2);   // MD2 is CTRL
    MAPANY(PC_RCTRL,SAM_CTRL,MODIFIER2);   // MD2 is CTRL
    MAPANY(PC_LALT,SAM_SHIFT,MODIFIER3);   // MD3 is ALT.
    MAPANY(PC_RALT,SAM_SYMBOL,MODIFIER3);  // MD3 is ALT.
    
    MAPANY(PC_RWIN,SAM_EDIT,0);     // EDIT key

    // Basic mapping: each key from PC is mapped to a key in the SAM
    MAP(PC_1,SAM_1,0);
    MAP(PC_2,SAM_2,0);
    MAP(PC_3,SAM_3,0);
    MAP(PC_4,SAM_4,0);
    MAP(PC_5,SAM_5,0);
    MAP(PC_6,SAM_6,0);
    MAP(PC_7,SAM_7,0);
    MAP(PC_8,SAM_8,0);
    MAP(PC_9,SAM_9,0);
    MAP(PC_0,SAM_0,0);

    MAP(PC_Q,SAM_Q,0);
    MAP(PC_W,SAM_W,0);
    MAP(PC_E,SAM_E,0);
    MAP(PC_R,SAM_R,0);
    MAP(PC_T,SAM_T,0);
    MAP(PC_Y,SAM_Y,0);
    MAP(PC_U,SAM_U,0);
    MAP(PC_I,SAM_I,0);
    MAP(PC_O,SAM_O,0);
    MAP(PC_P,SAM_P,0);
    MAP(PC_A,SAM_A,0);
    MAP(PC_S,SAM_S,0);
    MAP(PC_D,SAM_D,0);
    MAP(PC_F,SAM_F,0);
    MAP(PC_G,SAM_G,0);
    MAP(PC_H,SAM_H,0);
    MAP(PC_J,SAM_J,0);
    MAP(PC_K,SAM_K,0);
    MAP(PC_L,SAM_L,0);
    MAP(PC_Z,SAM_Z,0);
    MAP(PC_X,SAM_X,0);
    MAP(PC_C,SAM_C,0);
    MAP(PC_V,SAM_V,0);
    MAP(PC_B,SAM_B,0);
    MAP(PC_N,SAM_N,0);
    MAP(PC_M,SAM_M,0);

    MAP(MD1|PC_Q,SAM_SHIFT<<12|SAM_Q,0);
    MAP(MD1|PC_W,SAM_SHIFT<<12|SAM_W,0);
    MAP(MD1|PC_E,SAM_SHIFT<<12|SAM_E,0);
    MAP(MD1|PC_R,SAM_SHIFT<<12|SAM_R,0);
    MAP(MD1|PC_T,SAM_SHIFT<<12|SAM_T,0);
    MAP(MD1|PC_Y,SAM_SHIFT<<12|SAM_Y,0);
    MAP(MD1|PC_U,SAM_SHIFT<<12|SAM_U,0);
    MAP(MD1|PC_I,SAM_SHIFT<<12|SAM_I,0);
    MAP(MD1|PC_O,SAM_SHIFT<<12|SAM_O,0);
    MAP(MD1|PC_P,SAM_SHIFT<<12|SAM_P,0);
    MAP(MD1|PC_A,SAM_SHIFT<<12|SAM_A,0);
    MAP(MD1|PC_S,SAM_SHIFT<<12|SAM_S,0);
    MAP(MD1|PC_D,SAM_SHIFT<<12|SAM_D,0);
    MAP(MD1|PC_F,SAM_SHIFT<<12|SAM_F,0);
    MAP(MD1|PC_G,SAM_SHIFT<<12|SAM_G,0);
    MAP(MD1|PC_H,SAM_SHIFT<<12|SAM_H,0);
    MAP(MD1|PC_J,SAM_SHIFT<<12|SAM_J,0);
    MAP(MD1|PC_K,SAM_SHIFT<<12|SAM_K,0);
    MAP(MD1|PC_L,SAM_SHIFT<<12|SAM_L,0);
    MAP(MD1|PC_Z,SAM_SHIFT<<12|SAM_Z,0);
    MAP(MD1|PC_X,SAM_SHIFT<<12|SAM_X,0);
    MAP(MD1|PC_C,SAM_SHIFT<<12|SAM_C,0);
    MAP(MD1|PC_V,SAM_SHIFT<<12|SAM_V,0);
    MAP(MD1|PC_B,SAM_SHIFT<<12|SAM_B,0);
    MAP(MD1|PC_N,SAM_SHIFT<<12|SAM_N,0);
    MAP(MD1|PC_M,SAM_SHIFT<<12|SAM_M,0);

    MAPANY(PC_SPACE,SAM_SPACE,0);
    MAPANY(PC_ENTER,SAM_RETURN,0);

    //Complex mapping. This is for the spanish keyboard although many
    //combos can be used with any other PC keyboard
    MAPANY(PC_ESC,SAM_ESC,0);
    MAPANY(PC_CPSLOCK,SAM_CAPS,0);
    MAPANY(PC_TAB,SAM_TAB,0);
    MAP(PC_BKSPACE,SAM_DELETE,0);
    MAPANY(PC_UP,SAM_UP,0);
    MAPANY(PC_DOWN,SAM_DOWN,0);
    MAPANY(PC_LEFT,SAM_LEFT,0);
    MAPANY(PC_RIGHT,SAM_RIGHT,0);

    MAP(PC_F5|MD2|MD3,0,NMI); // Ctrl-Alt-F5 for NMI
    MAP(PC_DELETE|MD2|MD3,0,URESET);     //
    MAP(PC_KP_DOT|MD2|MD3,0,URESET);     // Ctrl-Alt-Del for user reset
    MAP(PC_BKSPACE|MD2|MD3,0,MRESET);    // Ctrl-Alt-BkSpace for master reset
    
    //keypad
    MAPANY(PC_KP_DIVIS,SAM_SLASH,0);
    MAPANY(PC_KP_MULT,SAM_STAR,0);
    MAPANY(PC_KP_MINUS,SAM_MINUS,0);
    MAPANY(PC_KP_PLUS,SAM_PLUS,0);
    MAPANY(PC_KP_ENTER,SAM_RETURN,0);   
	MAPANY(PC_KP_0,SAM_F0,0); 
	MAPANY(PC_KP_1,SAM_F1,0); 
	MAPANY(PC_KP_2,SAM_F2,0); 
	MAPANY(PC_KP_3,SAM_F3,0); 
	MAPANY(PC_KP_4,SAM_F4,0); 
	MAPANY(PC_KP_5,SAM_F5,0); 
	MAPANY(PC_KP_6,SAM_F6,0); 
	MAPANY(PC_KP_7,SAM_F7,0); 
	MAPANY(PC_KP_8,SAM_F8,0); 
	MAPANY(PC_KP_9,SAM_F9,0); 

    //Some shift+key mappings for the ES keyboard
    MAP(MD1|PC_1,SAM_BANG,0);
    MAP(MD1|PC_2,SAM_QUOTE,0);
    MAP(MD1|PC_3,SAM_HASH,0);
    MAP(MD1|PC_4,SAM_DOLLAR,0);
    MAP(MD1|PC_5,SAM_PERCEN,0);
    MAP(MD1|PC_6,SAM_AMP,0);
    MAP(MD1|PC_7,SAM_SLASH,0);
    MAP(MD1|PC_8,SAM_PAROPEN,0);
    MAP(MD1|PC_9,SAM_PARCLOS,0);
    MAP(MD1|PC_0,SAM_EQUAL,0);
    MAP(PC_APOSTRO,SAM_APOSTRO,0);
    MAP(MD1|PC_APOSTRO,SAM_QUEST,0);
    MAP(PC_GRAVEAC,SAM_POUND,0);
    MAP(MD1|PC_GRAVEAC,SAM_CARET,0);
    MAP(PC_PLUS,SAM_PLUS,0);
    MAP(MD1|PC_PLUS,SAM_STAR,0);
    MAP(PC_ACUTEAC,SAM_CUROPEN,0);
    MAP(MD1|PC_ACUTEAC,SAM_CUROPEN,0);
    MAP(PC_ACUTEAC,SAM_CUROPEN,0);
    MAP(MD1|PC_ACUTEAC,SAM_CUROPEN,0);
    MAP(PC_CEDILLA,SAM_CURCLOS,0);
    MAP(MD1|PC_CEDILLA,SAM_COPY,0);
    MAP(PC_COMMA,SAM_COMMA,0);
    MAP(MD1|PC_COMMA,SAM_SEMICOL,0);
    MAP(PC_DOT,SAM_DOT,0);
    MAP(MD1|PC_DOT,SAM_COLON,0);
    MAP(PC_MINUS,SAM_MINUS,0);
    MAP(MD1|PC_MINUS,SAM_UNDERSC,0);
    MAP(PC_BACKSLA,SAM_BACKSLA,0);
    MAP(MD1|PC_BACKSLA,SAM_BACKSLA,0);
    MAP(PC_EGNE,SAM_TILDE,0);
    MAP(PC_LESS,SAM_LESS,0);
    MAP(MD1|PC_LESS,SAM_GREATER,0);

    // End of mapping. Save .HEX file for Verilog
    SAVEMAPHEX("keyb_es_hex.txt");
}

