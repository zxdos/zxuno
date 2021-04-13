/*
 * fcut - a file hexadecimal cutter.
 *
 * Copyright (C) 2015, 2021 Antonio Villena
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
 * SPDX-FileCopyrightText: Copyright (C) 2015, 2021 Antonio Villena
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include <stdio.h>
#include <stdlib.h>

#define PROGRAM "fcut"
#define DESCRIPTION "a file hexadecimal cutter."
#define VERSION "1.00 (20 Jun 2015)"
#define COPYRIGHT "Copyright (C) 2015, 2021 Antonio Villena"
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
    "  " PROGRAM " <input_file> <start> <length> <output_file>\n"
    "\n"
    "  <input_file>   Origin file to cut\n"
    "  <start>        In hexadecimal, is the start offset of the segment\n"
    "  <length>       In hexadecimal, is the length of the segment\n"
    "  <output_file>  Genetated output file\n"
    "\n"
    "<start> negative value assumes a negative offset from the end of the file.\n"
    "<length> negative value will substract file size result to that parameter.\n"
  );
}

int main(int argc, char* argv[]){
  unsigned char *mem= (unsigned char *) malloc (0x10000);
  FILE *fi, *fo;
  long start, length, size;
  if( argc==1 )
    show_help(),
    exit(0);
  if( argc!=5 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[1], "rb");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[1]),
    exit(-1);
  fo= fopen(argv[4], "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", argv[4]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  size= ftell(fi);
  rewind(fi);
  start= strtol(argv[2], NULL, 16);
  if( start<0 )
    start+= size;
  length= strtol(argv[3], NULL, 16);
  if( length<0 )
    length+= size;
  if( start+length>size
   || start>size )
    printf("\nOut of input file\n"),
    exit(-1);
  fseek(fi, start, SEEK_SET);
  for ( size= 0; size<length>>16; size++ )
    fread(mem, 1, 0x10000, fi),
    fwrite(mem, 1, 0x10000, fo);
  fread(mem, 1, length&0xffff, fi);
  fwrite(mem, 1, length&0xffff, fo);
  fclose(fi);
  fclose(fo);
  printf("\n0x%lx bytes written (%lu) at offset 0x%lx (%lu)\n", length, length, start, start);
}
