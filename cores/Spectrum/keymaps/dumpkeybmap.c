/*
 * dumpkeybmap - dumps ZX Spectrum core's keymap file for ZXUNO/ZXDOS.
 *
 * Copyright (C) 2023 Ivan Tatarinov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2023 Ivan Tatarinov
 * SPDX-FileContributor: 2023 Miguel Angel Rodriguez Jodar
 * SPDX-FileContributor: 2023 Antonio Villena
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <stdio.h>
#include <string.h>

#define PROGRAM "dumpkeybmap"
#define DESCRIPTION                                                          \
"Dumps ZX Spectrum core's keymap file for ZXUNO/ZXDOS."
#define VERSION "1.0"
#define COPYRIGHT                                                            \
"Copyright (C) 2023 Ivan Tatarinov\n"                                        \
"Contributors: 2023 Miguel Angel Rodriguez Jodar, Antonio Villena"
#define LICENSE                                                              \
"This program is free software: you can redistribute it and/or modify\n"     \
"it under the terms of the GNU General Public License as published by\n"     \
"the Free Software Foundation, either version 3 of the License, or\n"        \
"(at your option) any later version."
#define HOMEPAGE "https://github.com/ivan-tat/zxuno"

#define HELP_HINT                                                            \
"Use \"-h\" to get help."

typedef unsigned char u8;
typedef unsigned short u16;

/* Options */
char        opt_help=0;
char        opt_version=0;
const char *opt_if=NULL;

/* Length of key's name string */
#define KEY_LEN 32

/* Naming of keys for output */
#define KEY_PREFIX_PC "PC_"
#define KEY_PREFIX_SP "SP_"

/* This should be a part of index but is used in key's scan code, limiting
   the usage of keys with scan codes above 0x7F */
#define EXT       (1<<7)  /* Extended key flag */

/* PC key modifiers. Use any combination of these constants as first index to
   access `keymap[]' (valid range is 0->7) */
#define MOD_SHIFT (1<<0)
#define MOD_CTRL  (1<<1)
#define MOD_ALT   (1<<2)

/* Aliases for key modifiers used for output */
#define MOD_SHIFT_STR "MD_SHIFT"
#define MOD_CTRL_STR  "MD_CTRL"
#define MOD_ALT_STR   "MD_ALT"

/* Line prefix for output */
#define LINE_PREFIX "  "

/* Function names used for output */
#define FUNC_MAP      "map"
#define FUNC_MAPALFA  "map_alfa"
#define FUNC_MAPALL   "map_all"
#define FUNC_MAPXALL  "map_xall"

u8 keymap[8][256][2];

/* PS/2 keyboard scan codes (set 2, US).
   https://wiki.osdev.org/PS/2_Keyboard
   https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes */
