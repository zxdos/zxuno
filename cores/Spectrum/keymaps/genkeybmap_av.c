/*
    This file is part of the ZXUNO Spectrum core. 
    Creation date is UNKNOWN by Miguel Angel Rodriguez Jodar
    (c)2014-2020 ZXUNO association.
    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
    Username: guest   Password: zxuno
    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core

    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ZXUNO Spectrum core is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.

    Any distributed copy of this file must keep this notice intact.
*/

#include <stdio.h>
#include <stdlib.h>

typedef unsigned char BYTE;
/*
    8        8    
AAADDDDD AAADDDDD 

AAA      = semifila del teclado a modificar                  | esta información está
DDDDD    = dato (AND negado con lo que haya) de esa semifila | repetida para dos teclas

Ej: en la dirección de memoria correspondiente al código de la tecla ESC,
que correspondería a la pulsación simultánea de CAPS SHIFT+SPACE, pondríamos:
00000001 11100001
Esto es: se activan las semifilas 0 y 7, y en cada una, se activa el bit 0

128 codigos + E0 = 256 codigos
SHIFT, CTRL, ALT = 8 combinaciones

256*8=2048 direcciones x 16 bits = 32768 bits
En el core se dispondrá como una memoria de 4096x8 bits

Cada tecla ocupará dos direcciones consecutivas.
D+0 : tecla1 (o 0 si no la hay)
D+1 : tecla2 (o 0 si no la hay)
*/

// You shouldn't have to touch these defs unless your Spectrum has a different keyboard
// layout (because, for example, you are using a different ROM

#define SP_1       0x61
#define SP_2       0x62
#define SP_3       0x64
#define SP_4       0x68
#define SP_5       0x70

#define SP_0       0x81
#define SP_9       0x82
#define SP_8       0x84
#define SP_7       0x88
#define SP_6       0x90

#define SP_Q       0x41
#define SP_W       0x42
#define SP_E       0x44
#define SP_R       0x48
#define SP_T       0x50

#define SP_P       0xA1
#define SP_O       0xA2
#define SP_I       0xA4
#define SP_U       0xA8
#define SP_Y       0xB0

#define SP_A       0x21
#define SP_S       0x22
#define SP_D       0x24
#define SP_F       0x28
#define SP_G       0x30

#define SP_ENTER   0xC1
#define SP_L       0xC2
#define SP_K       0xC4
#define SP_J       0xC8
#define SP_H       0xD0

#define SP_CAPS    0x01
#define SP_Z       0x02
#define SP_X       0x04
#define SP_C       0x08
#define SP_V       0x10

#define SP_SPACE   0xE1
#define SP_SYMBOL  0xE2
#define SP_M       0xE4
#define SP_N       0xE8
#define SP_B       0xF0

#define SP_BANG    (SP_SYMBOL<<8) | SP_1
#define SP_AT      (SP_SYMBOL<<8) | SP_2
#define SP_HASH    (SP_SYMBOL<<8) | SP_3
#define SP_DOLLAR  (SP_SYMBOL<<8) | SP_4
#define SP_PERCEN  (SP_SYMBOL<<8) | SP_5
#define SP_AMP     (SP_SYMBOL<<8) | SP_6
#define SP_APOSTRO (SP_SYMBOL<<8) | SP_7
#define SP_PAROPEN (SP_SYMBOL<<8) | SP_8
#define SP_PARCLOS (SP_SYMBOL<<8) | SP_9
#define SP_UNDERSC (SP_SYMBOL<<8) | SP_0
#define SP_LESS    (SP_SYMBOL<<8) | SP_R
#define SP_LESSEQ  (SP_SYMBOL<<8) | SP_Q
#define SP_GREATER (SP_SYMBOL<<8) | SP_T
#define SP_GREATEQ (SP_SYMBOL<<8) | SP_E
#define SP_NOTEQ   (SP_SYMBOL<<8) | SP_W
#define SP_BRAOPEN (SP_SYMBOL<<8) | SP_Y
#define SP_BRACLOS (SP_SYMBOL<<8) | SP_U
#define SP_SEMICOL (SP_SYMBOL<<8) | SP_O
#define SP_QUOTE   (SP_SYMBOL<<8) | SP_P
#define SP_TILDE   (SP_SYMBOL<<8) | SP_A
#define SP_PIPE    (SP_SYMBOL<<8) | SP_S
#define SP_BACKSLA (SP_SYMBOL<<8) | SP_D
#define SP_CUROPEN (SP_SYMBOL<<8) | SP_F
#define SP_CURCLOS (SP_SYMBOL<<8) | SP_G
#define SP_CARET   (SP_SYMBOL<<8) | SP_H
#define SP_MINUS   (SP_SYMBOL<<8) | SP_J
#define SP_PLUS    (SP_SYMBOL<<8) | SP_K
#define SP_EQUAL   (SP_SYMBOL<<8) | SP_L
#define SP_COLON   (SP_SYMBOL<<8) | SP_Z
#define SP_POUND   (SP_SYMBOL<<8) | SP_X
#define SP_QUEST   (SP_SYMBOL<<8) | SP_C
#define SP_SLASH   (SP_SYMBOL<<8) | SP_V
#define SP_STAR    (SP_SYMBOL<<8) | SP_B
#define SP_COMMA   (SP_SYMBOL<<8) | SP_N
#define SP_DOT     (SP_SYMBOL<<8) | SP_M

