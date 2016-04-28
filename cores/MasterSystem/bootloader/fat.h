#ifndef __FAT_H
#define __FAT_H

#include <sms.h>

typedef struct {
	BYTE type;		// first byte : directories are 0x01, files are 0x11
	char name[11];
	DWORD cluster;
} file_descr_t;

typedef struct {
	DWORD cluster;
	DWORD sector;
} file_t;

extern int fat_init();
extern file_descr_t* fat_open_root_directory();
extern file_descr_t* fat_open_directory(DWORD first_cluster);

#define FAT_EOF	0xffff

extern int fat_open_file(file_t *file, DWORD cluster);
extern int fat_load_file_sector(file_t *file, UBYTE *buffer);

#endif // __FAT_H



