#include "fat.h"

#define DEBUG_FAT2

typedef struct {
	BYTE	fat32;
	BYTE	sectors_per_cluster;
	DWORD	first_fat_sector;
	DWORD	first_data_sector;
	DWORD	current_data_sector;
	DWORD	current_fat_sector;
	DWORD	root_directory;
	WORD	root_directory_size;
} fat_t;

const fat_t *fat 					= 0xc010;
const UBYTE *fat_buffer				= 0xc100;
const UBYTE *data_buffer			= 0xc300;
const file_descr_t *directory_buffer= 0xc500;

void fat_init32();
void fat_init16();

DWORD load_dword(UBYTE *ptr)
{
	return (ptr[0])
		 | (ptr[1]<<8)
		 | (ptr[2]<<16)
		 | (ptr[3]<<24);
}

WORD load_word(UBYTE *ptr)
{
	return (ptr[0])
		 | (ptr[1]<<8);
}

int fat_init()
{
	DWORD sector;

	sector = 0;
	if (!sd_load_sector(data_buffer, sector)) {
		console_puts("Error loading MBR\n");
		return FALSE;
	}

	if ((data_buffer[0x1fe]!=0x55) || (data_buffer[0x1ff]!=0xaa)) {
		console_puts("Wrong MBR\n");
		return FALSE;
	}
	switch (data_buffer[0x1c2]) {
	case 0x06:
	case 0x04:
		fat->fat32 = FALSE;
		break;
	case 0x0b:
	case 0x0c:	
		fat->fat32 = TRUE;
		break;
	default:
		console_puts("Unsupported FileSystem (FAT16/32 only)\n");
		return FALSE;
	}

	sector = load_dword(&data_buffer[0x1c6]); 
#ifdef DEBUG_FAT
	debug_puts("first sector: ");
	debug_print_dword(sector);
	debug_puts("\n");
#endif


	if (!sd_load_sector(data_buffer, sector)) {
		console_puts("Error while loading boot sector\n");
		return FALSE;
	}

	if ((data_buffer[0x1fe]!=0x55) || (data_buffer[0x1ff]!=0xaa)) {
		console_puts("Wrong boot record\n");
		return FALSE;
	}

	if ((data_buffer[11]!=0) || (data_buffer[12]!=2)) {
		console_puts("sector size != 0x200\n");
		console_print_byte(data_buffer[11]);
		console_print_byte(data_buffer[12]);
		return FALSE;
	}

	fat->sectors_per_cluster = data_buffer[13];

	// reserved sectors
	fat->first_fat_sector = sector + load_word(&data_buffer[14]);

	if (fat->fat32) {
		fat_init32();
	} else {
		fat_init16();
	}

#ifdef DEBUG_FAT
	debug_puts("sectors_per_cluster: ");
	debug_print_byte(fat->sectors_per_cluster);
	debug_puts("\n");
	debug_puts("first_fat_sector: ");
	debug_print_dword(fat->first_fat_sector);
	debug_puts("\n");
	debug_puts("first_data_sector: ");
	debug_print_dword(fat->first_data_sector);
	debug_puts("\n");
	debug_puts("root_directory: ");
	debug_print_dword(fat->root_directory);
	debug_puts("\n");
#endif

	return TRUE;
}

void fat_init32()
{
	UBYTE nb_fats;
	DWORD fat_size;

	nb_fats = data_buffer[0x10];
	fat_size= load_dword(&data_buffer[0x24]);
#ifdef DEBUG_FAT
	debug_puts("fat_size: ");
	debug_print_dword(fat_size);
	debug_puts("\n");
#endif

	fat->first_data_sector = fat->first_fat_sector;
	for (; nb_fats>0; --nb_fats) {
		fat->first_data_sector += fat_size;
	}
	fat->root_directory = load_dword(&data_buffer[0x2c]);
}

void fat_init16()
{
	UBYTE nb_fats;
	WORD fat_size;

	// root directory first sector
	nb_fats = data_buffer[0x10];
	fat_size = load_word(&data_buffer[22]);
	fat->root_directory = fat->first_fat_sector;
	for (; nb_fats>0; --nb_fats) {
		fat->root_directory += fat_size;
	}

	// root directory size (in sectors)
	fat->root_directory_size = load_word(&data_buffer[17])>>4;

	// first data sector = first sector after root directory
	fat->first_data_sector = fat->root_directory + fat->root_directory_size;
}

int load_fat_sector(DWORD sector)
{
	sector += fat->first_fat_sector;
	if (fat->current_fat_sector==sector) {
		return TRUE;
	}

	if (sd_load_sector(fat_buffer, sector)) {
		fat->current_fat_sector = sector;
		return TRUE;
	}
	return FALSE;
}

int load_data_sector(UBYTE *buffer, DWORD sector)
{
	return sd_load_sector(buffer, sector);
}

DWORD first_sector_of_cluster(DWORD cluster)
{
/*#ifdef DEBUG
		debug_puts("cluster ");
		debug_print_dword(cluster);
		debug_puts(" => ");
		debug_print_dword(fat->first_data_sector + (cluster-2)*fat->sectors_per_cluster);
		debug_puts("\n");
#endif*/
	return fat->first_data_sector + (cluster-2)*fat->sectors_per_cluster;
}

