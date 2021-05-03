/*
 * Png2Rcs - convert image to ZX Spectrum RCS screen.
 *
 * Copyright (C) 2014, 2015, 2021 Antonio Villena
 * Contributors:
 *   2015 David Skywalker
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
 * SPDX-FileCopyrightText: Copyright (C) 2014, 2015, 2021 Antonio Villena
 *
 * SPDX-FileContributor: 2015 David Skywalker
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

#define PROGRAM "Png2Rcs"
#define DESCRIPTION "Image to ZX Spectrum RCS screen."
#define VERSION "1.20 (31 May 2015)"
#define COPYRIGHT "Copyright (C) 2014, 2015, 2021 Antonio Villena"
#define LICENSE \
"This program is free software: you can redistribute it and/or modify\n" \
"it under the terms of the GNU General Public License as published by\n" \
"the Free Software Foundation, version 3."
#define HOMEPAGE "https://github.com/zxdos/zxuno/"

unsigned char *image, *pixel, output[0x5b00], input[0x300];
unsigned  error, width, height, i, j, k, l, m, fondo, tinta, outpos= 0,
          input1= 0, input2= 0, output1= 0, output2= 0, inverse= 0;
long long atr, celda;
FILE *fo;

int check(int value){
  return value==0 || value==192 || value==255;
}

int tospec(int r, int g, int b){
  return ((r|g|b)==255 ? 8 : 0) | g>>7<<2 | r>>7<<1 | b>>7;
}

void show_help() {
  printf(
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
    "\n"
    "Usage:\n"
    "  " PROGRAM " <input_png> <output_rcs> [output_attr] [-i] [-a input_attr]\n"
    "\n"
    "  <input_png>     256x64, 256x128 or 256x192 png file\n"
    "  <output_rcs>    ZX spectrum output in RCS format\n"
    "  <output_attr>   If specified, output attributes here\n"
    "  -i              Inverse behaviour, force darker inks\n"
    "  -a <input_attr> Force attributes specifying the file\n"
    "\n"
    "Example: " PROGRAM " loading.png loading.rcs\n"
  );
}

int main(int argc, char *argv[]){
  if( argc==1 )
    show_help(),
    exit(0);
  for ( i= 0; i<argc; i++ )
    if( argv[i][0]=='-' ){
      if( argv[i][1]=='i' )
        inverse= 1;
      else if( argv[i][1]=='a' )
        input2= ++i;
      else
        printf("Invalid option: %s\n", argv[i]),
        exit(-1);
    }
    else{
      if( input1 ){
        if( output1 ){
          if( output2 )
            printf("Invalid number of parameters\n"),
            exit(-1);
          else
            output2= i;
        }
        else
          output1= i;
      }
      else
        input1= i;
    }
  if( !output1 )
    printf("Invalid number of parameters\n"),
    exit(-1);
  error= lodepng_decode32_file(&image, &width, &height, argv[input1]);
  if( error )
    printf("Error %u: %s\n", error, lodepng_error_text(error)),
    exit(-1);
  if( width!=256 || height>192 || height&63 )
    printf("Error. Incorrect size on %s, must be 256x64, 256x128 or 256x192", argv[input1]);
  if( input2 )
    fo= fopen(argv[input2], "rb"),
    0!=fread(input, 1, 0x300, fo),
    fclose(fo);
  fo= fopen(argv[output1], "wb+");
  if( !fo )
    printf("Cannot create output file: %s\n", argv[output1]),
    exit(-1);
  for ( i= 0; i < height>>6; i++ )
    for ( j= 0; j < 32; j++ )
      for ( k= 0; k < 8; k++ ){
        celda= 0;
        pixel= &image[(i<<14 | j<<3 | k<<11)<<2];
        if( input2 )
          tinta= input[i<<8 | k<<5 | j]&7 | input[i<<8 | k<<5 | j]>>3&8,
          fondo= input[i<<8 | k<<5 | j]>>3&15;
        else
          fondo= tinta= tospec(pixel[0], pixel[1], pixel[2]);
        for ( l= 0; l < 8; l++ )
          for ( m= 0; m < 8; m++ ){
            pixel= &image[(i<<14 | j<<3 | k<<11 | l<<8 | m)<<2];
            if( !(check(pixel[0]) && check(pixel[1]) && check(pixel[2]))
              || ((char)pixel[0]*-1 | (char)pixel[1]*-1 | (char)pixel[2]*-1)==65 )
              printf("The pixel (%d, %d) has an incorrect color\n" , m|j<<3, l|k<<3|i<<6),
              exit(-1);
            if( input2 ){
              if( (tinta|8) != (tospec(pixel[0], pixel[1], pixel[2])|8)
               && (fondo|8) != (tospec(pixel[0], pixel[1], pixel[2])|8) )
                printf("The pixel (%d, %d) has a third color in the cell\n", m|j<<3, l|k<<3|i<<6),
                exit(-1);
              celda<<= 1;
              celda|= (fondo|8) != (tospec(pixel[0], pixel[1], pixel[2])|8);
            }
            else{
              if( tinta != tospec(pixel[0], pixel[1], pixel[2]) )
                if( fondo != tospec(pixel[0], pixel[1], pixel[2]) ){
                  if( tinta != fondo )
                    printf("The pixel (%d, %d) has a third color in the cell\n", m|j<<3, l|k<<3|i<<6),
                    exit(-1);
                  tinta= tospec(pixel[0], pixel[1], pixel[2]);
                }
              celda<<= 1;
              celda|= fondo != tospec(pixel[0], pixel[1], pixel[2]);
            }
          }
        if( input2 )
          atr= fondo<<3&120 | tinta&7 | tinta<<3&64;
        else if( fondo==tinta ){
          if( inverse ){
            if( tinta  )
              celda= 0,
              atr= tinta<<3&120;
            else
              celda= 0xffffffffffffffff,
              atr= 56;
          }
          else{
            if( tinta  )
              celda= 0xffffffffffffffff,
              atr= tinta&7 | tinta<<3&64;
            else
              celda= 0,
              atr= 7;
          }
        }
        else if( (fondo<tinta) ^ inverse )
          atr= fondo<<3 | tinta&7 | tinta<<3&64;
        else
          celda^= 0xffffffffffffffff,
          atr= tinta<<3 | fondo&7 | fondo<<3&64;
        for ( l= 0; l < 8; l++ )
          output[outpos++]= celda>>(56-l*8);
        output[height<<5 | i<<8 | k<<5 | j]= atr;
      }
  if( output2 ){
    fwrite(output, 1, height<<5, fo);
    fclose(fo);
    fo= fopen(argv[output2], "wb+");
    if( !fo )
      printf("Cannot create output file: %s\n", argv[output2]),
      exit(-1);
    fwrite(output+(height<<5), 1, height<<2, fo);
    printf("Files %s and %s generated from %s\n", argv[output1], argv[output2], argv[input1]);
  }
  else
    fwrite(output, 1, height*36, fo),
    printf("File %s filtered from %s\n", argv[output1], argv[input1]);
  fclose(fo);
  free(image);
}
