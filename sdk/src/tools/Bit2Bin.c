/*
 * Bit2Bin - strip .bit header and align binary to 16K.
 *
 * Copyright (C) 2019-2023 Antonio Villena
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
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROGRAM "Bit2Bin"
#define DESCRIPTION "strip .bit header and align binary to 16K."
#define VERSION "0.06 (2023-07-26)"
#define COPYRIGHT "Copyright (C) 2019-2023 Antonio Villena"
#define LICENSE \
"This program is free software: you can redistribute it and/or modify\n" \
"it under the terms of the GNU General Public License as published by\n" \
"the Free Software Foundation, version 3."
#define HOMEPAGE "https://github.com/zxdos/zxuno/"

FILE *fi, *fo;
int i, length;
unsigned char mem[0x4000];
unsigned short j;

void show_help() {
  printf(
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
    "\n"
    "Usage:\n"
    "  " PROGRAM "        <input_file> <output_file>\n"
    "\n"
    "  <input_file>   Input BIT file\n"
    "  <output_file>  Output BIN file\n"
    "\n"
    "All parameters are mandatory.\n"
  );
}

int main(int argc, char *argv[]) {
  if( argc==1 )
    show_help(),
    exit(0);
  if( argc!=3 )
    printf("Invalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[1], "rb");
  if( !fi )
    printf("Input file not found: %s\n", argv[1]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  i= ftell(fi);
  fseek(fi, 0, SEEK_SET);
  fread(mem, 1, 2, fi);
  i-= (j= mem[1]|mem[0]<<8)+4;
  fread(mem, 1, j+2, fi);
  i-= (j= mem[j+1]|mem[j]<<8)+3;
  fread(mem, 1, j+3, fi);
  i-= (j= mem[j+1]|mem[j]<<8)+3;
  fread(mem, 1, j+3, fi);
  i-= (j= mem[j+1]|mem[j]<<8)+3;
  fread(mem, 1, j+3, fi);
  i-= (j= mem[j+1]|mem[j]<<8)+3;
  fread(mem, 1, j+3, fi);
  i-= (j= mem[j+1]|mem[j]<<8)+4;
  fread(mem, 1, j+4, fi);
  length= mem[j+3]|mem[j+2]<<8|mem[j+1]<<16|mem[j]<<24;
  if( i!=length )
    printf("Invalid file length\n"),
    exit(-1);
  fo= fopen(argv[2], "wb+");
  if( !fo )
    printf("Cannot create output file: %s\n", argv[2]),
    exit(-1);
  j= i>>14;
  if( j )
    for ( i= 0; i<j; i++ )
      fread(mem, 1, 0x4000, fi),
      fwrite(mem, 1, 0x4000, fo);
  memset(mem, 0, 0x4000);
  fread(mem, 1, length&0x3fff, fi),
  fwrite(mem, 1, 0x4000, fo);
  if( j<71 ){
    memset(mem, 0, 0x4000);
    if( j>48 )  // ZX3
      for ( i= 0; i<71-j; i++ )
        fwrite(mem, 1, 0x4000, fo);
    else if( j>28 )  // ZXD
      for ( i= 0; i<48-j; i++ )
        fwrite(mem, 1, 0x4000, fo);
    else if( j>20 )  // ZX2
      for ( i= 0; i<28-j; i++ )
        fwrite(mem, 1, 0x4000, fo);
    else  // ZX1
      for ( i= 0; i<20-j; i++ )
        fwrite(mem, 1, 0x4000, fo);
  }
  printf("File `%s' successfully created\n", argv[2]);
}
