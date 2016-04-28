#include "minfat.h"
#include "menu.h"

static int romindex=0;
static int romcount;

static void listroms();
static void selectrom(int row);
static void scrollroms(int row);
int (*loadfunction)(const char *filename); // Callback function

static char romfilenames[13][30];

static struct menu_entry rommenu[]=
{
	{MENU_ENTRY_CALLBACK,romfilenames[0],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[1],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[2],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[3],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[4],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[5],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[6],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[7],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[8],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[9],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[10],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[11],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_CALLBACK,romfilenames[12],MENU_ACTION(&selectrom)},
	{MENU_ENTRY_SUBMENU,"Back",MENU_ACTION(0)},
	{MENU_ENTRY_NULL,0,MENU_ACTION(scrollroms)}
};


static void copyname(char *dst,const unsigned char *src,int l)
{
	int i;
	for(i=0;i<l;++i)
		*dst++=*src++;
	*dst++=0;
}


static DIRENTRY *nthfile(int n)
{
	int i,j=0;
	DIRENTRY *p;
	for(i=0;(j<=n) && (i<dir_entries);++i)
	{
		p=NextDirEntry(i);
		if(p)
			++j;
	}
	return(p);
}


static void selectrom(int row)
{
	DIRENTRY *p=nthfile(romindex+row);
	if(p)
	{
		copyname(longfilename,p->Name,11);	// Make use of the long filename buffer to store a temporary copy of the filename,
											// since loading it by name will overwrite the sector buffer which currently contains it!
		if(loadfunction)
			(*loadfunction)(longfilename);
	}
}


static void selectdir(int row)
{
	DIRENTRY *p=nthfile(romindex+row);
	if(p)
		ChangeDirectory(p);
	romindex=0;
	listroms();
	Menu_Draw();
}


static void scrollroms(int row)
{
	switch(row)
	{
		case ROW_LINEUP:
			if(romindex)
				--romindex;
			break;
		case ROW_PAGEUP:
			romindex-=16;
			if(romindex<0)
				romindex=0;
			break;
		case ROW_LINEDOWN:
			++romindex;
			break;
		case ROW_PAGEDOWN:
			romindex+=16;
			break;
	}
	listroms();
	Menu_Draw();
}


static void listroms()
{
	int i,j;
	j=0;
	for(i=0;(j<romindex) && (i<dir_entries);++i)
	{
		DIRENTRY *p=NextDirEntry(i);
		if(p)
			++j;
	}

	for(j=0;(j<12) && (i<dir_entries);++i)
	{
		DIRENTRY *p=NextDirEntry(i);
		if(p)
		{
			// FIXME declare a global long file name buffer.
			if(p->Attributes&ATTR_DIRECTORY)
			{
				rommenu[j].action=MENU_ACTION(&selectdir);
				romfilenames[j][0]=16; // Right arrow
				romfilenames[j][1]=' ';
				if(longfilename[0])
					copyname(romfilenames[j++]+2,longfilename,28);
				else
					copyname(romfilenames[j++]+2,p->Name,11);
			}
			else
			{
				rommenu[j].action=MENU_ACTION(&selectrom);
				if(longfilename[0])
					copyname(romfilenames[j++],longfilename,28);
				else
					copyname(romfilenames[j++],p->Name,11);
			}
		}
		else
			romfilenames[j][0]=0;
	}
	for(;j<12;++j)
		romfilenames[j][0]=0;
}


void FileSelector_Show(int row)
{
	romindex=0;
	listroms();
	rommenu[13].action=MENU_ACTION(Menu_Get()); // Set parent menu entry
	Menu_Set(rommenu);
}


void FileSelector_SetLoadFunction(int (*func)(const char *filename))
{
	loadfunction=func;
}

