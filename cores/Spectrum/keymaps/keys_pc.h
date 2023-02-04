/*
 * keys_pc.h - PS/2 keyboard scan codes (set 2) without localized keys.
 *
 * https://wiki.osdev.org/PS/2_Keyboard
 * https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2022, 2023 Miguel Angel Rodriguez Jodar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef KEYS_PC_H
#define KEYS_PC_H

/* Extended scan code flag, received from PS/2 controller, but mapped into
   key's scan code field thus limiting the usage of scan codes above 0x7F */
#define EXT         (1<<7)

/* A key can be pressed with up to three key modifiers
   which generates 8 combinations for each key */
#define MD_SHIFT    (1<<8)
#define MD_CTRL     (1<<9)
#define MD_ALT      (1<<10)

/* PS/2 keyboard scan codes (set 2) */

#define PC_A        0x1C
#define PC_B        0x32
#define PC_C        0x21
#define PC_D        0x23
#define PC_E        0x24
#define PC_F        0x2B
#define PC_G        0x34
#define PC_H        0x33
#define PC_I        0x43
#define PC_J        0x3B
#define PC_K        0x42
#define PC_L        0x4B
#define PC_M        0x3A
#define PC_N        0x31
#define PC_O        0x44
#define PC_P        0x4D
#define PC_Q        0x15
#define PC_R        0x2D
#define PC_S        0x1B
#define PC_T        0x2C
#define PC_U        0x3C
#define PC_V        0x2A
#define PC_W        0x1D
#define PC_X        0x22
#define PC_Y        0x35
#define PC_Z        0x1A

#define PC_0        0x45  /* 0 ) */
#define PC_1        0x16  /* 1 ! */
#define PC_2        0x1E  /* 2 @ */
#define PC_3        0x26  /* 3 # */
#define PC_4        0x25  /* 4 $ */
#define PC_5        0x2E  /* 5 % */
#define PC_6        0x36  /* 6 ^ */
#define PC_7        0x3D  /* 7 & */
#define PC_8        0x3E  /* 8 * */
#define PC_9        0x46  /* 9 ( */

#define PC_F1       0x05
#define PC_F2       0x06
#define PC_F3       0x04
#define PC_F4       0x0C
#define PC_F5       0x03
#define PC_F6       0x0B
#define PC_F7       0x83 | EXT  /* Caution: scan code > 0x7F */
#define PC_F8       0x0A
#define PC_F9       0x01
#define PC_F10      0x09
#define PC_F11      0x78
#define PC_F12      0x07

#define PC_ESC      0x76
#define PC_SPACE    0x29
#define PC_LCTRL    0x14
#define PC_RCTRL    0x14 | EXT
#define PC_LSHIFT   0x12
#define PC_RSHIFT   0x59
#define PC_LALT     0x11
#define PC_RALT     0x11 | EXT
#define PC_LWIN     0x1F | EXT
#define PC_RWIN     0x27 | EXT
#define PC_APPS     0x2F | EXT  /* a.k.a. MENUS */

#define PC_TAB      0x0D
#define PC_CPSLOCK  0x58
#define PC_SCRLOCK  0x7E

#define PC_INSERT   0x70 | EXT
#define PC_DELETE   0x71 | EXT
#define PC_HOME     0x6C | EXT
#define PC_END      0x69 | EXT
#define PC_PGUP     0x7D | EXT
#define PC_PGDOWN   0x7A | EXT
#define PC_BKSPACE  0x66
#define PC_ENTER    0x5A
#define PC_UP       0x75 | EXT
#define PC_DOWN     0x72 | EXT
#define PC_LEFT     0x6B | EXT
#define PC_RIGHT    0x74 | EXT

#define PC_NUMLOCK  0x77
#define PC_KP_DIVIS 0x4A | EXT
#define PC_KP_MULT  0x7C
#define PC_KP_MINUS 0x7B
#define PC_KP_PLUS  0x79
#define PC_KP_ENTER 0x5A | EXT
#define PC_KP_DOT   0x71  /* . Delete */
#define PC_KP_0     0x70  /* 0 Insert */
#define PC_KP_1     0x69  /* 1 End */
#define PC_KP_2     0x72  /* 2 DOWN ARROW */
#define PC_KP_3     0x7A  /* 3 Page Down */
#define PC_KP_4     0x6B  /* 4 LEFT ARROW */
#define PC_KP_5     0x73  /* 5 */
#define PC_KP_6     0x74  /* 6 RIGHT ARROW */
#define PC_KP_7     0x6C  /* 7 Home */
#define PC_KP_8     0x75  /* 8 UP ARROW */
#define PC_KP_9     0x7D  /* 9 Page Up */

#endif  /* !KEYS_PC_H */
