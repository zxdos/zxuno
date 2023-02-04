/*
 * FuenteABin - convert PNG image to a binary font file.
 *
 * Copyright (C) 2019, 2021 Antonio Villena
 * Contributors:
 *   2021 Ivan Tatarinov <ivan-tat@ya.ru>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: Copyright (C) 2019, 2021 Antonio Villena
 *
 * SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

#define PROGRAM "FuenteABin"
#define DESCRIPTION "convert PNG image to a binary font file."
#define VERSION "0.1"
#define COPYRIGHT "Copyright (C) 2016, 2021 Antonio Villena"
#define LICENSE \
"This program is free software: you can redistribute it and/or modify\n" \
"it under the terms of the GNU General Public License as published by\n" \
"the Free Software Foundation, version 3."
#define HOMEPAGE "https://github.com/zxdos/zxuno/"

#define IMAGE_WIDTH 96
#define IMAGE_HEIGHT 40
#define CHAR_WIDTH 6
#define CHAR_HEIGHT 8
#define BUF_SIZE ((IMAGE_WIDTH/CHAR_WIDTH)*(IMAGE_HEIGHT/CHAR_HEIGHT)*CHAR_HEIGHT)

unsigned char *image, *pixel, output[BUF_SIZE];
unsigned error, i, j, k, l, celda, fondo, tinta, outpos= 0;
FILE *fo;

int check(int value){
  return value==0 || value==192 || value==255;
}

unsigned tospec(unsigned r, unsigned g, unsigned b){
  return g>>7<<2 | r>>7<<1 | b>>7;
}

void show_help() {
  printf(
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
    "\n"
    "Usage:\n"
    "  " PROGRAM " <input_file> <output_file>\n"
    "\n"
    "  <input_file>   Input PNG file, %ux%u pixels in size\n"
    "  <output_file>  Output binary file\n",
    IMAGE_WIDTH,
    IMAGE_HEIGHT
  );
}

#define image_pixel_off(i, j, k, l) (((j|i<<7)*CHAR_WIDTH + k*IMAGE_WIDTH + l)<<2)

int main(int argc, char *argv[]){
  if (argc!=3){
    show_help(),
    exit(argc==1 ? 0 : -1);
  }
  error= lodepng_decode32_file(&image, &i, &j, argv[1]);
  if( error )
    printf("Error %u: %s\n", error, lodepng_error_text(error)),
    exit(-1);
  if( i!= IMAGE_WIDTH || j!= IMAGE_HEIGHT )
    printf("Error. Incorrect image size, must be %ux%u pixels\n", IMAGE_WIDTH, IMAGE_HEIGHT),
    exit(-1);
  fo= fopen(argv[2], "wb+");
  if( !fo )
    printf("Cannot create output file: %s\n", argv[2]),
    exit(-1);
  for ( i= 0; i < IMAGE_HEIGHT/CHAR_HEIGHT; i++ )
    for ( j= 0; j < IMAGE_WIDTH/CHAR_WIDTH; j++ ){
      pixel= &image[image_pixel_off(i, j, 0, 0)];
      fondo= tinta= tospec(pixel[0], pixel[1], pixel[2]);
      for ( k= 0; k < CHAR_HEIGHT; k++ ){
        celda= 0;
        for ( l= 0; l < CHAR_WIDTH; l++ ){
          pixel= &image[image_pixel_off(i, j, k, l)];
          if( !(check(pixel[0]) && check(pixel[1]) && check(pixel[2]))
            || ((char)pixel[0]*-1 | (char)pixel[1]*-1 | (char)pixel[2]*-1)==65 )
            printf("The pixel (%d, %d) has an incorrect color\n" , j*CHAR_WIDTH+l, i*CHAR_HEIGHT+k),
            exit(-1);
          if( tinta != tospec(pixel[0], pixel[1], pixel[2]) )
            if( fondo != tospec(pixel[0], pixel[1], pixel[2]) ){
              if( tinta != fondo )
                printf("The pixel (%d, %d) has a third color in the cell\n", j*CHAR_WIDTH+l, i*CHAR_HEIGHT+k),
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
  printf("File `%s' successfully created\n", argv[2]);
  free(image);
}
