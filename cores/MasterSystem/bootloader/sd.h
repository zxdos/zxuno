#ifndef __SD_H
#define __SD_H

#include <sms.h>

int sd_init();
int sd_load_sector(UBYTE* target, DWORD sector);

#endif // __SD_H
