/*
 * fpoke - tool that overwrites bytes in a file.
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

#define PROGRAM "fpoke"
#define DESCRIPTION "tool that overwrites bytes in a file."
#define VERSION "1.0 (11 May 2016)"
#define COPYRIGHT "Copyright (C) 2016, 2021 Antonio Villena"
#define LICENSE \
"This program is free software: you can redistribute it and/or modify\n" \
"it under the terms of the GNU General Public License as published by\n" \
"the Free Software Foundation, version 3."
#define HOMEPAGE "https://github.com/zxdos/zxuno/"

#define BUFFER_LENGTH 0x60000

void show_help() {
  printf(
    PROGRAM " version " VERSION " - " DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: " HOMEPAGE "\n"
    "\n"
    "Usage:\n"
    "  " PROGRAM " <target_file> <addr> [<repeat>x]<bytes> [<addr> [<repeat>x]<bytes>] ..\n"
    "\n"
    "  <target_file>  Origin and target file to poke\n"
    "  <addr>         In hexadecimal, address of the first byte to poke\n"
    "  <repeat>       Number of repetitions, also in hex\n"
    "  <bytes>        Even digits in hex or single quotation string like 'hello'\n"
    "  file:filename  Equivalent to [<repeat>x]<bytes> but with a file\n"
    "\n"
    "At least one sequence of <addr><bytes> is mandatory (<repeat> is optional). The\n"
    "first char of <bytes> can be g or l to indicate biG endian or Little endian,\n"
    "default is little endian. Example:hello.txt 48 65 6C 6C 6F 20 57 6F 72 6C 64 21\n"
    "  " PROGRAM " hello.txt 2 12                      48 65 12 6C 6F 20 57 6F 72 6C 64 21\n"
    "  " PROGRAM " hello.txt 3 1234                    48 65 6C 34 12 20 57 6F 72 6C 64 21\n"
    "  " PROGRAM " hello.txt 4 g123456 0 l1234         34 12 6C 6C 12 34 56 6F 72 6C 64 21\n"
    "  " PROGRAM " hello.txt 5 3xab                    48 65 6C 6C 6F AB AB AB 72 6C 64 21\n"
    "  " PROGRAM " hello.txt 6 'Earth'                 48 65 6C 6C 6F 20 45 61 72 74 68 21\n"
    "  " PROGRAM " hello.txt 6 file:hi.bin\n"
  );
}

char char2hex(char value){
  if( value<'0' || value>'f' || value<'A' && value>'9' || value<'a' && value>'F' )
    printf("\nInvalid character %c\n", value),
    exit(-1);
  return value>'9' ? 9+(value&7) : value-'0';
}

int main(int argc, char* argv[]){
  unsigned char *mem= (unsigned char *) malloc (BUFFER_LENGTH);
  FILE *fi, *fi2;
  char *bytes;
  long start, size, rep, length, i, j, k;
  if( argc==1 )
    show_help(),
    exit(0);
  if( argc&1 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fi= fopen(argv[1], "rb+");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[1]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  size= ftell(fi);
  while ( argc > 2 ){
    start= strtol(argv++[2], NULL, 16);
    if( start<0 )
      start+= size;
    if( bytes= strchr(argv[2], ':') )
      rep= -1,
      argv++;
    else if( strchr(argv[2], 'x') || strchr(argv[2], 'X') )
      rep= strtol(strtok(argv++[2], "xX"), NULL, 16),
      bytes= strtok(NULL, "xX");
    else
      rep= 1,
      bytes= argv++[2];
    if( bytes[0]=='g' || bytes[0]=='l' || bytes[0]=='\'' )
      bytes++;
    if( bytes[-1]=='\'' )
      bytes= strtok(bytes, "'"),
      length= strlen(bytes);
    else if( rep==-1 ){
      fi2= fopen(++bytes, "rb+");
      if( !fi2 )
        printf("\nInput file not found: %s\n", bytes),
        exit(-1);
      fseek(fi2, 0, SEEK_END);
      length= ftell(fi2);
      fseek(fi2, 0, SEEK_SET);
    }
    else{
      length= strlen(bytes);
      if( length&1 )
        printf("\nIncorrect length %X (%s), must be even, in address %X\n", length, bytes, start),
        exit(-1);
      length>>= 1;
    }
    if( length*rep+start > size )
      printf("\nOut of file\n"),
      exit(-1);
    if( length>BUFFER_LENGTH )
      printf("\nOut of buffer\n"),
      exit(-1);
    if( rep==-1 )
      printf("hola %d %d %d\n", argc, length, fread(mem, 1, length, fi2)),
      fclose(fi2);
    else if( bytes[-1]=='g' )
      for ( i= 0; i < length; i++ )
        mem[i]= char2hex(bytes[i<<1|1]) | char2hex(bytes[i<<1]) << 4;
    else if( bytes[-1]=='\'' )
      for ( i= 0; i < length; i++ )
        mem[i]= bytes[i];
    else
      for ( i= 0; i < length; i++ )
        mem[length-i-1]= char2hex(bytes[i<<1|1]) | char2hex(bytes[i<<1]) << 4;
    for ( i= 1; i < rep; i++ )
      if( i*length > BUFFER_LENGTH )
        break;
    if( --i > 1 )
      for ( j= 1; j < i; j++ )
        for ( k= 0; k < length; k++ )
          mem[k+j*length]= mem[k];
    fseek(fi, start, SEEK_SET);
    if( i ){
      j= rep/i;
      for ( k= 0; k < j; k++ )
        fwrite(mem, 1, length*i, fi);
      if( rep%i )
        fwrite(mem, 1, length*(rep%i), fi);
    }
    else
      fwrite(mem, 1, length, fi);
    argc-= 2;
  }
  printf("\nFile correctly modified\n");
  fclose(fi);
}
