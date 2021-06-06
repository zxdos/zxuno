/*

Utilidad de conversión de ficheros S-Record de Motorola, creados con SDCC, a TAP de Spectrum
(C)2007-2008 Miguel Angel Rodriguez Jodar (McLeod/IdeaFix). Dept. Arquitectura y Tecnología de Computadores. Universidad de Sevilla. rodriguj@atc.us.es
Licencia: GPL
Se puede compilar con cualquier compilador para Windows/UNIX (gcc, mingw32, etc...)

Uso:
s19tozx -i archivo.s19 -o archivo.tap

El archivo S19 se habrá generado con SDCC, que debe haberse usado con los siguientes parámetros:

sdcc -mz80 --opt-code-speed --nostdlib --nostdinc --no-std-crt0 --out-fmt-s19 --code-loc XXXX --data-loc 0 fichero1.c fichero2.c ...

Donde XXXX es la dirección de memoria donde comenzará nuestro código.
*/

#include <stdio.h>

#define hextodec(x) ((x)<='9'?(x)-'0':(x)-'A'+10)
#define D(x) if (verbose) x

typedef struct
{
  unsigned int address;
  unsigned int lbytes;
  unsigned char bytes[65536];
} Tbloque;

Tbloque ElBloque;
int verbose=0;

void SalvarBloqueTAP (FILE *fs, unsigned short int address, unsigned short int lbytes, unsigned char *bytes)
{
  unsigned char cabecera[19];
  unsigned short int dummy;
  int i;
  unsigned char chk;
  
  cabecera[0]=0;  // Flag 0 para indicar cabecera estándar
  cabecera[1]=3;  // Bytes:
  sprintf(cabecera+2,"datos-%4.4X",address);
  cabecera[12]=lbytes&0xFF;
  cabecera[13]=(lbytes>>8)&0xFF;
  cabecera[14]=address&0xFF;
  cabecera[15]=(address>>8)&0xFF;
  cabecera[16]=0;
  cabecera[17]=0x80;
  cabecera[18]=0;
  
  for (i=0;i<=17;i++)
    cabecera[18]^=cabecera[i];
    
  dummy=19;
  fwrite(&dummy,1,2,fs);
  fwrite(cabecera,1,19,fs);
  
  dummy=lbytes+2;
  fwrite(&dummy,1,2,fs);
  fputc(0xFF,fs);  // FF para indicar datos
  fwrite(bytes,1,lbytes,fs);
  
  chk=0xFF;
  for (i=0;i<lbytes;i++)
    chk^=bytes[i];
  fputc(chk,fs);
}

void SalvarLoaderTAP (FILE *fs, unsigned short int address)
{
/* Este cargador corresponde a: (32 columnas por linea)

  10 CLEAR 0: LOAD ""CODE : PRIN
T AT 11,0;" Pulsa una tecla para
 ejecutar  ": PAUSE 0: RANDOMIZE
 USR 0

*/
	unsigned char loader[]={19,0,0,0,108,111,97,100,101,114,32,32,32,32,91,0,1,
	                        0,91,0,16,93,0,255,0,10,87,0,253,48,14,0,0,0,0,0,58,
				239,34,34,175,58,245,172,49,49,14,0,0,11,0,0,44,48,
				14,0,0,0,0,0,59,34,32,80,117,108,115,97,32,117,110,
				97,32,116,101,99,108,97,32,112,97,114,97,32,101,106,
				101,99,117,116,97,114,32,32,34,58,242,48,14,0,0,0,0,0,
				58,249,192,48,14,0,0,0,0,0,13,0};

	int offpdata=23;
	int offclear=33;
	int offrand=111;
	int i,chks;

    if (address>=25000)
    {
      loader[offclear]=(address-1)&0xFF;
	  loader[offclear+1]=((address-1)>>8)&0xFF;
    }

    loader[offrand]=address&0xFF;
	loader[offrand+1]=(address>>8)&0xFF;

    for (chks=0,i=offpdata;i<115;i++)
      chks^=loader[i];
    loader[i]=chks;

    fwrite (loader, 1, 116, fs);
}

int main (int argc, char *argv[])
{
  char *fsalida=NULL;
  char *fentrada=NULL;
  char *opc;
  char linea[10001];
  int llinea,indact;
  unsigned char dato;
  unsigned short int dir;
  int i,p;
  FILE *fe, *fs;
  
  for (i=1;i<argc;i++)
  {
    opc=argv[i];
    if (opc[0]=='-' && opc[1]=='o')
    {
      fsalida=argv[i+1];
      i++;
    }
    else if (opc[0]=='-' && opc[1]=='i')
    {
      fentrada=argv[i+1];
      i++;
    }
    else if (opc[0]=='-' && opc[1]=='v')
      verbose=1;
  }
  
  if (!fentrada)
    fe=stdin;
  else
    fe=fopen(fentrada,"rt");
    
  if (!fsalida)
    fs=stdout;
  else
    fs=fopen(fsalida,"wb");
    
  if (!fs || !fe)
  {
    printf ("No se pudo abrir alguno de los ficheros especificados\n");
    return 1;
  }
    
  fgets (linea, 10000, fe);
  indact=0;
  ElBloque.lbytes=0;
  
  while (!feof(fe))
  {
    if (linea[0]!='S')
      continue;
    if (linea[1]=='9')
      break;
    if (linea[1]!='1')
      continue;

    D(printf("%s\n",linea));
      
    llinea=((hextodec(linea[2])<<4) | hextodec(linea[3])) - 3;
    dir=(hextodec(linea[4])<<12) | 
        (hextodec(linea[5])<<8) | 
        (hextodec(linea[6])<<4) |
        (hextodec(linea[7]));

    if (indact==0)
      ElBloque.address=dir;
      
    if (dir!=ElBloque.address+ElBloque.lbytes)
    {
   	   SalvarLoaderTAP(fs,ElBloque.address);
       SalvarBloqueTAP(fs,ElBloque.address,ElBloque.lbytes,ElBloque.bytes);
       indact=0;
       ElBloque.address=dir;
       ElBloque.lbytes=0;
    }

    D(printf("dir: %4.4X  indact: %d  llinea: %d\n",dir,indact,llinea));
    
    for (i=0,p=8;i<llinea;i++,p+=2)
    {
      dato=(hextodec(linea[p])<<4) | hextodec(linea[p+1]);
      ElBloque.bytes[indact++]=dato;
      ElBloque.lbytes++;
    }
    
    fgets (linea,10000,fe);
  }
  
  if (indact)
  {
    SalvarLoaderTAP(fs,ElBloque.address);  	
    SalvarBloqueTAP(fs,ElBloque.address,ElBloque.lbytes,ElBloque.bytes);
  }
  return 0;
}