const struct {
  char loc; /* 1=localized, 0=standard */
  const char *name;
  u8 key;
} pc_keys[]={ /* Key, press scan codes (release scan codes) */
  {0,"ESC",       0x76},      /* ESC, 76 (F076) */
  {0,"F1",        0x05},      /* F1,  05 (F005) */
  {0,"F2",        0x06},      /* F2,  06 (F006) */
  {0,"F3",        0x04},      /* F3,  04 (F004) */
  {0,"F4",        0x0C},      /* F4,  0C (F00C) */
  {0,"F5",        0x03},      /* F5,  03 (F003) */
  {0,"F6",        0x0B},      /* F6,  0B (F00B) */
  {0,"F7",        0x83},      /* F7,  83 (F083) */
  {0,"F8",        0x0A},      /* F8,  0A (F00A) */
  {0,"F9",        0x01},      /* F9,  01 (F001) */
  {0,"F10",       0x09},      /* F10, 09 (F009) */
  {0,"F11",       0x78},      /* F11, 78 (F078) */
  {0,"F12",       0x07},      /* F12, 07 (F007) */
/*{0,"PRTSCR",    ?},         // Prt Scr, E012E07C (E0F07CE0F012) */
  {0,"SCRLOCK",   0x7E},      /* Scroll Lock, 7E (F07E) */
/*{0,"PAUSE",     ?},         // Pause/Break, E11477E1F014E077 (None) */
  {1,"US_GRAVEAC",0x0E},      /* ` ~, 0E (F00E) */
  {0,"1",         0x16},      /* 1,   16 (F016) */
  {0,"2",         0x1E},      /* 2,   1E (F01E) */
  {0,"3",         0x26},      /* 3,   26 (F026) */
  {0,"4",         0x25},      /* 4,   25 (F025) */
  {0,"5",         0x2E},      /* 5,   2E (F02E) */
  {0,"6",         0x36},      /* 6,   36 (F036) */
  {0,"7",         0x3D},      /* 7,   3D (F03D) */
  {0,"8",         0x3E},      /* 8,   3E (F03E) */
  {0,"9",         0x46},      /* 9,   46 (F046) */
  {0,"0",         0x45},      /* 0,   45 (F045) */
  {1,"US_MINUS",  0x4E},      /* - _, 4E (F04E) */
  {1,"US_EQUAL",  0x55},      /* = +, 55 (F055) */
  {0,"BKSPACE",   0x66},      /* Backspace, 66 (F066) */
  {0,"TAB",       0x0D},      /* Tab, 66 (F066) */
  {0,"Q",         0x15},      /* Q,   15 (F015) */
  {0,"W",         0x1D},      /* W,   1D (F01D) */
  {0,"E",         0x24},      /* E,   24 (F024) */
  {0,"R",         0x2D},      /* R,   2D (F02D) */
  {0,"T",         0x2C},      /* T,   2C (F02C) */
  {0,"Y",         0x35},      /* Y,   35 (F035) */
  {0,"U",         0x3C},      /* U,   3C (F03C) */
  {0,"I",         0x43},      /* I,   43 (F043) */
  {0,"O",         0x44},      /* O,   44 (F044) */
  {0,"P",         0x4D},      /* P,   4D (F04D) */
  {1,"US_BRAOPEN",0x54},      /* [ {, 54 (F054) */
  {1,"US_BRACLOS",0x5B},      /* ] }, 5B (F05B) */
  {1,"US_BACKSLA",0x5D},      /* \ |, 5D (F05D) */
  {0,"CPSLOCK",   0x58},      /* Caps Lock, 58 (F058) */
  {0,"A",         0x1C},      /* A,   1C (F01C) */
  {0,"S",         0x1B},      /* S,   1B (F01B) */
  {0,"D",         0x23},      /* D,   23 (F023) */
  {0,"F",         0x2B},      /* F,   2B (F02B) */
  {0,"G",         0x34},      /* G,   34 (F034) */
  {0,"H",         0x33},      /* H,   33 (F033) */
  {0,"J",         0x3B},      /* J,   3B (F03B) */
  {0,"K",         0x42},      /* K,   42 (F042) */
  {0,"L",         0x4B},      /* L,   4B (F04B) */
  {1,"US_SEMICOL",0x4C},      /* ; :, 4C (F04C) */
  {1,"US_APOSTRO",0x52},      /* ' ", 52 (F052) */
  {0,"ENTER",     0x5A},      /* Enter, 52 (F052) */
  {0,"LSHIFT",    0x12},      /* Shift (left), 12 (F012) */
  {0,"Z",         0x1A},      /* Z,   1A (F01A) */
  {0,"X",         0x22},      /* X,   22 (F022) */
  {0,"C",         0x21},      /* C,   21 (F021) */
  {0,"V",         0x2A},      /* V,   2A (F02A) */
  {0,"B",         0x32},      /* B,   32 (F032) */
  {0,"N",         0x31},      /* N,   31 (F031) */
  {0,"M",         0x3A},      /* M,   3A (F03A) */
  {1,"US_COMMA",  0x41},      /* , <, 41 (F041) */
  {1,"US_DOT",    0x49},      /* . >, 49 (F049) */
  {1,"US_SLASH",  0x4A},      /* / ?, 4A (F04A) */
  {0,"RSHIFT",    0x59},      /* Shift (right), 59 (F059) */
  {0,"LCTRL",     0x14},      /* Ctrl (left), 14 (F014) */
  {0,"LWIN",      0x1F|EXT},  /* Windows (left), E01F (E0F01F)*/
  {0,"LALT",      0x11},      /* Alt (left), 11 (F011) */
  {0,"SPACE",     0x29},      /* Spacebar, 29 (F029) */
  {0,"RALT",      0x11|EXT},  /* Alt (right), E011 (E0F011) */
  {0,"RWIN",      0x27|EXT},  /* Windows (right), E027 (E0F027) */
  {0,"APPS",      0x2F|EXT},  /* Menus, E02F (E0F02F) */
  {0,"RCTRL",     0x14|EXT},  /* Ctrl (right), E014 (E0F014) */
  {0,"INSERT",    0x70|EXT},  /* Insert, E070 (E0F070) */
  {0,"HOME",      0x6C|EXT},  /* Home, E06C (E0F06C) */
  {0,"PGUP",      0x7D|EXT},  /* Page Up, E07D (E0F07D) */
  {0,"DELETE",    0x71|EXT},  /* Delete, E071 (E0F071) */
  {0,"END",       0x69|EXT},  /* End, E069 (E0F069) */
  {0,"PGDOWN",    0x7A|EXT},  /* Page Down, E07A (E0F07A) */
  {0,"UP",        0x75|EXT},  /* Up Arrow, E075 (E0F075) */
  {0,"LEFT",      0x6B|EXT},  /* Left Arrow, E06B (E0F06B) */
  {0,"DOWN",      0x72|EXT},  /* Down Arrow, E072 (E0F072) */
  {0,"RIGHT",     0x74|EXT},  /* Right Arrow, E074 (E0F074) */
  /* Keypad */
  {0,"NUMLOCK",   0x77},      /* Num Lock, 77 (F077) */
  {0,"KP_DIVIS",  0x4A|EXT},  /* /, E04A (E0F04A) */
  {0,"KP_MULT",   0x7C},      /* *, 7C (F07C) */
  {0,"KP_MINUS",  0x7B},      /* -, 7B (F07B) */
  {0,"KP_7",      0x6C},      /* 7, 6C (F06C) */
  {0,"KP_8",      0x75},      /* 8, 75 (F075) */
  {0,"KP_9",      0x7D},      /* 9, 7D (F07D) */
  {0,"KP_PLUS",   0x79},      /* +, 79 (F079) */
  {0,"KP_4",      0x6B},      /* 4, 6B (F06B) */
  {0,"KP_5",      0x73},      /* 5, 73 (F073) */
  {0,"KP_6",      0x74},      /* 6, 74 (F074) */
  {0,"KP_1",      0x69},      /* 1, 69 (F069) */
  {0,"KP_2",      0x72},      /* 2, 72 (F072) */
  {0,"KP_3",      0x7A},      /* 3, 7A (F07A) */
  {0,"KP_0",      0x70},      /* 0, 70 (F070) */
  {0,"KP_DOT",    0x71},      /* ., 71 (F071) */
  {0,"KP_ENTER",  0x5A|EXT},  /* Enter, E05A (E0F05A) */
  {0,NULL,0}                  /* stop mark */
};

