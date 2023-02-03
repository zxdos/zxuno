/*
 * keymap_av_sd.c
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2014-2023 Miguel Angel Rodriguez Jodar
 * SPDX-FileContributor: 2018 Antonio Villena
 * SPDX-FileContributor: 2023 Ivan Tatarinov
 * SPDX-FileNotice: Based on https://github.com/zxdos/zxuno/blob/f838fb61d92d6a263feb54521c23b0f990c8362f/SD/SYS/KEYMAPS/AV
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#define KEYMAP_AV_SD  "av-sd"
#define COMMENT_AV_SD "Spanish (ES) layout for SD card"
#define VERSION_AV_SD "2018-10-15"

#define PC_AV_SD_BACKSLA 0x0E
#define PC_AV_SD_APOSTRO 0x4E
#define PC_AV_SD_OPNBANG 0x55
#define PC_AV_SD_GRAVEAC 0x54
#define PC_AV_SD_PLUS    0x5B
#define PC_AV_SD_EGNE    0x4C
#define PC_AV_SD_ACUTEAC 0x52
#define PC_AV_SD_CEDILLA 0x5D
#define PC_AV_SD_LESS    0x61
#define PC_AV_SD_COMMA   0x41
#define PC_AV_SD_DOT     0x49
#define PC_AV_SD_MINUS   0x4A

void gen_keymap_av_sd() {
  /* Standard keys: */
  map_all(PC_ESC,SP_BREAK);
  /* Key PC_F1 is not mapped */
  map_all(PC_F2,SP_EDIT);
  map_all(PC_F3,SP_TRUE);
  map_all(PC_F4,SP_INVERSE);
  /* Key PC_F5 is not mapped */
  /* Key PC_F6 is not mapped */
  /* Key PC_F7 is not mapped */
  /* Key PC_F8 is not mapped */
  /* Key PC_F9 is not mapped */
  map_all(PC_F10,SP_GRAPH);
  /* Key PC_F11 is not mapped */
  /* Key PC_F12 is not mapped */
  /* Key PC_SCRLOCK is not mapped */
  map_all(PC_1,SP_1);
  map_all(PC_2,SP_2);
  map_all(PC_3,SP_3);
  map_all(PC_4,SP_4);
  map_all(PC_5,SP_5);
  map_all(PC_6,SP_6);
  map_all(PC_7,SP_7);
  map_all(PC_8,SP_8);
  map_all(PC_9,SP_9);
  map_all(PC_0,SP_0);
  map(PC_BKSPACE,SP_DELETE);
  map_all(PC_TAB,SP_EXTEND);
  map_all(PC_Q,SP_Q);
  map_all(PC_W,SP_W);
  map_all(PC_E,SP_E);
  map_all(PC_R,SP_R);
  map_all(PC_T,SP_T);
  map_all(PC_Y,SP_Y);
  map_all(PC_U,SP_U);
  map_all(PC_I,SP_I);
  map_all(PC_O,SP_O);
  map_all(PC_P,SP_P);
  map_all(PC_CPSLOCK,SP_CPSLOCK);
  map_all(PC_A,SP_A);
  map_all(PC_S,SP_S);
  map_all(PC_D,SP_D);
  map_all(PC_F,SP_F);
  map_all(PC_G,SP_G);
  map_all(PC_H,SP_H);
  map_all(PC_J,SP_J);
  map_all(PC_K,SP_K);
  map_all(PC_L,SP_L);
  map_all(PC_ENTER,SP_ENTER);
  map_all(PC_LSHIFT,SP_CAPS);
  map_all(PC_Z,SP_Z);
  map_all(PC_X,SP_X);
  map_all(PC_C,SP_C);
  map_all(PC_V,SP_V);
  map_all(PC_B,SP_B);
  map_all(PC_N,SP_N);
  map_all(PC_M,SP_M);
  map_all(PC_RSHIFT,SP_CAPS);
  map_all(PC_LCTRL,SP_SYMBOL);
  /* Key PC_LWIN is not mapped */
  /* Key PC_LALT is not mapped */
  map_all(PC_SPACE,SP_SPACE);
  /* Key PC_RALT is not mapped */
  /* Key PC_RWIN is not mapped */
  /* Key PC_APPS is not mapped */
  map_all(PC_RCTRL,SP_SYMBOL);
  /* Key PC_INSERT is not mapped */
  /* Key PC_HOME is not mapped */
  /* Key PC_PGUP is not mapped */
  /* Key PC_DELETE is not mapped */
  /* Key PC_END is not mapped */
  /* Key PC_PGDOWN is not mapped */
  map_all(PC_UP,SP_UP);
  map_all(PC_LEFT,SP_LEFT);
  map_all(PC_DOWN,SP_DOWN);
  map_all(PC_RIGHT,SP_RIGHT);
  /* Key PC_NUMLOCK is not mapped */
  map_all(PC_KP_DIVIS,SP_SLASH);
  map_all(PC_KP_MULT,SP_STAR);
  map_all(PC_KP_MINUS,SP_MINUS);
  map_all(PC_KP_7,SP_7);
  map_all(PC_KP_8,SP_8);
  map_all(PC_KP_9,SP_9);
  map_all(PC_KP_PLUS,SP_PLUS);
  map_all(PC_KP_4,SP_4);
  map_all(PC_KP_5,SP_5);
  map_all(PC_KP_6,SP_6);
  map_all(PC_KP_1,SP_1);
  map_all(PC_KP_2,SP_2);
  map_all(PC_KP_3,SP_3);
  map_all(PC_KP_0,SP_0);
  map_all(PC_KP_DOT,SP_DOT);
  map_all(PC_KP_ENTER,SP_ENTER);

  /* Localized keys: */
  map_all(PC_AV_SD_BACKSLA,SP_COLON);
  map_all(PC_AV_SD_APOSTRO,SP_DOLLAR);
  map_all(PC_AV_SD_OPNBANG,SP_EQUAL);
  map_all(PC_AV_SD_GRAVEAC,SP_PAROPEN);
  map_all(PC_AV_SD_PLUS,SP_PARCLOS);
  map_all(PC_AV_SD_EGNE,SP_SEMICOL);
  map_all(PC_AV_SD_ACUTEAC,SP_QUOTE);
  /* Key PC_AV_SD_CEDILLA is not mapped */
  /* Key PC_AV_SD_LESS is not mapped */
  map_all(PC_AV_SD_COMMA,SP_COMMA);
  map_all(PC_AV_SD_DOT,SP_DOT);
  map_all(PC_AV_SD_MINUS,SP_SLASH);
}
