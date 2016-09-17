#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *fi, *fo;
int i;
unsigned char mem[0x4004+0x55], checksum;
unsigned short j, k, crc, tab[]= {
0x0000, 0x2110, 0x4220, 0x6330, 0x8440, 0xa550, 0xc660, 0xe770,
0x0881, 0x2991, 0x4aa1, 0x6bb1, 0x8cc1, 0xadd1, 0xcee1, 0xeff1,
0x3112, 0x1002, 0x7332, 0x5222, 0xb552, 0x9442, 0xf772, 0xd662,
0x3993, 0x1883, 0x7bb3, 0x5aa3, 0xbdd3, 0x9cc3, 0xfff3, 0xdee3,
0x6224, 0x4334, 0x2004, 0x0114, 0xe664, 0xc774, 0xa444, 0x8554,
0x6aa5, 0x4bb5, 0x2885, 0x0995, 0xeee5, 0xcff5, 0xacc5, 0x8dd5,
0x5336, 0x7226, 0x1116, 0x3006, 0xd776, 0xf666, 0x9556, 0xb446,
0x5bb7, 0x7aa7, 0x1997, 0x3887, 0xdff7, 0xfee7, 0x9dd7, 0xbcc7,
0xc448, 0xe558, 0x8668, 0xa778, 0x4008, 0x6118, 0x0228, 0x2338,
0xccc9, 0xedd9, 0x8ee9, 0xaff9, 0x4889, 0x6999, 0x0aa9, 0x2bb9,
0xf55a, 0xd44a, 0xb77a, 0x966a, 0x711a, 0x500a, 0x333a, 0x122a,
0xfddb, 0xdccb, 0xbffb, 0x9eeb, 0x799b, 0x588b, 0x3bbb, 0x1aab,
0xa66c, 0x877c, 0xe44c, 0xc55c, 0x222c, 0x033c, 0x600c, 0x411c,
0xaeed, 0x8ffd, 0xeccd, 0xcddd, 0x2aad, 0x0bbd, 0x688d, 0x499d,
0x977e, 0xb66e, 0xd55e, 0xf44e, 0x133e, 0x322e, 0x511e, 0x700e,
0x9fff, 0xbeef, 0xdddf, 0xfccf, 0x1bbf, 0x3aaf, 0x599f, 0x788f,
0x8891, 0xa981, 0xcab1, 0xeba1, 0x0cd1, 0x2dc1, 0x4ef1, 0x6fe1,
0x8010, 0xa100, 0xc230, 0xe320, 0x0450, 0x2540, 0x4670, 0x6760,
0xb983, 0x9893, 0xfba3, 0xdab3, 0x3dc3, 0x1cd3, 0x7fe3, 0x5ef3,
0xb102, 0x9012, 0xf322, 0xd232, 0x3542, 0x1452, 0x7762, 0x5672,
0xeab5, 0xcba5, 0xa895, 0x8985, 0x6ef5, 0x4fe5, 0x2cd5, 0x0dc5,
0xe234, 0xc324, 0xa014, 0x8104, 0x6674, 0x4764, 0x2454, 0x0544,
0xdba7, 0xfab7, 0x9987, 0xb897, 0x5fe7, 0x7ef7, 0x1dc7, 0x3cd7,
0xd326, 0xf236, 0x9106, 0xb016, 0x5766, 0x7676, 0x1546, 0x3456,
0x4cd9, 0x6dc9, 0x0ef9, 0x2fe9, 0xc899, 0xe989, 0x8ab9, 0xaba9,
0x4458, 0x6548, 0x0678, 0x2768, 0xc018, 0xe108, 0x8238, 0xa328,
0x7dcb, 0x5cdb, 0x3feb, 0x1efb, 0xf98b, 0xd89b, 0xbbab, 0x9abb,
0x754a, 0x545a, 0x376a, 0x167a, 0xf10a, 0xd01a, 0xb32a, 0x923a,
0x2efd, 0x0fed, 0x6cdd, 0x4dcd, 0xaabd, 0x8bad, 0xe89d, 0xc98d,
0x267c, 0x076c, 0x645c, 0x454c, 0xa23c, 0x832c, 0xe01c, 0xc10c,
0x1fef, 0x3eff, 0x5dcf, 0x7cdf, 0x9baf, 0xbabf, 0xd98f, 0xf89f,
0x176e, 0x367e, 0x554e, 0x745e, 0x932e, 0xb23e, 0xd10e, 0xf01e};

