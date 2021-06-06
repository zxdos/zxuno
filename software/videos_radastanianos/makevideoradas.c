#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OFSBMP 0x76
#define OFSPAL 0x36

void AddFrame (FILE *fmov, FILE *fbmp)
{
	unsigned char paleta[16][4];
	unsigned char bmp[96][64];
	int i;
	unsigned char color;
	
	fseek (fbmp, OFSPAL, SEEK_SET);
	fread (paleta, 1, 64, fbmp);
	fseek (fbmp, OFSBMP, SEEK_SET);
	fread (bmp, 96, 64, fbmp);
	
	for (i=95;i>=0;i--)
	{
		fwrite (bmp[i], 1, 64, fmov);
	}
	
	for (i=0;i<16;i++)
	{
		color = (paleta[i][0]/64) | (paleta[i][1]/32)<<5 | (paleta[i][2]/32)<<2;
		fwrite (&color, 1, 1, fmov);
	}
}

int main (int argc, char *argv[])
{
	FILE *fbmp, *fmov;
	int i;
	char nfile[80];
	char *prefix;
	int paso;
	
	if (argc<2)
	{
		fprintf (stderr, "USO: makevideoradas prefijo [paso]\n\n");
		fprintf (stderr, "Donde: 'prefijo' es el comienzo del nombre de cada uno de los ficheros.\n");
		fprintf (stderr, "       'paso' es opcional e indica el incremento en frames (defecto: 1)\n");
		fprintf (stderr, "El nombre completo de cada fichero sera prefijo + codigo de 5 digitos\ncomenzando en 0 + .BMP\n\n");
		fprintf (stderr, "Ejemplo: con el prefijo 'vid' se procesaran los ficheros:\nvid00000.bmp , vid00001.bmp , vid00002.bmp , etc...\n");
		fprintf (stderr, "Si se indica un valor para paso distinto de 1, por ejemplo 2, se\nprocesaran los ficheros: vid00000.bmp , vid00002.bmp , vid00004.bmp , etc...\n");
		
		return 0;
	}

	prefix = argv[1];
	if (argc>=3)
		paso = atoi(argv[2]);
	else
		paso = 1;
		
	sprintf (nfile, "%s.rdm", prefix);
	fmov = fopen (nfile, "wb");
	i=0;
	while (1)
	{
		sprintf (nfile, "%s%05.5d.bmp", prefix, i);
		fbmp = fopen (nfile, "rb");
		if (!fbmp)
			break;
		
		fprintf (stderr, "Procesando frame %5d  \r", i);	
		AddFrame (fmov, fbmp);
		fclose (fbmp);
		i+=paso;
	}
	fclose (fmov);
	puts("");
	return 0;
}

