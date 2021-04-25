/*
 * rcs - SCR filter to RCS (and inverse).
 *
 * Copyright (C) 2013, 2021 Antonio Villena
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
 * SPDX-FileCopyrightText: Copyright (C) 2013, 2021 Antonio Villena
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include <stdio.h>
#include <stdlib.h>

#define PROGRAM "rcs"
#define DESCRIPTION "SCR filter to RCS (and inverse)."
#define VERSION "1.03 (18 Jan 2013)"
#define COPYRIGHT "Copyright (C) 2013, 2021 Antonio Villena"
#define LICENSE \
"This program is free software: you can redistribute it and/or modify\n" \
"it under the terms of the GNU General Public License as published by\n" \
"the Free Software Foundation, version 3."
#define HOMEPAGE "https://github.com/zxdos/zxuno/"

void show_help() {
  printf(
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
    "\n"
    "Usage:\n"
    "  " PROGRAM " [-i] <input_file> <output_file>\n"
    "\n"
    "  -i             Inverse filter (RCS to SCR), optional\n"
    "  <input_file>   Input file to filter\n"
    "  <output_file>  Generated output file\n"
    "\n"
    "All parameters are mandatory except `-i'.\n"
  );
}

int scr2rcs( int i ){ return i&0x1800 | i<<8&0x700 | i<<2&0xe0 | i>>6&0x1f;  }
int rcs2scr( int i ){ return i&0x1800 | i>>8&7     | i>>2&0x38 | i<<6&0x7c0; }
int main(int argc, char* argv[]){
  unsigned char *mem= (unsigned char *) malloc (0x1b00);
  int tmp, last, j, k;
  FILE *fi, *fo;
  if( argc==1 )
    show_help(),
    exit(0);
  int (*func)(int)= &scr2rcs;
  if( argv[1][0] == '-' )
    func= &rcs2scr, argv++, argc--;
  if( argc!=3 )
    printf("Invalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[1], "rb");
  if( !fi )
    printf("Input file not found: %s\n", argv[1]),
    exit(-1);
  fo= fopen(argv[2], "wb+");
  if( !fo )
    printf("Cannot create output file: %s\n", argv[2]),
    exit(-1);
  fread(mem, 1, 0x1b01, fi);
  if( ftell(fi) != 0x1b00 )
    printf("Input file size must be 6912 bytes\n"),
    exit(-1);
  for ( int i= 0; i<0x1800; i++ ){
    k= j= i;
    do
      last= j,
      j= func(j),
      k<j && (k= j, j= i);
    while( j != i );
    if( k==i ){
      tmp= mem[j];
      do
        k= func(j),
        mem[j]= mem[k],
        j= k;
      while( j != i );
      mem[last]= tmp;
    }
  }
  fwrite(mem, 1, 0x1b00, fo);
  printf("File `%s' successfully created\n",argv[2]);
}
