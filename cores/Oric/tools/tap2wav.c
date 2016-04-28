/* tap2wav tool by F.Frances*/
#include <stdio.h>
#include <stdlib.h>

FILE *in,*out;
int file_size;
int speed=4800;

struct {
	char sig[4];
	int riff_size;
	char typesig[4];
	char fmtsig[4];
	int fmtsize;
	short tag;
	short channels;
	int freq;
	int bytes_per_sec;
	short byte_per_sample;
	short bits_per_sample;
	char samplesig[4];
	int datalength;
} sample_riff= { "RIFF",0,"WAVE","fmt ",16,1,1,0,0,1,8,"data",0 };

void emit_level(int size)
{
    static int current_level=0xC0;
    int i;
    current_level=256-current_level;
    for (i=0;i<size;i++) fputc(current_level,out);
    file_size+=size;
}


void emit_bit(int bit)
{
    switch (speed) {
      case 4800:
        emit_level(1);
        if (bit) emit_level(1);
        else emit_level(2);
        break;
      case 8000:
        if (bit) {
          emit_level(1);
          emit_level(2);
        } else {
          emit_level(2);
          emit_level(3);
        }
        break;
      case 11025:
        if (bit) {
          emit_level(2);
          emit_level(2);
        } else {
          emit_level(3);
          emit_level(4);
        }
        break;
    }
}

void emit_byte(int val)
{
  int i,parity=1;
  emit_bit(0);
  for (i=0; i<8; i++,val>>=1) {
    parity+=val&1;
    emit_bit(val&1);
  }
  emit_bit(parity&1);
  emit_bit(1);
  emit_bit(1);
  emit_bit(1);
  emit_bit(1);  /* 4 bits stop au lieu de 3.5 pour être sûr que les routines aient du temps */
}

void emit_gap()
{
  int i;
  /* un paquet de bits stop pour laisser le temps d'afficher la ligne de statut */
  for (i=0;i<100;i++) emit_bit(1); 
}

init(int argc, char *argv[])
{
  if (argc<3) return 1;
  if (argv[1][0]=='-') {
    if (strcmp(argv[1],"-8")==0) speed=8000;
    else if (strcmp(argv[1],"-11")==0) speed=11025;
    else { 
      printf("Bad option\n\n");
      return 1;
    }
  }
  sample_riff.freq=sample_riff.bytes_per_sec=speed;
  in=fopen(argv[argc-2],"rb");
  if (in==NULL) {
    printf("Cannot open %s file\n\n",argv[1]);
    return 1;
  }
  out=fopen(argv[argc-1],"wb");
  if (out==NULL) {
    printf("Cannot create %s file\n\n",argv[2]);
    return 1;
  }
  return 0;
}

main(int argc,char *argv[])
{
  int i,size;
  unsigned char header[9];

  if (init(argc,argv)) {
    printf("Usage: %s [ -8 | -11 ] <.TAP file> <.WAV file>\n",argv[0]);
    printf("Options: -8  produces a  8 kHz WAV file\n");
    printf("         -11 produces a 11 kHz WAV file  (default is 4800 Hz)\n");
    exit(1);
  }

  fwrite(&sample_riff,1,sizeof(sample_riff),out);

  while (!feof(in)) {
    while (fgetc(in)==0x16) ; /* read synchro (0x24 included) */
    if (feof(in)) break;
    for (i=0;i<256;i++) emit_byte(0x16);
    emit_byte(0x24);

    for (i=0;i<9;i++) emit_byte(header[i]=fgetc(in));  /* header */

    do {
      i=fgetc(in); emit_byte(i);   /* name */
    } while (i!=0);

    emit_gap();

    size=(header[4]*256+header[5])-(header[6]*256+header[7])+1;
    for (i=0;i<size;i++) emit_byte(fgetc(in));
  }
  fclose(in);

  sample_riff.datalength=file_size;
  sample_riff.riff_size=sample_riff.datalength+8+sample_riff.fmtsize+12;
  fseek(out,0,SEEK_SET); 
  fwrite(&sample_riff,1,sizeof(sample_riff),out);

  fclose(out);
}