/* ZX Spectrum keys ([B7<-B0]=[A2 A1 A0 D4 D3 D2 D1 D0])
   A=semi-row address: 0->3=left half, 4->7=right half
   D=bit mask for 5 keys (1=key is pressed) */
const struct {
  const char *name;
  u8 key;
} sp_keys[]={
  {"1",     0x61},  /* 1 */
  {"2",     0x62},  /* 2 */
  {"3",     0x64},  /* 3 */
  {"4",     0x68},  /* 4 */
  {"5",     0x70},  /* 5 */
  {"6",     0x90},  /* 6 */
  {"7",     0x88},  /* 7 */
  {"8",     0x84},  /* 8 */
  {"9",     0x82},  /* 9 */
  {"0",     0x81},  /* 0 */
  {"Q",     0x41},  /* Q */
  {"W",     0x42},  /* W */
  {"E",     0x44},  /* E */
  {"R",     0x48},  /* R */
  {"T",     0x50},  /* T */
  {"Y",     0xB0},  /* Y */
  {"U",     0xA8},  /* U */
  {"I",     0xA4},  /* I */
  {"O",     0xA2},  /* O */
  {"P",     0xA1},  /* P */
  {"A",     0x21},  /* A */
  {"S",     0x22},  /* S */
  {"D",     0x24},  /* D */
  {"F",     0x28},  /* F */
  {"G",     0x30},  /* G */
  {"H",     0xD0},  /* H */
  {"J",     0xC8},  /* J */
  {"K",     0xC4},  /* K */
  {"L",     0xC2},  /* L */
  {"ENTER", 0xC1},  /* ENTER */
  {"CAPS",  0x01},  /* CAPS SHIFT */
  {"Z",     0x02},  /* Z */
  {"X",     0x04},  /* X */
  {"C",     0x08},  /* C */
  {"V",     0x10},  /* V */
  {"B",     0xF0},  /* B */
  {"N",     0xE8},  /* N */
  {"M",     0xE4},  /* M */
  {"SYMBOL",0xE2},  /* SYMBOL SHIFT */
  {"SPACE", 0xE1},  /* SPACE */
  {NULL,0}          /* stop mark */
};

