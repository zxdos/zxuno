#include <stdio.h>
#include <stdlib.h>

unsigned char image[0xc000], font[0x1000];
char tmpstr[50];
unsigned short i, j, k, af, pos, lreg, loff;
FILE *fi, *fo, *ft;

int main(int argc, char *argv[]){
  if( argv[1][0]=='1' )
    lreg= 61,
    loff= 32;
  else
    lreg= 35,
    loff= 8;
  ft= fopen("fuente6x8.bin", "r");
  fread(font+0x80, 1, 0x380, ft);
  for ( i= 0x400; i<0x1000; i++ )
    font[i]= (font[i-0x400] >> 2) | (font[i-0x400] << 6);
  fi= fopen("menu.txt", "r");
  for ( i= 0; i<12; i++ ){
    fgets(tmpstr, 50, fi);
    k= 0;
    pos= i<<5&0xf0 | i<<8&0x800;
    while ( 1 ){
      for ( j= 0; j<8; j++, pos+= 0x100 )
        image[pos]= font[j|tmpstr[k]<<3];
      pos-= 0x800;
      if( tmpstr[++k]<14 )
        break;
      for ( j= 0; j<8; j++, pos+= 0x100 )
        image[pos]= image[pos]&0xfc | font[0xc00|j|tmpstr[k]<<3]&0x3,
        image[pos+1]= font[0xc00|j|tmpstr[k]<<3]&0xfc;
      pos-= 0x7ff;
      if( tmpstr[++k]<14 )
        break;
      for ( j= 0; j<8; j++, pos+= 0x100 )
        image[pos]= image[pos]&0xf0 | font[0x800|j|tmpstr[k]<<3]&0xf,
        image[pos+1]= font[0x800|j|tmpstr[k]<<3]&0xf0;
      pos-= 0x7ff;
      if( tmpstr[++k]<14 )
        break;
      for ( j= 0; j<8; j++, pos+= 0x100 )
        image[pos]= image[pos] | font[0x400|j|tmpstr[k]<<3];
      pos-= 0x7ff;
      if( tmpstr[++k]<14 )
        break;
    }
  }
  fo= fopen("screen.scr", "wb+");
  memset(image+0x1800, 0x38, 0x300);
  fwrite(image, 1, 0x1b00, fo);
  fclose(fi);
  fclose(fo);
  memset(font, 0, lreg*10);
  fo= fopen("rest.bin", "wb+");
  for ( i= 0; i<10; i++ ){
    sprintf(tmpstr, "game%d.sna", i);
    fi= fopen(tmpstr, "rb");
    fread(font+lreg*10, 1, 0x1b, fi);
    fread(image, 1, 0xc000, fi);
    pos= *(unsigned short*)(font+lreg*10+23);         // SP
    af= *(unsigned short*)(font+lreg*10+21);          // AF
    if( loff==8 )
      pos-= 2,
      *(unsigned short*)(image+pos-0x4000)= af,
      fwrite(image, 1, 0xc000, fo);
    else
      fwrite(image, 1, 0x4000, fo),
      fwrite(image+0x3ffc, 1, 0x4000, fo),
      fwrite(image+0x7ff8, 1, 0x4000, fo);
    memcpy(font+i*lreg, image+0xc000-loff, loff);
    font[i*lreg+loff]= font[lreg*10];                 // I
    font[i*lreg+loff+1]= font[lreg*10+25]-1;          // IM
    memcpy(font+i*lreg+loff+2, font+lreg*10+1, 8);    // HL',DE',BC',AF'
    memcpy(font+i*lreg+loff+10, font+lreg*10+11, 8);  // DE,BC,IY,IX
    *(unsigned short*)(font+i*lreg+loff+18)= af;
    font[i*lreg+loff+18+(loff>>3&2)]= 0x21;                       // HL
    *(unsigned short*)(font+i*lreg+loff+19+(loff>>3&2))= *(unsigned short*)(font+lreg*10+9);
    font[i*lreg+loff+21+(loff>>3&2)]= 0x31;                       // SP
    *(unsigned short*)(font+i*lreg+loff+22+(loff>>3&2))= pos;
    font[i*lreg+loff+24+(loff>>3&2)]= 0xf3|font[lreg*10+19]<<1&8; // IFF
    font[i*lreg+loff+25+(loff>>3&2)]= 0x18;                       // jr rel
    font[i*lreg+loff+26+(loff>>3&2)]= i<9 ? lreg-2 : 0;
    fclose(fi);
  }
  fclose(fo);
  fo= fopen("regs.bin", "wb+");
  fwrite(font, 1, lreg*10, fo);
  fclose(fo);
}