DWORD fat_next_cluster(DWORD current)
{
	DWORD fat_sector;

	fat_sector = (fat->fat32) ? (current>>7) : (current>>8);
	if (!load_fat_sector(fat_sector)) {
		return 0;
	}

	if (fat->fat32) {
		return load_dword(&fat_buffer[(current & 0x7f) << 2]);
	} else {
		return load_word(&fat_buffer[(current & 0xff) << 1]);
	}
}

int fat_is_last_cluster(DWORD cluster)
{
	if (fat->fat32) {
		return ((cluster&0xfffffff8)==0xfffffff8);
	} else {
		return ((cluster&0xfff8)==0xfff8);
	}
}

int fat_open_file(file_t *file, DWORD cluster)
{
	file->cluster = cluster;
	file->sector  = first_sector_of_cluster(cluster);
	return TRUE;
}

int fat_load_file_sector(file_t *file, UBYTE *buffer)
{
	int i;
	if (file->sector==first_sector_of_cluster(file->cluster+1)) {
		file->cluster = fat_next_cluster(file->cluster);
#ifdef DEBUG2
		debug_puts("end of cluster -- next cluster is ");
		debug_print_dword(file->cluster);
		debug_puts("\n");
#endif
		if (fat_is_last_cluster(file->cluster)) {
#ifdef DEBUG2
			debug_puts("end of file\n");
#endif
			return FAT_EOF;
		} else {
#ifdef DEBUG2
			debug_puts("continuing\n");
#endif
			file->sector  = first_sector_of_cluster(file->cluster);
		}
	}
	return sd_load_sector(buffer, file->sector++);
}

void clear_directory_buffer()
{
	int i;
	for (i=0; i<0x100; i++) {
		directory_buffer[i].type = 0;
	}
}

int fat_process_directory_entry(file_descr_t *file_descr, UBYTE* data)
{
	UBYTE i;

	if ((*data) == 0xe5) {		// deleted
		return FALSE;
	} 
	if ((data[11]&13) != 0) {	// fancy attributes
		return FALSE;
	}

	// first byte : directories are 0x01", files are 0x11
	file_descr->type = ((data[11]&0x10)^0x10) | 0x01;

	// copy file name (11 bytes)
	for(i=0; i<11; i++) {
		file_descr->name[i] = *data++;
	}

	// copy cluster # (4 bytes)
	file_descr->cluster = load_word(&data[15]);
	if (fat->fat32) {
		file_descr->cluster |= ((DWORD)load_word(&data[9]))<<16;
	}

	return TRUE;
}
int process_directory_sector(file_descr_t** directory_ptr,UBYTE* buffer_ptr)
{
	UBYTE i;
	for (i=0x10; i>0; --i) {
		if ((*buffer_ptr) == 0) {
			(*directory_ptr)->type = 0; // marks last entry
			return TRUE;
		}
		if (fat_process_directory_entry(*directory_ptr, buffer_ptr)) {
			(*directory_ptr)++;
		}
		buffer_ptr += 0x20;
	}
	return FALSE;
}

file_descr_t* fat_open_root_directory16()
{
	DWORD sector;
	file_descr_t* directory_ptr;
	UBYTE* buffer_ptr;
	UBYTE i;

	clear_directory_buffer();

	sector = fat->root_directory;
	directory_ptr = directory_buffer;
	for (i=fat->root_directory_size; i>0; --i) {
		if (!sd_load_sector(data_buffer, sector)) {
			console_puts("error while reading\n");
			return 0;
		}
		if (process_directory_sector(&directory_ptr,data_buffer)) {
			goto fat_open_root_directory16;
		}
		sector++;
	}

fat_open_root_directory16:
	(*directory_ptr)->type = 0; // marks last entry
	return directory_buffer;
}

file_descr_t* fat_open_directory(DWORD first_cluster)
{
	DWORD cluster;
	DWORD sector;
	file_descr_t* directory_ptr;

	if (!fat->fat32) {
		if (first_cluster==0) {
#ifdef DEBUG_FAT
			debug_puts("opening root dir\n");
#endif
			return fat_open_root_directory16();
		}
	}

	clear_directory_buffer();

	cluster = first_cluster;
	directory_ptr = directory_buffer;
	do {
		UBYTE i;
		sector = first_sector_of_cluster(cluster);
		for(i=8; i>0; --i) {
			if (!sd_load_sector(data_buffer, sector)) {
				return 0;
			}
			if (process_directory_sector(&directory_ptr,data_buffer)) {
				goto fat_open_directory_end;
			}
			sector++;
		}
		cluster = fat_next_cluster(cluster);
		if (cluster==0) {
			return 0;
		}
	} while (!fat_is_last_cluster(cluster));

fat_open_directory_end:
	(*directory_ptr)->type = 0; // marks last entry
	return directory_buffer;
}

file_descr_t* fat_open_root_directory()
{
	if (fat->fat32) {
		return fat_open_directory(fat->root_directory);
	} else {
		return fat_open_root_directory16();
	}
}

