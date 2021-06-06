#include <stdio.h>
#include <stdlib.h>
#include <mem.h>

#define BW
//#define COLOR

int main ()
{
	char header[256];
	FILE *fi, *fo;
	char name[100];
	char *frame;
	int fr = 1;
	
	memcpy (header,"ZXM",3);
#ifdef COLOR
	header[18] = 14;
#endif
#ifdef BW
	header[18] = 12;
#endif
	frame = malloc(6912);
	fo = fopen ("badapple.zxm", "wb");
	fwrite (header, 1, 256, fo);
	memset (header, 0, 256);
	
	while(1)
	{
		sprintf (name, "%09.9d.scr", fr++);
		fi = fopen (name, "rb");
		if (!fi)
			break;
#ifdef COLOR
		fread (frame, 1, 6912, fi);
		fwrite (header, 1, 256, fo);
		fwrite (frame, 1, 6912, fo);
#endif		
#ifdef BW
		fread (frame, 1, 6144, fi);
		fwrite (frame, 1, 6144, fo);
#endif		
		printf ("%s\n", name);
		fclose (fi);
	}
	fclose (fo);
	free(frame);
}
	