int main(int argc, char *argv[]) {
  if( argc==1 )
    printf("\n"
    "GenRom v0.06, generates a TAP for loading a ROM in the ZX-Uno, 2016-07-04\n\n"
    "  GenRom         <params> <name> <input_file> <output_file>\n\n"
    "  <params>       Set 13 flags parameters, combinable\n"
    "     0           MODE=00, DI1FFD=DI7FFD=DITAY=DIAY=DIRADAS=DITIMEX=DIULAPLUS=0\n"
    "                 I2KB=DISCONT=DIVEN=DISNMI=DISD=ENMMU=DIROM1F=DIROM7F=0\n"
    "     i           Change Issue2\n"
    "     t           Force Timing to 128\n"
    "     p           Force Timing to Pentagon\n"
    "     c           Disable Contention\n"
    "     d           Enable DivMMC paging\n"
    "     n           Enable NMI-DivMMC\n"
    "     s           Disable SD ports (DivMMC and ZXMMC)\n"
    "     m           Enable horizontal MMU in Timex Sinclair\n"
    "     h           Disable high bit ROM (1FFD bit 2)\n"
    "     l           Disable low bit ROM (7FFD bit 4)\n"
    "     1           Disable 1FFD port (+2A/+3 memory paging)\n"
    "     7           Disable 7FFD port (128K memory paging)\n"
    "     2           Disable 2nd AY chip\n"
    "     a           Disable main AY chip\n"
    "     r           Disable Radastanian mode\n"
    "     x           Disable Timex mode\n"
    "     u           Disable Ulaplus\n"
    "  <name>         Name between single quotes up to 32 chars\n"
    "  <input_file>   Input ROM file\n"
    "  <output_file>  Output TAP file\n\n"
    "All params are mandatory\n\n"),
    exit(0);
  if( argc!=5 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[3], "rb");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[3]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  i= ftell(fi);
  if( i&0x3fff && i!=8192 )
    printf("\nInput file size must be multiple of 16384: %s\n", argv[3]),
    exit(-1);
  fo= fopen(argv[4], "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", argv[4]),
    exit(-1);
  fwrite(mem, 1, 0x55, fo);
  j= i>>14;
  mem[0]= 0x02;
  mem[1]= 0x40;
  mem[2]= 0xff;
  mem[0x4004]= 0x53;
  mem[0x4005]= 0x00;
  mem[0x4006]= 0xff;
  if( j ){
    for ( i= j; i--; ){
      fseek(fi, i<<14, SEEK_SET);
      fread(mem+3, 1, 0x4000, fi);
      for ( checksum= 0, k= 3; k<0x4003; ++k )
        checksum|= mem[k];
      if( checksum )
        break;
    }
    j= i+1;
    fseek(fi, 0, SEEK_SET);
    for ( i= 0; i<j; i++ ){
      fread(mem+3, 1, 0x4000, fi);
      crc= 0xffff;
      for ( checksum= 0xff, k= 3; k<0x4003; ++k )
        crc= tab[mem[k] ^ crc & 0xff] ^ crc>>8,
        checksum^= mem[k];
      *(unsigned short*)(mem+0x400c+(j-i)*2)= crc;
      mem[0x4003]= checksum;
      fwrite(mem, 1, 0x4004, fo);
    }
  }
  else{
    fseek(fi, 0, SEEK_SET);
    mem[1]= 0x20;
    fread(mem+3, j= 1, 0x2000, fi);
    crc= 0xffff;
    for ( checksum= 0xff, k= 3; k<0x2003; ++k )
      crc= tab[mem[k] ^ crc & 0xff] ^ crc>>8,
      checksum^= mem[k];
    *(unsigned short*)(mem+0x400e)= crc;
    mem[0x2003]= checksum;
    fwrite(mem, 1, 0x2004, fo);
  }
  fseek(fo, 0, SEEK_SET);
  mem[0x4007]= j;
  mem[0x4008]= 0b00110000;
  mem[0x4009]= 0b00000000;
  for ( i= 0; i<strlen(argv[1]); i++ )
    switch( argv[1][i] ){
      case 'i': mem[0x4008]^= 0b00100000; break;
      case 'c': mem[0x4008]^= 0b00010000; break;
      case 'd': mem[0x4008]^= 0b00001000; break;
      case 'n': mem[0x4008]^= 0b00000100; break;
      case 'p': mem[0x4008]^= 0b00000010; break;
      case 't': mem[0x4008]^= 0b00000001; break;
      case 's': mem[0x4009]^= 0b10000000; break;
      case 'm': mem[0x4009]^= 0b01000000; break;
      case 'h': mem[0x4009]^= 0b00100000; break;
      case 'l': mem[0x4009]^= 0b00010000; break;
      case '1': mem[0x4009]^= 0b00001000; break;
      case '7': mem[0x4009]^= 0b00000100; break;
      case '2': mem[0x4009]^= 0b00000010; break;
      case 'a': mem[0x4009]^= 0b00000001; break;
      case 'r': mem[0x400a]^= 0b00000100; break;
      case 'x': mem[0x400a]^= 0b00000010; break;
      case 'u': mem[0x400a]^= 0b00000001;
    }
  for ( i= 0; i<32 && i<strlen(argv[2]); i++ )
    mem[i+0x4006+0x32]= argv[2][i];
  while( ++i<33 )
    mem[i+0x4006+0x31]= ' ';
  for ( checksum= 0xff, k= 0x4007; k<0x4058; ++k )
    checksum^= mem[k];
  mem[0x4058]= checksum;
  fwrite(mem+0x4004, 1, 0x55, fo);
  printf("\nFile generated successfully\n");
}