/* ZX Spectrum 2-keys combinations */
const struct {
  const char *name;
  u8 keys[2];
} sp_keys2[]={
  {"EDIT",   {0x01,0x61}},  /* SP_CAPS+SP_1 */
  {"CPSLOCK",{0x01,0x62}},  /* SP_CAPS+SP_2 */
  {"TRUE",   {0x01,0x64}},  /* SP_CAPS+SP_3 */
  {"INVERSE",{0x01,0x68}},  /* SP_CAPS+SP_4 */
  {"LEFT",   {0x01,0x70}},  /* SP_CAPS+SP_5 */
  {"DOWN",   {0x01,0x90}},  /* SP_CAPS+SP_6 */
  {"UP",     {0x01,0x88}},  /* SP_CAPS+SP_7 */
  {"RIGHT",  {0x01,0x84}},  /* SP_CAPS+SP_8 */
  {"GRAPH",  {0x01,0x82}},  /* SP_CAPS+SP_9 */
  {"DELETE", {0x01,0x81}},  /* SP_CAPS+SP_0 */
  {"EXTEND", {0x01,0xE2}},  /* SP_CAPS+SP_SYMBOL */
  {"BREAK",  {0x01,0xE1}},  /* SP_CAPS+SP_SPACE */
  {"BANG",   {0xE2,0x61}},  /* !  SP_SYMBOL+SP_1 */
  {"AT",     {0xE2,0x62}},  /* @  SP_SYMBOL+SP_2 */
  {"HASH",   {0xE2,0x64}},  /* #  SP_SYMBOL+SP_3 */
  {"DOLLAR", {0xE2,0x68}},  /* $  SP_SYMBOL+SP_4 */
  {"PERCEN", {0xE2,0x70}},  /* %  SP_SYMBOL+SP_5 */
  {"AMP",    {0xE2,0x90}},  /* &  SP_SYMBOL+SP_6 */
  {"APOSTRO",{0xE2,0x88}},  /* '  SP_SYMBOL+SP_7 */
  {"PAROPEN",{0xE2,0x84}},  /* (  SP_SYMBOL+SP_8 */
  {"PARCLOS",{0xE2,0x82}},  /* )  SP_SYMBOL+SP_9 */
  {"UNDERSC",{0xE2,0x81}},  /* _  SP_SYMBOL+SP_0 */
  {"LESSEQ", {0xE2,0x41}},  /* <= SP_SYMBOL+SP_Q */
  {"NOTEQ",  {0xE2,0x42}},  /* <> SP_SYMBOL+SP_W */
  {"GREATEQ",{0xE2,0x44}},  /* >= SP_SYMBOL+SP_E */
  {"LESS",   {0xE2,0x48}},  /* <  SP_SYMBOL+SP_R */
  {"GREATER",{0xE2,0x50}},  /* >  SP_SYMBOL+SP_T */
  {"BRAOPEN",{0xE2,0xB0}},  /* [  SP_SYMBOL+SP_Y */
  {"BRACLOS",{0xE2,0xA8}},  /* ]  SP_SYMBOL+SP_U */
  {"SEMICOL",{0xE2,0xA2}},  /* ;  SP_SYMBOL+SP_O */
  {"QUOTE",  {0xE2,0xA1}},  /* "  SP_SYMBOL+SP_P */
  {"TILDE",  {0xE2,0x21}},  /* ~  SP_SYMBOL+SP_A */
  {"PIPE",   {0xE2,0x22}},  /* |  SP_SYMBOL+SP_S */
  {"BACKSLA",{0xE2,0x24}},  /* \  SP_SYMBOL+SP_D */
  {"CUROPEN",{0xE2,0x28}},  /* {  SP_SYMBOL+SP_F */
  {"CURCLOS",{0xE2,0x30}},  /* }  SP_SYMBOL+SP_G */
  {"CARET",  {0xE2,0xD0}},  /* ^  SP_SYMBOL+SP_H */
  {"MINUS",  {0xE2,0xC8}},  /* -  SP_SYMBOL+SP_J */
  {"PLUS",   {0xE2,0xC4}},  /* +  SP_SYMBOL+SP_K */
  {"EQUAL",  {0xE2,0xC2}},  /* =  SP_SYMBOL+SP_L */
  {"COLON",  {0xE2,0x02}},  /* :  SP_SYMBOL+SP_Z */
  {"POUND",  {0xE2,0x04}},  /* £  SP_SYMBOL+SP_X */
  {"QUEST",  {0xE2,0x08}},  /* ?  SP_SYMBOL+SP_C */
  {"SLASH",  {0xE2,0x10}},  /* /  SP_SYMBOL+SP_V */
  {"STAR",   {0xE2,0xF0}},  /* *  SP_SYMBOL+SP_B */
  {"COMMA",  {0xE2,0xE8}},  /* ,  SP_SYMBOL+SP_N */
  {"DOT",    {0xE2,0xE4}},  /* .  SP_SYMBOL+SP_M */
  {NULL,{0,0}}              /* stop mark */
};

