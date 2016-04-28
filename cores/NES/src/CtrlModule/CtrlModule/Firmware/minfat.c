/*
Copyright 2005, 2006, 2007 Dennis van Weeren
Copyright 2008, 2009 Jakub Bednarski

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

This is a simple FAT16 handler. It works on a sector basis to allow fastest acces on disk
images.

11-12-2005 - first version, ported from FAT1618.C

JB:
2008-10-11  - added SeekFile() and cluster_mask
            - limited file create and write support added
2009-05-01  - modified LoadDirectory() and GetDirEntry() to support sub-directories (with limitation of 511 files/subdirs per directory)
            - added GetFATLink() function
            - code cleanup
2009-05-03  - modified sorting algorithm in LoadDirectory() to display sub-directories above files
2009-08-23  - modified ScanDirectory() to support page scrolling and parent dir selection
2009-11-22  - modified FileSeek()
            - added FileReadEx()
2009-12-15  - all entries are now sorted by name with extension
            - directory short names are displayed with extensions

2012-07-24  - Major changes to fit the MiniSOC project - AMR
*/

// #include <stdio.h>
#include <string.h>
//#include <ctype.h>

#include "spi.h"

#include "minfat.h"
#include "swap.h"
#include "osd.h"

// Stubs to replace standard C library functions
#define puts OSD_Puts
#define tolower(x) (x|32)


static unsigned int directory_cluster;       // first cluster of directory (0 if root)
static unsigned int entries_per_cluster;     // number of directory entries per cluster

// internal global variables
static unsigned int fat32;                // volume format is FAT32
static unsigned long fat_start;                // start LBA of first FAT table
static unsigned long data_start;               // start LBA of data field
static unsigned long root_directory_cluster;   // root directory cluster (used in FAT32)
static unsigned long root_directory_start;     // start LBA of directory table
static unsigned long root_directory_size;      // size of directory region in sectors
static unsigned int fat_number;               // number of FAT tables
unsigned int cluster_size;             // size of a cluster in sectors
unsigned long cluster_mask;             // binary mask of cluster number
static unsigned long fat_size;                 // size of fat

static unsigned int current_directory_cluster;
static unsigned int current_directory_start;

static int partitioncount;

unsigned int dir_entries;             // number of entry's in directory table

unsigned char sector_buffer[512];       // sector buffer

#ifndef DISABLE_LONG_FILENAMES
char longfilename[260];
#endif

#define fat_buffer (*(FATBUFFER*)&sector_buffer) // Don't need a separate buffer for this.


static int compare(const char *s1, const char *s2,int b)
{
	int i;
	for(i=0;i<b;++i)
	{
		if(*s1++!=*s2++)
			return(1);
	}
	return(0);
}


