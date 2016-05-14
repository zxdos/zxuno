#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *fi, *fo;
int i;
unsigned char mem[0x4004+0x55], checksum, a, b;
unsigned short j, k, crc, tab[]= {
  0x0000, 0x1189, 0x2312, 0x329b, 0x4624, 0x57ad, 0x6536, 0x74bf,
  0x8c48, 0x9dc1, 0xaf5a, 0xbed3, 0xca6c, 0xdbe5, 0xe97e, 0xf8f7,
  0x1081, 0x0108, 0x3393, 0x221a, 0x56a5, 0x472c, 0x75b7, 0x643e,
  0x9cc9, 0x8d40, 0xbfdb, 0xae52, 0xdaed, 0xcb64, 0xf9ff, 0xe876,
  0x2102, 0x308b, 0x0210, 0x1399, 0x6726, 0x76af, 0x4434, 0x55bd,
  0xad4a, 0xbcc3, 0x8e58, 0x9fd1, 0xeb6e, 0xfae7, 0xc87c, 0xd9f5,
  0x3183, 0x200a, 0x1291, 0x0318, 0x77a7, 0x662e, 0x54b5, 0x453c,
  0xbdcb, 0xac42, 0x9ed9, 0x8f50, 0xfbef, 0xea66, 0xd8fd, 0xc974,
  0x4204, 0x538d, 0x6116, 0x709f, 0x0420, 0x15a9, 0x2732, 0x36bb,
  0xce4c, 0xdfc5, 0xed5e, 0xfcd7, 0x8868, 0x99e1, 0xab7a, 0xbaf3,
  0x5285, 0x430c, 0x7197, 0x601e, 0x14a1, 0x0528, 0x37b3, 0x263a,
  0xdecd, 0xcf44, 0xfddf, 0xec56, 0x98e9, 0x8960, 0xbbfb, 0xaa72,
  0x6306, 0x728f, 0x4014, 0x519d, 0x2522, 0x34ab, 0x0630, 0x17b9,
  0xef4e, 0xfec7, 0xcc5c, 0xddd5, 0xa96a, 0xb8e3, 0x8a78, 0x9bf1,
  0x7387, 0x620e, 0x5095, 0x411c, 0x35a3, 0x242a, 0x16b1, 0x0738,
  0xffcf, 0xee46, 0xdcdd, 0xcd54, 0xb9eb, 0xa862, 0x9af9, 0x8b70,
  0x8408, 0x9581, 0xa71a, 0xb693, 0xc22c, 0xd3a5, 0xe13e, 0xf0b7,
  0x0840, 0x19c9, 0x2b52, 0x3adb, 0x4e64, 0x5fed, 0x6d76, 0x7cff,
  0x9489, 0x8500, 0xb79b, 0xa612, 0xd2ad, 0xc324, 0xf1bf, 0xe036,
  0x18c1, 0x0948, 0x3bd3, 0x2a5a, 0x5ee5, 0x4f6c, 0x7df7, 0x6c7e,
  0xa50a, 0xb483, 0x8618, 0x9791, 0xe32e, 0xf2a7, 0xc03c, 0xd1b5,
  0x2942, 0x38cb, 0x0a50, 0x1bd9, 0x6f66, 0x7eef, 0x4c74, 0x5dfd,
  0xb58b, 0xa402, 0x9699, 0x8710, 0xf3af, 0xe226, 0xd0bd, 0xc134,
  0x39c3, 0x284a, 0x1ad1, 0x0b58, 0x7fe7, 0x6e6e, 0x5cf5, 0x4d7c,
  0xc60c, 0xd785, 0xe51e, 0xf497, 0x8028, 0x91a1, 0xa33a, 0xb2b3,
  0x4a44, 0x5bcd, 0x6956, 0x78df, 0x0c60, 0x1de9, 0x2f72, 0x3efb,
  0xd68d, 0xc704, 0xf59f, 0xe416, 0x90a9, 0x8120, 0xb3bb, 0xa232,
  0x5ac5, 0x4b4c, 0x79d7, 0x685e, 0x1ce1, 0x0d68, 0x3ff3, 0x2e7a,
  0xe70e, 0xf687, 0xc41c, 0xd595, 0xa12a, 0xb0a3, 0x8238, 0x93b1,
  0x6b46, 0x7acf, 0x4854, 0x59dd, 0x2d62, 0x3ceb, 0x0e70, 0x1ff9,
  0xf78f, 0xe606, 0xd49d, 0xc514, 0xb1ab, 0xa022, 0x92b9, 0x8330,
  0x7bc7, 0x6a4e, 0x58d5, 0x495c, 0x3de3, 0x2c6a, 0x1ef1, 0x0f78
};