#include "errors.c"

void show_version() {
  printf(
    PROGRAM ", version " VERSION " (built on " __DATE__ " " __TIME__ ")\n"
  );
}

void show_usage() {
  show_version();
  printf(
    DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: <" HOMEPAGE ">\n"
  );
  printf(
    "\n"
    "Usage:\n"
    "  " PROGRAM " [options...] | INPUT\n"
    "\n"
    "Options:\n"
    "  -h, --help     Show this help\n"
    "  -v, --version  Show version\n"
    "\n"
    "Where:\n"
    "  INPUT - ZX Spectrum core's keymap file (4 KiB size)\n"
  );
}

/* 1 if PC key is mapped directly or with any modifier to Spectrum key(s) */
char is_mapped(u8 pc) {
  u8 m;
  for(m=0;m<8;m++) if(keymap[m][pc][0]||keymap[m][pc][1]) return 1;
  return 0;
}

/* 1 if PC key is mapped directly and with Shift / CAPS SHIFT modifiers to
   Spectrum key(s) */
char is_mapped_alfa(u8 pc) {
  if((keymap[0][pc][0]==0)
  && (keymap[0][pc][1]!=0)
  && (keymap[1][pc][0]==0x01)
  && (keymap[1][pc][1]==keymap[0][pc][1])) {
    u8 m;
    for(m=2;m<8;m++) if(keymap[m][pc][0]||keymap[m][pc][1]) return 0;
    return 1;
  }
  return 0;
}

/* 1 if PC key is mapped directly and with all modifiers to Spectrum key(s) */
char is_mapped_all(u8 pc) {
  u8 m;
  for(m=1;m<8;m++)
    if((keymap[0][pc][0]!=keymap[m][pc][0])
    || (keymap[0][pc][1]!=keymap[m][pc][1])) return 0;
  return 1; /* Mapped directly and with all modifiers */
}

/* 1 if PC key is mapped not directly but with all modifiers to Spectrum
   key(s) */
char is_mapped_xall(u8 pc) {
  if((keymap[0][pc][0]==0)&&(keymap[0][pc][1]==0)) {
    /* Not mapped directly */
    u8 m;
    for(m=2;m<8;m++)
      if((keymap[1][pc][0]!=keymap[m][pc][0])
      || (keymap[1][pc][1]!=keymap[m][pc][1])) return 0;
    return 1; /* Not mapped directly but with all modifiers */
  } else return 0;
}

/* Return index of PC key in `pc_keys' array or -1 if failed */
int find_pc_key(u8 pc) {
  int i;
  for(i=0;pc_keys[i].name;i++) if(pc_keys[i].key==pc) return i;
  return -1;
}

void get_pc_name(char *str,size_t size,u8 pc) {
  int i=find_pc_key(pc);
  if(i>=0)
    snprintf(str,size,"%s%s",(char*)KEY_PREFIX_PC,(char*)pc_keys[i].name);
  else
    snprintf(str,size,"0x%02hhX",(unsigned char)pc);
}