// FindDrive() checks if a card is present and contains FAT formatted primary partition
int FindDrive(void)
{
	unsigned long boot_sector;              // partition boot sector
	fat32=0;
	int i;
	
	i=5;
	i=5;
	while(--i>0)
	{
		if(sd_init())
		{
		    if(sd_read_sector(0, sector_buffer)) // read MBR
				i=-1;
		}
	}
	if(!i)	// Did we escape the loop?
	{
		OSD_Puts("Card init failed\n");
		return(0);
	}

	boot_sector=0;
	partitioncount=1;

	// If we can identify a filesystem on block 0 we don't look for partitions
    if (compare((const char*)&sector_buffer[0x36], "FAT16   ",8)==0) // check for FAT16
		partitioncount=0;
    if (compare((const char*)&sector_buffer[0x52], "FAT32   ",8)==0) // check for FAT32
		partitioncount=0;

//	printf("%d partitions found\n",partitioncount);

	if(partitioncount)
	{
		// We have at least one partition, parse the MBR.
		struct MasterBootRecord *mbr=(struct MasterBootRecord *)sector_buffer;

		boot_sector = mbr->Partition[0].startlba;
		if(mbr->Signature==0x55aa)
				boot_sector=SwapBBBB(mbr->Partition[0].startlba);
		else if(mbr->Signature!=0xaa55)
		{
			puts("No partition sig\n");
			return(0);
		}
//		printf("Reading boot sector %d\n",boot_sector);
		if (!sd_read_sector(boot_sector, sector_buffer)) // read discriptor
		    return(0);
//		hexdump(sector_buffer,512);
//		puts("Read boot sector from first partition\n");
	}

    if (compare(sector_buffer+0x52, "FAT32   ",8)==0) // check for FAT16
		fat32=1;
	else if (compare(sector_buffer+0x36, "FAT16   ",8)!=0) // check for FAT32
	{
        puts("Bad part\n");
		return(0);
	}

    if (sector_buffer[510] != 0x55 || sector_buffer[511] != 0xaa)  // check signature
        return(0);

    // check for near-jump or short-jump opcode
    if (sector_buffer[0] != 0xe9 && sector_buffer[0] != 0xeb)
        return(0);

    // check if blocksize is really 512 bytes
    if (sector_buffer[11] != 0x00 || sector_buffer[12] != 0x02)
        return(0);

    // get cluster_size
    cluster_size = sector_buffer[13];

    // calculate cluster mask
    cluster_mask = cluster_size - 1;

    fat_start = boot_sector + sector_buffer[0x0E] + (sector_buffer[0x0F] << 8); // reserved sector count before FAT table (usually 32 for FAT32)
	fat_number = sector_buffer[0x10];

    if (fat32)
    {
        if (compare((const char*)&sector_buffer[0x52], "FAT32   ",8) != 0) // check file system type
            return(0);

        dir_entries = cluster_size << 4; // total number of dir entries (16 entries per sector)
        root_directory_size = cluster_size; // root directory size in sectors
        fat_size = sector_buffer[0x24] + (sector_buffer[0x25] << 8) + (sector_buffer[0x26] << 16) + (sector_buffer[0x27] << 24);
        data_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = sector_buffer[0x2C] + (sector_buffer[0x2D] << 8) + (sector_buffer[0x2E] << 16) + ((sector_buffer[0x2F] & 0x0F) << 24);
        root_directory_start = (root_directory_cluster - 2) * cluster_size + data_start;
    }
    else
    {
        // calculate drive's parameters from bootsector, first up is size of directory
        dir_entries = sector_buffer[17] + (sector_buffer[18] << 8);
        root_directory_size = ((dir_entries << 5) + 511) >> 9;

        // calculate start of FAT,size of FAT and number of FAT's
        fat_size = sector_buffer[22] + (sector_buffer[23] << 8);

        // calculate start of directory
        root_directory_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = 0; // unused

        // calculate start of data
        data_start = root_directory_start + root_directory_size;
    }
	ChangeDirectory(0);
    return(1);
}


int GetCluster(int cluster)
{
	int i;
	int sb;
	if (fat32)
	{
		sb = cluster >> 7; // calculate sector number containing FAT-link
		i = cluster & 0x7F; // calculate link offsset within sector
	}
	else
	{
		sb = cluster >> 8; // calculate sector number containing FAT-link
		i = cluster & 0xFF; // calculate link offsset within sector
	}

    if (!sd_read_sector(fat_start + sb, (unsigned char*)&fat_buffer))
		return(0);
    i = fat32 ? SwapBBBB(fat_buffer.fat32[i]) & 0x0FFFFFFF : SwapBB(fat_buffer.fat16[i]); // get FAT link, big-endian
	return(i);
}


DIRENTRY *NextDirEntry(int prev)
{
    unsigned long  iDirectory = 0;       // only root directory is supported
    DIRENTRY      *pEntry = NULL;        // pointer to current entry in sector buffer
    unsigned long  iDirectorySector;     // current sector of directory entries table
    unsigned long  iEntry;               // entry index in directory cluster or FAT16 root directory
	static int prevlfn=0;

	// FIXME traverse clusters if necessary

    iDirectorySector = current_directory_start+(prev>>4);

	if ((prev & 0x0F) == 0) // first entry in sector, load the sector
	{
		sd_read_sector(iDirectorySector, sector_buffer); // root directory is linear
	}
	pEntry = (DIRENTRY*)sector_buffer;
	pEntry+=(prev&0xf);
	if (pEntry->Name[0] != SLOT_EMPTY && pEntry->Name[0] != SLOT_DELETED) // valid entry??
	{
		if (!(pEntry->Attributes & ATTR_VOLUME)) // not a volume
		{
			if(!prevlfn)
				longfilename[0]=0;
			prevlfn=0;
			// FIXME - should check the lfn checksum here.
			return(pEntry);
		}
#ifndef DISABLE_LONG_FILENAMES
		else if (pEntry->Attributes == ATTR_LFN)	// Do we have a long filename entry?
		{
			unsigned char *p=&pEntry->Name[0];
			int seq=p[0];
			int offset=((seq&0x1f)-1)*13;
			char *o=&longfilename[offset];
			*o++=p[1];
			*o++=p[3];
			*o++=p[5];
			*o++=p[7];
			*o++=p[9];

			*o++=p[0xe];
			*o++=p[0x10];
			*o++=p[0x12];
			*o++=p[0x14];
			*o++=p[0x16];
			*o++=p[0x18];

			*o++=p[0x1c];
			*o++=p[0x1e];
			prevlfn=1;
		}
#endif
	}
	return((DIRENTRY *)0);
}


