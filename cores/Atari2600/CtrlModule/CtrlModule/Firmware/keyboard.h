#ifndef KEYBOARD_H
#define KEYBOARD_H

#define KEY_EXT 0xe0
#define KEY_KEYUP 0xf0

#define KEY_F1  0x5
#define KEY_F2 	0x6
#define KEY_F3 	0x4
#define KEY_F4 	0x0C 
#define KEY_F5 	0x3
#define KEY_F6 	0x0B 
#define KEY_F7 	0x83
#define KEY_F8 	0x0A 
#define KEY_F9 	0x1
#define KEY_F10 0x9
#define KEY_F11 0x78
#define KEY_F12 0x7

#define KEY_CAPSLOCK 0x58
#define KEY_NUMLOCK 0x77
#define KEY_SCROLLLOCK 0x7e
#define KEY_LEFTARROW 0xeb
#define KEY_RIGHTARROW 0xf4
#define KEY_UPARROW 0xf5
#define KEY_DOWNARROW 0xf2
#define KEY_ENTER 0x5a
#define KEY_PAGEUP 0xfd
#define KEY_PAGEDOWN 0xfa
#define KEY_SPACE 0x29
#define KEY_ESC 0x76

#define KEY_P 0x4d
#define KEY_T 0x2c

#define KEY_A 0x1c
#define KEY_D 0x23
#define KEY_W 0x1d
#define KEY_S 0x1b
#define KEY_LSHIFT 0x12
#define KEY_RSHIFT 0x59
#define KEY_LCTRL 0x14
#define KEY_RCTRL 0x94
#define KEY_ALT	0x11
#define KEY_ALTGR 0x91


int HandlePS2RawCodes();
void ClearKeyboard();

int TestKey(int rawcode);

// Each keytable entry has two bits: bit 0 - currently pressed, bit 1 - pressed since last test
extern unsigned int keytable[16];

#endif

