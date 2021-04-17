/*
 * fpad - generate a file with padded values.
 *
 * Copyright (C) 2016, 2021 Antonio Villena
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
 * SPDX-FileCopyrightText: Copyright (C) 2016, 2021 Antonio Villena
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROGRAM "fpad"
#define DESCRIPTION "generate a file with padded values."
#define VERSION "1.00 (24 Apr 2016)"
#define COPYRIGHT "Copyright (C) 2016, 2021 Antonio Villena"
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
    "  " PROGRAM " <length> <byte> <output_file>\n"
    "\n"
    "  <length>       In hexadecimal, is the length of the future file\n"
    "  <byte>         In hexadecimal, is the value of the padding\n"
    "  <output_file>  Genetated output file\n"
  );
}

int main(int argc, char* argv[]){
  unsigned char mem[0x10000];
  FILE *fo;
  long length, size;
  if( argc==1 )
    show_help(),
    exit(0);
  if( argc!=4 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fo= fopen(argv[3], "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", argv[3]),
    exit(-1);
  memset(mem, strtol(argv[2], NULL, 16), 0x10000);
  length= strtol(argv[1], NULL, 16);
  for ( size= 0; size<length>>16; size++ )
    fwrite(mem, 1, 0x10000, fo);
  fwrite(mem, 1, length&0xffff, fo);
  fclose(fo);
  printf("\nDone\n");
}