int main(int argc, char *argv[]) {
  if( argc==1 )
    printf("\n"
    "GenRom v0.05, generates a TAP for loading a ROM in the ZX-Uno, 2016-05-14\n\n"
    "  GenRom         <params1> <params2> <name> <input_file> <output_file>\n\n"
    "  <params1>      Set 5 flags parameters, combinable\n"
    "     0           Default values Issue3, Tim48K, Contended, Disabled Div & NMI\n"
    "     i           Change Issue2\n"
    "     t           Force Timing to 128\n"
    "     p           Force Timing to Pentagon\n"
    "     c           Disable Contention\n"
    "     d           Enable DivMMC paging\n"
    "     n           Enable NMI-DivMMC\n"
    "  <params2>      Set 8 flags parameters, combinable\n"
    "     0           Default values DISD, DIFUL, DIKEMP, ENMMU, DI1FFD, DI7FFD,"
    "                                                             DITAY and DIAY\n"
    "     s           Disable SD ports (DivMMC and ZXMMC)\n"
    "     m           Enable horizontal MMU in Timex Sinclair\n"
    "     h           Disable high bit ROM (1FFD bit 2)\n"
    "     l           Disable low bit ROM (7FFD bit 4)\n"
    "     1           Disable 1FFD port (+2A/+3 memory paging)\n"
    "     7           Disable 7FFD port (128K memory paging)\n"
    "     t           Disable second AY chip\n"
    "     a           Disable main AY chip\n"
    "  <name>         Name between single quotes up to 32 chars\n"
    "  <input_file>   Input ROM file\n"
    "  <output_file>  Output TAP file\n\n"
    "All params are mandatory\n\n"),
    exit(0);
  if( argc!=6 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[4], "rb");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[4]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  i= ftell(fi);
  if( i&0x3fff && i!=8192 )
    printf("\nInput file size must be multiple of 16384: %s\n", argv[4]),
    exit(-1);
  fo= fopen(argv[5], "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", argv[5]),
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
      crc= 0x4c2b;
      for ( checksum= 0xff, k= 3; k<0x4003; ++k )
        a= mem[k],
        b= a ^ crc,
        crc= tab[b] ^ (crc>>8&0xff ),
        checksum^= a;
      *(unsigned short*)(mem+0x400c+(j-i)*2)= crc;
      mem[0x4003]= checksum;
      fwrite(mem, 1, 0x4004, fo);
    }
  }
  else{
    fseek(fi, 0, SEEK_SET);
    mem[1]= 0x20;
    fread(mem+3, j= 1, 0x2000, fi);
    crc= 0x4c2b;
    for ( checksum= 0xff, k= 3; k<0x2003; ++k )
      a= mem[k],
      b= a ^ crc,
      crc= tab[b] ^ (crc>>8&0xff ),
      checksum^= a;
    *(unsigned short*)(mem+0x400e)= crc;
    mem[0x2003]= checksum;
    fwrite(mem, 1, 0x2004, fo);
  }
  fseek(fo, 0, SEEK_SET);
  mem[0x4007]= j;
  mem[0x4008]= 0b00110000;
  for ( i= 0; i<strlen(argv[1]); i++ )
    switch( argv[1][i] ){
      case 'i': mem[0x4008]^= 0b00100000; break;
      case 'c': mem[0x4008]^= 0b00010000; break;
      case 'd': mem[0x4008]^= 0b00001000; break;
      case 'n': mem[0x4008]^= 0b00000100; break;
      case 'p': mem[0x4008]^= 0b00000010; break;
      case 't': mem[0x4008]^= 0b00000001;
    }
  mem[0x4009]= 0b00000000;
  for ( i= 0; i<strlen(argv[2]); i++ )
    switch( argv[2][i] ){
      case 's': mem[0x4009]^= 0b10000000; break;
      case 'm': mem[0x4009]^= 0b01000000; break;
      case 'h': mem[0x4009]^= 0b00100000; break;
      case 'l': mem[0x4009]^= 0b00010000; break;
      case '1': mem[0x4009]^= 0b00001000; break;
      case '7': mem[0x4009]^= 0b00000100; break;
      case 't': mem[0x4009]^= 0b00000010; break;
      case 'a': mem[0x4009]^= 0b00000001;
    }
  for ( i= 0; i<32 && i<strlen(argv[3]); i++ )
    mem[i+0x4006+0x32]= argv[3][i];
  while( ++i<33 )
    mem[i+0x4006+0x31]= ' ';
  for ( checksum= 0xff, k= 0x4007; k<0x4058; ++k )
    checksum^= mem[k];
  mem[0x4058]= checksum;
  fwrite(mem+0x4004, 1, 0x55, fo);
  printf("\nFile generated successfully\n");
}
