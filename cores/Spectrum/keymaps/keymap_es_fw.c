/*
 * keymap_es_fw.c
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2014-2023 Miguel Angel Rodriguez Jodar
 * SPDX-FileContributor: 2016, 2018, 2022 Antonio Villena
 * SPDX-FileContributor: 2023 Ivan Tatarinov
 * SPDX-FileNotice: Based on https://github.com/zxdos/zxuno/blob/24d87411bb1869d89c7128fe5909c3cabb9603b9/firmware/es.zx7b
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#define KEYMAP_ES_FW  "es-fw"
#define COMMENT_ES_FW "Spanish (ES) layout for firmware"
#define VERSION_ES_FW "2022-02-04"

#define PC_ES_FW_BACKSLA 0x0E
#define PC_ES_FW_APOSTRO 0x4E
#define PC_ES_FW_OPNBANG 0x55
#define PC_ES_FW_GRAVEAC 0x54
#define PC_ES_FW_PLUS    0x5B
#define PC_ES_FW_EGNE    0x4C
#define PC_ES_FW_ACUTEAC 0x52
#define PC_ES_FW_CEDILLA 0x5D
#define PC_ES_FW_LESS    0x61
#define PC_ES_FW_COMMA   0x41
#define PC_ES_FW_DOT     0x49
#define PC_ES_FW_MINUS   0x4A

void gen_keymap_es_fw() {
  /* Standard keys: */
  map_all(PC_ESC,SP_BREAK);
  /* Key PC_F1 is not mapped */
  map_all(PC_F2,SP_EDIT);
  /* Key PC_F3 is not mapped */
  /* Key PC_F4 is not mapped */
  /* Key PC_F5 is not mapped */
  /* Key PC_F6 is not mapped */
  /* Key PC_F7 is not mapped */
  /* Key PC_F8 is not mapped */
  /* Key PC_F9 is not mapped */
  map(PC_F10,SP_GRAPH);
  /* Key PC_F11 is not mapped */
  /* Key PC_F12 is not mapped */
  /* Key PC_SCRLOCK is not mapped */
  map(PC_1,SP_1);
  map(MD_SHIFT|PC_1,SP_BANG);
  map(PC_2,SP_2);
  map(MD_SHIFT|PC_2,SP_QUOTE);
  map(PC_3,SP_3);
  map(MD_SHIFT|PC_3,SP_HASH);
  map(PC_4,SP_4);
  map(MD_SHIFT|PC_4,SP_DOLLAR);
  map(PC_5,SP_5);
  map(MD_SHIFT|PC_5,SP_PERCEN);
  map(PC_6,SP_6);
  map(MD_SHIFT|PC_6,SP_AMP);
  map(PC_7,SP_7);
  map(MD_SHIFT|PC_7,SP_SLASH);
  map(PC_8,SP_8);
  map(MD_SHIFT|PC_8,SP_PAROPEN);
  map(PC_9,SP_9);
  map(MD_SHIFT|PC_9,SP_PARCLOS);
  map(PC_0,SP_0);
  map(MD_SHIFT|PC_0,SP_EQUAL);
  map(PC_BKSPACE,SP_DELETE);
  map_all(PC_TAB,SP_EXTEND);
  map_alfa(PC_Q,SP_Q);
  map_alfa(PC_W,SP_W);
  map_alfa(PC_E,SP_E);
  map_alfa(PC_R,SP_R);
  map_alfa(PC_T,SP_T);
  map_alfa(PC_Y,SP_Y);
  map_alfa(PC_U,SP_U);
  map_alfa(PC_I,SP_I);
  map_alfa(PC_O,SP_O);
  map_alfa(PC_P,SP_P);
  map_all(PC_CPSLOCK,SP_CPSLOCK);
  map_alfa(PC_A,SP_A);
  map_alfa(PC_S,SP_S);
  map_alfa(PC_D,SP_D);
  map_alfa(PC_F,SP_F);
  map_alfa(PC_G,SP_G);
  map_alfa(PC_H,SP_H);
  map_alfa(PC_J,SP_J);
  map_alfa(PC_K,SP_K);
  map_alfa(PC_L,SP_L);
  map_all(PC_ENTER,SP_ENTER);
  /* Key PC_LSHIFT is not mapped */
  map_alfa(PC_Z,SP_Z);
  map_alfa(PC_X,SP_X);
  map_alfa(PC_C,SP_C);
  map_alfa(PC_V,SP_V);
  map_alfa(PC_B,SP_B);
  map_alfa(PC_N,SP_N);
  map_alfa(PC_M,SP_M);
  /* Key PC_RSHIFT is not mapped */
  map_all(PC_LCTRL,SP_CAPS);
  /* Key PC_LWIN is not mapped */
  /* Key PC_LALT is not mapped */
  map_all(PC_SPACE,SP_SPACE);
  /* Key PC_RALT is not mapped */
  /* Key PC_RWIN is not mapped */
  map_all(PC_APPS,SP_SYMBOL);
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
  /* Key PC_KP_7 is not mapped */
  /* Key PC_KP_8 is not mapped */
  /* Key PC_KP_9 is not mapped */
  map_all(PC_KP_PLUS,SP_PLUS);
  /* Key PC_KP_4 is not mapped */
  /* Key PC_KP_5 is not mapped */
  /* Key PC_KP_6 is not mapped */
  /* Key PC_KP_1 is not mapped */
  /* Key PC_KP_2 is not mapped */
  /* Key PC_KP_3 is not mapped */
  /* Key PC_KP_0 is not mapped */
  map_all(PC_KP_DOT,SP_DOT);
  map_all(PC_KP_ENTER,SP_ENTER);

  /* Localized keys: */
  map(PC_ES_FW_BACKSLA,SP_BACKSLA);
  map(MD_SHIFT|PC_ES_FW_BACKSLA,SP_BACKSLA);
  map(PC_ES_FW_APOSTRO,SP_APOSTRO);
  map(MD_SHIFT|PC_ES_FW_APOSTRO,SP_QUEST);
  /* Key PC_ES_FW_OPNBANG is not mapped */
  map(PC_ES_FW_GRAVEAC,SP_POUND);
  map(MD_SHIFT|PC_ES_FW_GRAVEAC,SP_CARET);
  map(PC_ES_FW_PLUS,SP_PLUS);
  map(MD_SHIFT|PC_ES_FW_PLUS,SP_STAR);
  map(PC_ES_FW_EGNE,SP_TILDE);
  map(PC_ES_FW_ACUTEAC,SP_CUROPEN);
  map(MD_SHIFT|PC_ES_FW_ACUTEAC,SP_CUROPEN);
  map(PC_ES_FW_CEDILLA,SP_CURCLOS);
  map(MD_SHIFT|PC_ES_FW_CEDILLA,SP_QUOTE);
  map(PC_ES_FW_LESS,SP_LESS);
  map(MD_SHIFT|PC_ES_FW_LESS,SP_GREATER);
  map(MD_CTRL|PC_ES_FW_LESS,SP_LESSEQ);
  map(MD_CTRL|MD_SHIFT|PC_ES_FW_LESS,SP_GREATEQ);
  map(MD_ALT|PC_ES_FW_LESS,SP_NOTEQ);
  map(MD_ALT|MD_SHIFT|PC_ES_FW_LESS,SP_NOTEQ);
  map(MD_ALT|MD_CTRL|PC_ES_FW_LESS,SP_NOTEQ);
  map(MD_ALT|MD_CTRL|MD_SHIFT|PC_ES_FW_LESS,SP_NOTEQ);
  map(PC_ES_FW_COMMA,SP_COMMA);
  map(MD_SHIFT|PC_ES_FW_COMMA,SP_SEMICOL);
  map(PC_ES_FW_DOT,SP_DOT);
  map(MD_SHIFT|PC_ES_FW_DOT,SP_COLON);
  map(PC_ES_FW_MINUS,SP_MINUS);
  map(MD_SHIFT|PC_ES_FW_MINUS,SP_UNDERSC);
}
