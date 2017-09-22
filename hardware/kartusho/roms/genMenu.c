#include <stdio.h>
#include <stdlib.h>

unsigned char image[0xc000], font[0x1000];
char tmpstr[50];
unsigned short i, j, k, pos;
FILE *fh;

int main(int argc, char *argv[]){
  fh= fopen("fuente6x8.bin", "r");
  fread(font+0x80, 1, 0x380, fh);
  fclose(fh);
  for ( i= 0x400; i<0x1000; i++ )
    font[i]= (font[i-0x400] >> 2) | (font[i-0x400] << 6);
  fh= fopen("menu.txt", "r");
  for ( i= 0; i<17; i++ ){
    fgets(tmpstr, 50, fh);
    k= 0;
    pos= i<<5&0xf0 | i<<8&0x1800;
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
  fclose(fh);
  fh= fopen("screen.scr", "wb+");
  memset(image+0x1800, 0x38, 0x300);
  fwrite(image, 1, 0x1b00, fh);
  fclose(fh);
}
