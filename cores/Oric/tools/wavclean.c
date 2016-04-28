/* wavclean tool by F.Frances */
#include <stdio.h>
#include <stdlib.h>

#define THRESHOLD 23
	/* a short period should be 18 samples at 44.1 kHz */
	/* a long one at least 27 */

struct riff {
	char sig[4];
	int riff_size;
	char datasig[4];
	char fmtsig[4];
	int fmtsize;
	short tag;
	short channels;
	int freq;
	int bytes_per_sec;
	short byte_per_sample;
	short bits_per_sample;
	char samplesig[4];
	int length;
};
struct riff sample_riff= {"RIFF",0,"WAVE","fmt ",16,1,1,4800,4800,1,8,"data",0};
struct riff header;

FILE *in, *out;
int size;

main(int argc,char **argv)
{	
	int i;
	if (argc!=3) { printf("Usage: wavclean file.wav outfile\n"); exit(1);}
	in=fopen(argv[1],"rb");
	if (in==NULL) { printf("Unable to open %s\n",argv[1]); exit(1);}
	fread(&header,sizeof(struct riff),1,in);
	if (header.channels!=1 || header.freq!=44100 || header.bits_per_sample!=8) {
		printf("Invalid WAV format: should be 44100 Hz, 8-bit, mono\n");
		exit(1);
	}

	out=fopen(argv[2],"wb");
	if (out==NULL) { printf("Unable to open %s for writing\n",argv[2]); exit(1);}
	fwrite(&sample_riff,sizeof(struct riff),1,out);
	convert();
	rewind(out);
	sample_riff.length=size;
	sample_riff.riff_size=sample_riff.length+36;
	fwrite(&sample_riff,1,sizeof(struct riff),out);
}

convert()
{
   int max=0,min=255,up=0,thres=128,last=0;
   int val,length1,length2;
   while(1) {
	length1=length2=0;
	while(1) {
		val=getc(in);
		if (val==EOF) return;
		if (val>max) max=val;
		if (val<last && up) { up=0; thres=(max+min)/2; min=255;}
		last=val;
		if (val>thres) length1++;
		else break;
	}
	while(1) {
		val=getc(in);
		if (val==EOF) return;
		if (val<min) min=val;
		if (val>last && !up) { up=1; thres=(max+min)/2; max=0; }
		last=val;
		if (val<thres) length2++;
		else break;
	}
	output_level(1);
	output_level(0);
	if (length1+length2>=THRESHOLD) output_level(0);
	if (length1+length2>10*THRESHOLD) output_silence((length1+length2)/9);
    }
}

output_level(int level)
{
	putc(level==1?0xC0:0x40,out);
	size++;
}

output_silence(int length)
{
	int i;
	for (i=0;i<length;i++) putc(0x80,out);
	size+=length;
}