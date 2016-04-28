/* wav2tap tool by F.Frances */
#include <stdio.h>
#include <stdlib.h>

struct {
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
} sample_riff;

int sync_ok=0;
int offset,pos;
FILE *in, *out;

main(int argc,char **argv)
{	
	unsigned start,end,byte;
	if (argc!=3) { printf("Usage: %s file.wav file.tap\n",argv[0]); exit(1);}
	in=fopen(argv[1],"rb");
	if (in==NULL) { printf("Unable to open WAV file\n"); exit(1);}
	fread(&sample_riff,sizeof(sample_riff),1,in);
	if (sample_riff.channels!=1 || sample_riff.freq!=4800 || sample_riff.byte_per_sample!=1) {
		printf("Invalid WAV format: should be 4800 Hz, 8-bit, mono\n");
		exit(1);
	}

	out=fopen(argv[2],"wb");
	if (out==NULL) { printf("Unable to create TAP file\n"); exit(1);}

	for (;;) {
		synchronize();
		printf("Synchro found, decoding bytes...\n");
		putc(0x16,out); putc(0x16,out); putc(0x16,out);
		sync_ok=1;
		offset+=3;
		byte=0x24;
		while (sync_ok) {
			putc(byte,out);
			offset++;
			byte=getbyte();
		}
	}
}

getbit()
{
	int val,length=1;
	val=getc(in); pos++;
	if (val==EOF) exit(0);
	while (val>=0x80) {
		length++;
		val=getc(in); pos++;
		if (val==EOF) exit(0);
	}
	length++;
	val=getc(in); pos++;
	if (val==EOF) exit(0);
	while (val<=0x80) {
		length++;
		val=getc(in); pos++;
		if (val==EOF) exit(0);
	}
	if (length>10) return -1;
	else if (length>2) return 0;
	else return 1;
}

getbyte()
{
	int decaleur=0,byte=0,i,bit,sum=0;
	getbit();
	while((bit=getbit())==1);
	if (bit==-1) { sync_ok=0; return 0; }
	for(i=0;i<8;i++) decaleur=(decaleur<<1)|getbit();
	for(i=0;i<8;i++) {
		bit=decaleur&1;
		decaleur=decaleur>>1;
		byte=(byte<<1)|bit;
		sum+=bit;
	}
	if (((sum&1)==getbit()) && sync_ok) printf("parity error at offset $%x\n",offset);
	return byte;
}

synchronize()
{
	int decaleur=0,val;
	printf("Searching synchro...\n");
	while(1) {
		while((decaleur&0xff) != 0x68)
                        decaleur=(decaleur<<1)|getbit();
		if (getbyte()!=0x16) continue;
		if (getbyte()!=0x16) continue;
		if (getbyte()!=0x16) continue;
		do {
			val=getbyte();
		} while (val==0x16);
		if (val==0x24) break;
	}
}

