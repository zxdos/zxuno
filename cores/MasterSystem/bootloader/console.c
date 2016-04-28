#include <sms.h>
#include "console.h"

int vdp_set_address(int a)
{
	#asm
	ld	hl, 2
	add	hl, sp
	ld	a, (hl)
	out	($bf), a
	inc	hl
	ld	a, (hl)
	out	($bf), a
	#endasm
}

int vdp_write(char a)
{
	#asm
	ld	hl, 2
	add	hl, sp
	ld	a, (hl)
	out	($be), a
	#endasm
}
typedef struct _console {
	int pos;
	char style;
} console_t;

console_t *console = 0xc000;

int console_init()
{
	console_gotoxy(0,0);
	//console->pos = 0x3800;
	console->style = 0;
}

int console_putc(char c)
{
    #asm
    ld hl,2
    add hl,sp              ; skip over return address on stack
    ld a,(hl)
	out ($be),a
	ld a,$00
	out ($be),a    
    #endasm
	console->pos += 2;
}

int console_clear()
{
    #asm
	ld	a,$00
	out ($bf),a
	ld	a,$38
	out ($bf),a

	xor	a
	ld	l,$7
.console_clear_loop1
	ld	b,$00
.console_clear_loop2
	out	($be),a
	djnz	console_clear_loop2
	dec	l
	jr	nz, console_clear_loop1
    #endasm
	console_gotoxy(0,0);
}

void console_gotoxy(int x,int y)
{
	int t = y;
	t += t;
	t += t;
	t += t;
	t += t;
	t += t;
	t += x;
	t += t;
	t += 0x3800;
	console->pos = t;
	vdp_set_address(t);
}

void console_puts(char *s)
{
	int t;
	char c;
	vdp_set_address(console->pos);
	while (1) {
		c = *s++;
		switch (c) {
		case 0:
			return;
		case '\n':
			t = (console->pos & 0x3fc0) + 0x40;
			console->pos = t;
			vdp_set_address(t);
			break;
		default:
			console_putc(c);
			break;
		}
	}
}

void console_print_digit(int t)
{
	if (t<10) {
		console_putc('0'+t);
	} else {
		console_putc('a'+(t-10));
	}
}

void console_print_byte(BYTE t)
{
	console_print_digit((t>>4)&0xf);
	console_print_digit(t&0xf);
}

void console_print_word(WORD t)
{
	console_print_digit((t>>12)&0xf);
	console_print_digit((t>>8)&0xf);
	console_print_digit((t>>4)&0xf);
	console_print_digit(t&0xf);
}

void console_print_dword(DWORD t)
{
	console_print_digit((t>>28)&0xf);
	console_print_digit((t>>24)&0xf);
	console_print_digit((t>>20)&0xf);
	console_print_digit((t>>16)&0xf);
	console_print_digit((t>>12)&0xf);
	console_print_digit((t>>8)&0xf);
	console_print_digit((t>>4)&0xf);
	console_print_digit(t&0xf);
}