#define SP_EXTEND  (SP_CAPS<<8) | SP_SYMBOL
#define SP_EDIT    (SP_CAPS<<8) | SP_1
#define SP_CPSLOCK (SP_CAPS<<8) | SP_2
#define SP_TRUE    (SP_CAPS<<8) | SP_3
#define SP_INVERSE (SP_CAPS<<8) | SP_4
#define SP_LEFT    (SP_CAPS<<8) | SP_5
#define SP_DOWN    (SP_CAPS<<8) | SP_6
#define SP_UP      (SP_CAPS<<8) | SP_7
#define SP_RIGHT   (SP_CAPS<<8) | SP_8
#define SP_GRAPH   (SP_CAPS<<8) | SP_9
#define SP_DELETE  (SP_CAPS<<8) | SP_0
#define SP_BREAK   (SP_CAPS<<8) | SP_SPACE

// END of Spectrum keys definitions


// A key can be pressed with up to three key modifiers
// which generates 8 combinations for each key
#define EXT        0x080
#define MD_SHIFT   0x100
#define MD_CTRL    0x200
#define MD_ALT     0x400

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
//#define PC_F7      0x83  // not used. scan code>7F
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

#define MAP(pc,sp) {                                                          \
                           rom[(pc)*2] = (((sp)>>8)&0xFF);                    \
                           rom[(pc)*2+1] = (((sp))&0xFF);                     \
                         }
                         
#define MAPANY(pc,sp)   {                                                     \
                               MAP((pc),(sp));                                \
                               MAP(MD_SHIFT|(pc),(sp));                       \
                               MAP(MD_CTRL|(pc),(sp));                        \
                               MAP(MD_ALT|(pc),(sp));                         \
                               MAP(MD_SHIFT|MD_CTRL|(pc),(sp));               \
                               MAP(MD_SHIFT|MD_ALT|(pc),(sp));                \
                               MAP(MD_CTRL|MD_ALT|(pc),(sp));                 \
                               MAP(MD_SHIFT|MD_CTRL|MD_ALT|(pc),(sp));        \
                            }
                         
#define CLEANMAP {                                                            \
                    int i;                                                    \
                    for (i=0;i<(sizeof(rom)/sizeof(rom[0]));i++)              \
                      rom[i] = 0;                                             \
                 }
#define SAVEMAP1HEX(name) {                                                   \
                           FILE *f;                                           \
                           int i;                                             \
                           f=fopen(name,"w");                                 \
                           for(i=0;i<(sizeof(rom)/sizeof(rom[0]));i+=2)       \
                             fprintf(f,"%.2X\n",rom[i]);                      \
                           fclose(f);                                         \
                         }

#define SAVEMAP2HEX(name) {                                                   \
                           FILE *f;                                           \
                           int i;                                             \
                           f=fopen(name,"w");                                 \
                           for(i=1;i<(sizeof(rom)/sizeof(rom[0]));i+=2)       \
                               fprintf(f,"%.2X\n",rom[i]);                    \
                           fclose(f);                                         \
                         }

#define SAVEMAPBIN(name) {                                                    \
                           FILE *f;                                           \
                           f=fopen(name,"wb");                                \
                           fwrite (rom, 1, sizeof(rom), f);                   \
                           fclose(f);                                         \
                         }

