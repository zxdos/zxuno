/*
 * keys_sp.h - ZX Spectrum keys definitions.
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2022, 2023 Miguel Angel Rodriguez Jodar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef KEYS_SP_H
#define KEYS_SP_H

/*
 * You shouldn't have to touch these defs unless your Spectrum has a different
 * keyboard layout (because, for example, you are using a different ROM)
 */

#define SP_1      0x61
#define SP_2      0x62
#define SP_3      0x64
#define SP_4      0x68
#define SP_5      0x70

#define SP_6      0x90
#define SP_7      0x88
#define SP_8      0x84
#define SP_9      0x82
#define SP_0      0x81

#define SP_Q      0x41
#define SP_W      0x42
#define SP_E      0x44
#define SP_R      0x48
#define SP_T      0x50

#define SP_Y      0xB0
#define SP_U      0xA8
#define SP_I      0xA4
#define SP_O      0xA2
#define SP_P      0xA1

#define SP_A      0x21
#define SP_S      0x22
#define SP_D      0x24
#define SP_F      0x28
#define SP_G      0x30

#define SP_H      0xD0
#define SP_J      0xC8
#define SP_K      0xC4
#define SP_L      0xC2
#define SP_ENTER  0xC1

#define SP_CAPS   0x01  /* CAPS SHIFT */
#define SP_Z      0x02
#define SP_X      0x04
#define SP_C      0x08
#define SP_V      0x10

#define SP_B      0xF0
#define SP_N      0xE8
#define SP_M      0xE4
#define SP_SYMBOL 0xE2  /* SYMBOL SHIFT */
#define SP_SPACE  0xE1

#define SP_EDIT     (SP_CAPS<<8) | SP_1       /* EDIT */
#define SP_CPSLOCK  (SP_CAPS<<8) | SP_2       /* CAPS LOCK */
#define SP_TRUE     (SP_CAPS<<8) | SP_3       /* TRUE VIDEO */
#define SP_INVERSE  (SP_CAPS<<8) | SP_4       /* INVERSE VIDEO */
#define SP_LEFT     (SP_CAPS<<8) | SP_5       /* LEFT ARROW */
#define SP_DOWN     (SP_CAPS<<8) | SP_6       /* DOWN ARROW */
#define SP_UP       (SP_CAPS<<8) | SP_7       /* UP ARROW */
#define SP_RIGHT    (SP_CAPS<<8) | SP_8       /* RIGHT ARROW */
#define SP_GRAPH    (SP_CAPS<<8) | SP_9       /* GRAPHICS MODE */
#define SP_DELETE   (SP_CAPS<<8) | SP_0       /* DELETE */

#define SP_EXTEND   (SP_CAPS<<8) | SP_SYMBOL  /* EXTEND MODE */
#define SP_BREAK    (SP_CAPS<<8) | SP_SPACE   /* BREAK */

#define SP_BANG     (SP_SYMBOL<<8) | SP_1     /* ! */
#define SP_AT       (SP_SYMBOL<<8) | SP_2     /* @ */
#define SP_HASH     (SP_SYMBOL<<8) | SP_3     /* # */
#define SP_DOLLAR   (SP_SYMBOL<<8) | SP_4     /* $ */
#define SP_PERCEN   (SP_SYMBOL<<8) | SP_5     /* % */
#define SP_AMP      (SP_SYMBOL<<8) | SP_6     /* & */
#define SP_APOSTRO  (SP_SYMBOL<<8) | SP_7     /* ' */
#define SP_PAROPEN  (SP_SYMBOL<<8) | SP_8     /* ( */
#define SP_PARCLOS  (SP_SYMBOL<<8) | SP_9     /* ) */
#define SP_UNDERSC  (SP_SYMBOL<<8) | SP_0     /* _ */

#define SP_LESSEQ   (SP_SYMBOL<<8) | SP_Q     /* <= */
#define SP_NOTEQ    (SP_SYMBOL<<8) | SP_W     /* != */
#define SP_GREATEQ  (SP_SYMBOL<<8) | SP_E     /* >= */
#define SP_LESS     (SP_SYMBOL<<8) | SP_R     /* < */
#define SP_GREATER  (SP_SYMBOL<<8) | SP_T     /* > */
#define SP_BRAOPEN  (SP_SYMBOL<<8) | SP_Y     /* [ */
#define SP_BRACLOS  (SP_SYMBOL<<8) | SP_U     /* ] */
#define SP_SEMICOL  (SP_SYMBOL<<8) | SP_O     /* ; */
#define SP_QUOTE    (SP_SYMBOL<<8) | SP_P     /* " */

#define SP_TILDE    (SP_SYMBOL<<8) | SP_A     /* ~ */
#define SP_PIPE     (SP_SYMBOL<<8) | SP_S     /* | */
#define SP_BACKSLA  (SP_SYMBOL<<8) | SP_D     /* \ */
#define SP_CUROPEN  (SP_SYMBOL<<8) | SP_F     /* { */
#define SP_CURCLOS  (SP_SYMBOL<<8) | SP_G     /* } */
#define SP_CARET    (SP_SYMBOL<<8) | SP_H     /* ^ */
#define SP_MINUS    (SP_SYMBOL<<8) | SP_J     /* - */
#define SP_PLUS     (SP_SYMBOL<<8) | SP_K     /* + */
#define SP_EQUAL    (SP_SYMBOL<<8) | SP_L     /* = */

#define SP_COLON    (SP_SYMBOL<<8) | SP_Z     /* : */
#define SP_POUND    (SP_SYMBOL<<8) | SP_X     /* £ */
#define SP_QUEST    (SP_SYMBOL<<8) | SP_C     /* ? */
#define SP_SLASH    (SP_SYMBOL<<8) | SP_V     /* / */
#define SP_STAR     (SP_SYMBOL<<8) | SP_B     /* * */
#define SP_COMMA    (SP_SYMBOL<<8) | SP_N     /* , */
#define SP_DOT      (SP_SYMBOL<<8) | SP_M     /* . */

#endif  /* !KEYS_SP_H */
