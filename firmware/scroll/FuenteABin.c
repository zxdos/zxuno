#include "lodepng.c"
#include <stdio.h>
#include <stdlib.h>
unsigned char *image, *pixel, output[0x300];
unsigned error, i, j, k, l, celda, fondo, tinta, outpos= 0;
FILE *fo;

int check(int value){
  return value==0 || value==192 || value==255;
}

int tospec(int r, int g, int b){
  return g>>7<<2 | r>>7<<1 | b>>7;
}

int main(int argc, char *argv[]){
  error= lodepng_decode32_file(&image, &i, &j, "fuente6x8.png");
  if( error )
    printf("\nError %u: %s\n", error, lodepng_error_text(error)),
    exit(-1);
  if( i!= 96 || j!= 48 )
    printf("\nError. Incorrect size, must be 96x48\n"),
    exit(-1);
  fo= fopen("fuente6x8.bin", "wb+");
  if( !fo )
    printf("\nCannot create output file\n"),
    exit(-1);
  for ( i= 0; i < 6; i++ )
    for ( j= 0; j < 16; j++ ){
      pixel= &image[((j|i<<7)*6)<<2];
      fondo= tinta= tospec(pixel[0], pixel[1], pixel[2]);
      for ( k= 0; k < 8; k++ ){
        celda= 0;
        for ( l= 0; l < 6; l++ ){
          pixel= &image[((j|i<<7)*6 + k*96 + l)<<2];
          if( !(check(pixel[0]) && check(pixel[1]) && check(pixel[2]))
            || ((char)pixel[0]*-1 | (char)pixel[1]*-1 | (char)pixel[2]*-1)==65 )
            printf("\nThe pixel (%d, %d) has an incorrect color\n" , j*6+l, i*8+k),
            exit(-1);
          if( tinta != tospec(pixel[0], pixel[1], pixel[2]) )
            if( fondo != tospec(pixel[0], pixel[1], pixel[2]) ){
              if( tinta != fondo )
                printf("\nThe pixel (%d, %d) has a third color in the cell\n", j*6+l, i*8+k),
                exit(-1);
              tinta= tospec(pixel[0], pixel[1], pixel[2]);
            }
          celda<<= 1;
          celda|= fondo != tospec(pixel[0], pixel[1], pixel[2]);
        }
        output[outpos++]= celda<<2;
      }
    }
  fwrite(output, outpos, 1, fo);
  fclose(fo);
  printf("\nDone\n");
  free(image);
}