/* Return index of ZX Spectrum key in `sp_keys' array or -1 if failed */
int find_sp_key(u8 sp) {
  int i;
  for(i=0;sp_keys[i].name;i++) if(sp_keys[i].key==sp) return i;
  return -1;
}

void get_sp_name(char *str,size_t size,u8 sp) {
  int i=find_sp_key(sp);
  if(i>=0) {
    snprintf(str,size,KEY_PREFIX_SP "%s",(char*)sp_keys[i].name);
  } else {
    snprintf(str,size,"0x%02hhX",(unsigned char)sp);
  }
}

/* Return index of ZX Spectrum key in `sp_keys2' array or -1 if failed */
int find_sp_keys2(u8 sp0,u8 sp1) {
  int i;
  for(i=0;sp_keys2[i].name;i++)
    if(((sp_keys2[i].keys[0]==sp0)&&(sp_keys2[i].keys[1]==sp1))
    || ((sp_keys2[i].keys[0]==sp1)&&(sp_keys2[i].keys[1]==sp0))) return i;
  return -1;
}

void get_sp_name_any(char *str,size_t size,u8 sp0,u8 sp1) {
  if(!sp0) { sp0=sp1; sp1=0; }
  if(sp0==sp1) sp1=0;
  if(sp1) {
    /* key 0 + key 1 */
    int i=find_sp_keys2(sp0,sp1);
    if(i>=0) {
      snprintf(str,size,KEY_PREFIX_SP "%s",(char*)sp_keys2[i].name);
    } else {
      char spn[2][KEY_LEN];
      get_sp_name(spn[0],KEY_LEN,sp0);
      get_sp_name(spn[1],KEY_LEN,sp1);
      snprintf(str,size,"(%s<<8)|%s",(char*)spn[0],(char*)spn[1]);
    }
  } else {
    /* key 0 only */
    char spn[KEY_LEN];
    get_sp_name(spn,KEY_LEN,sp0);
    snprintf(str,size,"%s",(char*)spn);
  }
}

const char *pc_mods[]={MOD_SHIFT_STR,MOD_CTRL_STR,MOD_ALT_STR};

void print_mods(u8 m) {
  u8 mask=1<<2,i;
  for(i=3;i;i--) {
    if(m&mask) printf("%s|",(char*)pc_mods[i-1]);
    mask>>=1;
  }
}

/* force=0 to skip unmapped unknown key, otherwise dump it */
void dump_key(u8 pc,char force) {
  char pcn[KEY_LEN];
  get_pc_name(pcn,KEY_LEN,pc);
  if(is_mapped(pc)) {
    char spn[KEY_LEN];
    if(is_mapped_alfa(pc)) {
      get_sp_name_any(spn,KEY_LEN,keymap[0][pc][0],keymap[0][pc][1]);
      printf(LINE_PREFIX FUNC_MAPALFA "(%s,%s);\n",(char*)pcn,(char*)spn);
    } else if(is_mapped_all(pc)) {
      get_sp_name_any(spn,KEY_LEN,keymap[0][pc][0],keymap[0][pc][1]);
      printf(LINE_PREFIX FUNC_MAPALL "(%s,%s);\n",(char*)pcn,(char*)spn);
    } else if(is_mapped_xall(pc)) {
      get_sp_name_any(spn,KEY_LEN,keymap[1][pc][0],keymap[1][pc][1]);
      printf(LINE_PREFIX FUNC_MAPXALL "(%s,%s);\n",(char*)pcn,(char*)spn);
    } else {
      u8 m;
      for(m=0;m<8;m++) {
        u8 sp[2];
        sp[0]=keymap[m][pc][0];
        sp[1]=keymap[m][pc][1];
        if(sp[0]||sp[1]) {
          printf(LINE_PREFIX FUNC_MAP "(");
          if(m) print_mods(m);
          get_sp_name_any(spn,KEY_LEN,sp[0],sp[1]);
          printf("%s,%s);\n",(char*)pcn,(char*)spn);
        }
      }
    }
  } else {
    if(force)
      printf(LINE_PREFIX "/* Key %s is not mapped */\n",(char*)pcn);
  }
}

