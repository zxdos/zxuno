#ifndef __DEBUG_H
#define __DEBUG_H

#include <sms.h>

#ifdef DEBUG

extern int debug_putc(char c);
extern void debug_puts(char *s);
extern void debug_print_byte(BYTE t);
extern void debug_print_word(WORD t);
extern void debug_print_dword(DWORD t);

#else

#define debug_putc(c)
#define debug_puts(s)
#define debug_print_byte(t)
#define debug_print_word(t)
#define debug_print_dword(t)

#endif

#endif // __DEBUG_H