int FileOpen(fileTYPE *file, const char *name)
{
    DIRENTRY      *pEntry = NULL;        // pointer to current entry in sector buffer
    unsigned long  iDirectorySector;     // current sector of directory entries table
    unsigned long  iDirectoryCluster;    // start cluster of subdirectory or FAT32 root directory
    unsigned long  iEntry;               // entry index in directory cluster or FAT16 root directory

    iDirectoryCluster = current_directory_cluster;
    iDirectorySector = current_directory_start;

    while (1)
    {
        for (iEntry = 0; iEntry < dir_entries; iEntry++)
        {
            if ((iEntry & 0x0F) == 0) // first entry in sector, load the sector
            {
                sd_read_sector(iDirectorySector++, sector_buffer); // root directory is linear
                pEntry = (DIRENTRY*)sector_buffer;
            }
            else
                pEntry++;


            if (pEntry->Name[0] != SLOT_EMPTY && pEntry->Name[0] != SLOT_DELETED) // valid entry??
            {
                if (!(pEntry->Attributes & (ATTR_VOLUME | ATTR_DIRECTORY))) // not a volume nor directory
                {
                    if (compare((const char*)pEntry->Name, name,11) == 0)
                    {
                        file->size = SwapBBBB(pEntry->FileSize); 		// for 68000
                        file->cluster = SwapBB(pEntry->StartCluster);
						file->cluster += (fat32 ? (SwapBB(pEntry->HighCluster) & 0x0FFF) << 16 : 0);
                        file->sector = 0;

                        return(1);
                    }
                }
            }
        }

        if (fat32) // subdirectory is a linked cluster chain
        {
            iDirectoryCluster = GetCluster(iDirectoryCluster); // get next cluster in chain
            if ((iDirectoryCluster & 0x0FFFFFF8) == 0x0FFFFFF8) // check if end of cluster chain
                 break; // no more clusters in chain

            iDirectorySector = data_start + cluster_size * (iDirectoryCluster - 2); // calculate first sector address of the new cluster
        }
        else
            break;

    }
    return(0);
}


int FileNextSector(fileTYPE *file)
{
    unsigned long sb;
    unsigned int i;

    // increment sector index
    file->sector++;

    // cluster's boundary crossed?
    if ((file->sector&cluster_mask) == 0)
		file->cluster=GetCluster(file->cluster);

    return(1);
}


int FileRead(fileTYPE *file, unsigned char *pBuffer)
{
    unsigned long sb;

    sb = data_start;                         // start of data in partition
    sb += cluster_size * (file->cluster-2);  // cluster offset
    sb += file->sector & cluster_mask;      // sector offset in cluster

	return(sd_read_sector(sb, pBuffer)); // read sector from drive
}


#ifndef DISABLE_WRITE
int FileWrite(fileTYPE *file, unsigned char *pBuffer)
{
    unsigned long sb;

    sb = data_start;                         // start of data in partition
    sb += cluster_size * (file->cluster-2);  // cluster offset
    sb += file->sector & cluster_mask;      // sector offset in cluster

	return(sd_write_sector(sb, pBuffer)); // read sector from drive
}
#endif


void ChangeDirectory(DIRENTRY *p)
{
	if(p)
	{
		current_directory_cluster = SwapBB(p->StartCluster);
		current_directory_cluster |= fat32 ? (SwapBB(p->HighCluster) & 0x0FFF) << 16 : 0;
	}
	if(current_directory_cluster)
	{	
	    current_directory_start = data_start + cluster_size * (current_directory_cluster - 2);
		dir_entries = cluster_size << 4;
	}
	else
	{
		current_directory_cluster = root_directory_cluster;
		current_directory_start = root_directory_start;
		dir_entries = fat32 ?  cluster_size << 4 : root_directory_size << 4; // 16 entries per sector
	}
}


int IsFat32()
{
	return(fat32);
}