void dump_localized_defs() {
  int pl=strlen(KEY_PREFIX_PC),l=0,k;
  /* get key name's maximal length */
  for(k=0;pc_keys[k].name;k++)
    if(pc_keys[k].loc==1) {
      int len=pl+strlen(pc_keys[k].name);
      if(l<len) l=len;
    }
  /* dump localized keys definitions */
  for(k=0;pc_keys[k].name;k++)
    if(pc_keys[k].loc==1) {
      int n=l-pl-strlen(pc_keys[k].name);
      printf("#define %s%s ",(char*)KEY_PREFIX_PC,(char*)pc_keys[k].name);
      while(n>0) { printf(" "); n--; }  /* padding */
      printf("0x%02hhX\n",(unsigned char)pc_keys[k].key);
    }
}

/* f=256 x 1-bit flags (packed) for processed keys */
void dump_known_keys(char loc,u8 *f) {
  int i;
  for(i=0;pc_keys[i].name;i++)
    if(pc_keys[i].loc==loc) {
      int k=pc_keys[i].key;
      dump_key(k,1);
      f[k/8]|=1<<(k%8); /* mark key as processed */
    }
}

void dump_unknown_keys(u8 *f) {
  int k;
  for(k=0;k<256;k++) if(!(f[k/8]&(1<<(k%8)))) dump_key(k,0);
}

void dump_keymap() {
  u8 f[256/8];  /* 256 x 1-bit flags (packed) for processed keys */
  memset(f,0,sizeof(f));
  printf("%s",
    "/*\n"
    " * keymap_us.c\n"
    " *\n"
    " * SPDX-FileType: SOURCE\n"
    " * SPDX-FileCopyrightText: ?\n"
    " * SPDX-FileContributor: ?\n"
    " * SPDX-FileNotice: ?\n"
    " * SPDX-License-Identifier: GPL-3.0-or-later\n"
    " * SPDX-LicenseComments: ?\n"
    " */\n"
    "\n"
    "#define KEYMAP_US  \"us\"\n"
    "#define COMMENT_US \"English (US) layout\"\n"
    "#define VERSION_US \"1.0\"\n"
    "\n"
  );
  dump_localized_defs();
  printf("%s",
    "\n"
    "void gen_keymap_us() {\n"
    LINE_PREFIX "/* Standard keys: */\n"
  );
  dump_known_keys(0,f);
  printf("%s","\n" LINE_PREFIX "/* Localized keys: */\n");
  dump_known_keys(1,f);
  dump_unknown_keys(f);
  printf("}\n");
}

/* Returns 0 on success, 1 if no arguments, other value on other error */
int parse_args(int argc,const char **argv) {
  int f,i;
  char optsend=0;
  if(argc==1) return 1;
  f=0;
  for(i=1;i<argc;i++) {
    if((!optsend)&&(argv[i][0]=='-')) {
      if(!strcmp(&argv[i][1],"-")) optsend=1;
      else if((!strcmp(&argv[i][1],"h"))
           ||  (!strcmp(&argv[i][1],"-help"))) opt_help=1;
      else if((!strcmp(&argv[i][1],"v"))
           ||  (!strcmp(&argv[i][1],"-version"))) opt_version=1;
      else {
        error("Unknown option \"%s\" (argument %u)",argv[i],i);
        return -1;
      }
    } else {
      switch(f++) {
      case 0: opt_if=argv[i]; break;
      default:
        error("Extra parameter \"%s\" given (argument %u)",argv[i],i);
        return -1;
      }
    }
  }
  return 0;
}

int read_raw(void *data,size_t size,const char *name) {
  FILE *f=fopen(name,"r");
  if(!f) {
    error("Failed to open input file \"%s\"",name);
    return 1;
  }
  if(!fread(data,size,1,f)) {
    fclose(f);
    error("Failed to read input file \"%s\"",name);
    return 1;
  }
  fclose(f);
  return 0;
}

int main(int argc,const char **argv) {
  switch(parse_args(argc,argv)) {
  case 0: break;
  case 1:
    message("No parameters. " HELP_HINT);
    return 0;
  default:
    return -1;
  }

  if(opt_help) {
    show_usage();
    return 0;
  }

  if(opt_version) {
    show_version();
    return 0;
  }

  if(!opt_if) {
    error("No input file specified");
    return 1;
  }

  if(read_raw(keymap,sizeof(keymap),opt_if)) return 1;

  dump_keymap();
  return 0;
}
