#include <sms.h>
#include "debug.h"

#ifdef DEBUG
int debug_putc(char c)
{
    #asm
debug_putc_wait:
	in a,($20)
	and a,1
	jr z,debug_putc_wait
    ld hl,2
    add hl,sp              ; skip over return address on stack
    ld a,(hl)
	out ($e0),a
    #endasm
}

void debug_puts(char *s)
{
	int t;
	char c;
	while (1) {
		c = *s++;
		switch (c) {
		case 0:
			return;
		case '\n':
			debug_putc('\n');
			debug_putc('\r');
			return;
		default:
			debug_putc(c);
			break;
		}
	}
}

void debug_print_digit(int t)
{
	if (t<10) {
		debug_putc('0'+t);
	} else {
		debug_putc('a'+(t-10));
	}
}

void debug_print_byte(BYTE t)
{
	debug_print_digit((t>>4)&0xf);
	debug_print_digit(t&0xf);
}

void debug_print_word(WORD t)
{
	debug_print_digit((t>>12)&0xf);
	debug_print_digit((t>>8)&0xf);
	debug_print_digit((t>>4)&0xf);
	debug_print_digit(t&0xf);
}

void debug_print_dword(DWORD t)
{
	debug_print_digit((t>>28)&0xf);
	debug_print_digit((t>>24)&0xf);
	debug_print_digit((t>>20)&0xf);
	debug_print_digit((t>>16)&0xf);
	debug_print_digit((t>>12)&0xf);
	debug_print_digit((t>>8)&0xf);
	debug_print_digit((t>>4)&0xf);
	debug_print_digit(t&0xf);
}
#endif // DEBUG