int main()
{
    BYTE rom[4096];

    CLEANMAP;

    MAPANY(PC_LSHIFT,SP_CAPS);
    MAPANY(PC_RSHIFT,SP_CAPS);
    MAPANY(PC_LCTRL,SP_SYMBOL); // MD2 is CTRL
    MAPANY(PC_RCTRL,SP_SYMBOL); // MD2 is CTRL
    
    // Basic mapping: each key from PC is mapped to a key in the Spectrum
    MAPANY(PC_1,SP_1);
    MAPANY(PC_2,SP_2);
    MAPANY(PC_3,SP_3);
    MAPANY(PC_4,SP_4);
    MAPANY(PC_5,SP_5);
    MAPANY(PC_6,SP_6);
    MAPANY(PC_7,SP_7);
    MAPANY(PC_8,SP_8);
    MAPANY(PC_9,SP_9);
    MAPANY(PC_0,SP_0);

    MAPANY(PC_Q,SP_Q);
    MAPANY(PC_W,SP_W);
    MAPANY(PC_E,SP_E);
    MAPANY(PC_R,SP_R);
    MAPANY(PC_T,SP_T);
    MAPANY(PC_Y,SP_Y);
    MAPANY(PC_U,SP_U);
    MAPANY(PC_I,SP_I);
    MAPANY(PC_O,SP_O);
    MAPANY(PC_P,SP_P);
    MAPANY(PC_A,SP_A);
    MAPANY(PC_S,SP_S);
    MAPANY(PC_D,SP_D);
    MAPANY(PC_F,SP_F);
    MAPANY(PC_G,SP_G);
    MAPANY(PC_H,SP_H);
    MAPANY(PC_J,SP_J);
    MAPANY(PC_K,SP_K);
    MAPANY(PC_L,SP_L);
    MAPANY(PC_Z,SP_Z);
    MAPANY(PC_X,SP_X);
    MAPANY(PC_C,SP_C);
    MAPANY(PC_V,SP_V);
    MAPANY(PC_B,SP_B);
    MAPANY(PC_N,SP_N);
    MAPANY(PC_M,SP_M);

    MAPANY(PC_SPACE,SP_SPACE);
    MAPANY(PC_ENTER,SP_ENTER);
    MAPANY(PC_ESC,SP_BREAK);
    MAPANY(PC_CPSLOCK,SP_CPSLOCK);
    MAPANY(PC_TAB,SP_EXTEND);
    MAP(PC_BKSPACE,SP_DELETE);
    MAPANY(PC_UP,SP_UP);
    MAPANY(PC_DOWN,SP_DOWN);
    MAPANY(PC_LEFT,SP_LEFT);
    MAPANY(PC_RIGHT,SP_RIGHT);
    MAPANY(PC_F2,SP_EDIT);
    MAPANY(PC_F3,SP_TRUE);
    MAPANY(PC_F4,SP_INVERSE);
    MAPANY(PC_F10,SP_GRAPH);          // F10 habilita el modo gráfico. Esto es para Antonio, para la BIOS
    
    //keypad
    MAPANY(PC_KP_1,SP_1);
    MAPANY(PC_KP_2,SP_2);
    MAPANY(PC_KP_3,SP_3);
    MAPANY(PC_KP_4,SP_4);
    MAPANY(PC_KP_5,SP_5);
    MAPANY(PC_KP_6,SP_6);
    MAPANY(PC_KP_7,SP_7);
    MAPANY(PC_KP_8,SP_8);
    MAPANY(PC_KP_9,SP_9);
    MAPANY(PC_KP_0,SP_0);
    MAPANY(PC_KP_DIVIS,SP_SLASH);
    MAPANY(PC_KP_MULT,SP_STAR);
    MAPANY(PC_KP_MINUS,SP_MINUS);
    MAPANY(PC_KP_PLUS,SP_PLUS);
    MAPANY(PC_KP_ENTER,SP_ENTER);
    MAPANY(PC_KP_DOT,SP_DOT);

    MAPANY(PC_BACKSLA,SP_COLON);
    MAPANY(PC_APOSTRO,SP_DOLLAR);
    MAPANY(PC_OPNBANG,SP_EQUAL);
    MAPANY(PC_GRAVEAC,SP_PAROPEN);
    MAPANY(PC_PLUS,SP_PARCLOS);
    MAPANY(PC_EGNE,SP_SEMICOL);
    MAPANY(PC_ACUTEAC,SP_QUOTE);
    MAPANY(PC_COMMA,SP_COMMA);
    MAPANY(PC_DOT,SP_DOT);
    MAPANY(PC_MINUS,SP_SLASH);

    // End of mapping. Save .HEX file for Verilog
    //SAVEMAPHEX("keyb_av_hex.txt");
    // And map file for loading from ESXDOS
    SAVEMAPBIN("AV");
}
