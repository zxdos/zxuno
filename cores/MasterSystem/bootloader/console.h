#ifndef __CONSOLE_H
#define __CONSOLE_H

#include <sms.h>

extern int	vdp_set_address(int a);
extern int	vdp_write(char a);

extern int	console_init();
extern int	console_clear();
extern int	console_putc(char c);
extern void	console_gotoxy(int x,int y);

extern void	console_puts(char *s);
extern void	console_print_byte(BYTE s);
extern void	console_print_word(WORD s);
extern void	console_print_dword(DWORD s);

#endif // __CONSOLE_H

