/*
 * genkeybmap - generates ZX Spectrum core's keymap file for ZXUNO/ZXDOS.
 *
 * Copyright (C) 2014-2023 Miguel Angel Rodriguez Jodar
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2014-2023 Miguel Angel Rodriguez Jodar
 * SPDX-FileContributor: 2022 Antonio Villena
 * SPDX-FileContributor: 2023 Ivan Tatarinov
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <stdio.h>
#include <string.h>

#define PROGRAM "genkeybmap"
#define DESCRIPTION                                                          \
"Generates ZX Spectrum core's keymap file for ZXUNO/ZXDOS."
#define VERSION "1.0"
#define COPYRIGHT                                                            \
"Copyright (C) 2014-2023 Miguel Angel Rodriguez Jodar\n"                     \
"Contributors: 2022 Antonio Villena, 2023 Ivan Tatarinov"
#define LICENSE                                                              \
"This program is free software: you can redistribute it and/or modify\n"     \
"it under the terms of the GNU General Public License as published by\n"     \
"the Free Software Foundation, either version 3 of the License, or\n"        \
"(at your option) any later version."
#define HOMEPAGE "https://github.com/ivan-tat/zxuno"

#define HELP_HINT                                                            \
"Use \"-h\" to get help."

typedef unsigned char u8;
typedef unsigned short u16;

/* Options */
char        opt_help=0;
char        opt_version=0;
char        opt_hex=0;    /* do output hex. files */
const char *opt_hexf[2]={ /* output hex. filenames */
    NULL,NULL
  };
int         opt_ki=-1;    /* keymap index (none) */
const char *opt_of=NULL;  /* output filename */

/*
 SPkey - Spectrum key
7<-----0
AAADDDDD

AAA   = semi-row of the keyboard to be modified | this information is
DDDDD = data (bit-negated) from that semi-row   | stored for two keys

Each PC key to Spectrum key(s) mapping will occupy two consecutive directions:
D+0 : SPkey1 (or 0 if there is none)
D+1 : SPkey2 (or 0 if there is none)

Parameter to map routines (16-bit integer):
 SPkey1   SPkey2
F<-----8 7<-----0
AAADDDDD AAADDDDD

Example 1: in the memory address D corresponding to the code of the 6 key
(PC), which would correspond to the single pressing of 6 (Spectrum), we would
put:

SPkey1=00000000 (no key)
SPkey2=10010000 (6)

Parameter to map routine (16-bit integer):
 SPkey1   SPkey2
F<-----8 7<-----0
00000000 10010000

That is: semi-row 4 is activated, and in that one bit 4 is activated

Example 2: in the memory address D corresponding to the code of the ESC key
(PC), which would correspond to the simultaneous pressing of CAPS SHIFT+SPACE
(Spectrum), we would put:

SPkey1=00000001 (CAPS SHIFT)
SPkey2=11100001 (SPACE)

Parameter to map routine (16-bit integer):
 SPkey1   SPkey2
F<-----8 7<-----0
00000001 11100001

That is: semi-rows 0 and 7 are activated, and in each one, bit 0 is activated

128 codes + E0 = 256 codes (E0=extended scan code flag, 1-bit)
SHIFT, CTRL, ALT = 8 combinations
256 codes x 8 combinations = 2048 addresses
2048 addresses x 16 bits = 32768 bits
In the core will be available as a 4096 x 8-bit memory
*/

u8 keymap[8][256][2];

#include "keys_pc.h"
#include "keys_sp.h"
#include "errors.c"

void map(u16 pc,u16 sp) {
  keymap[(pc>>8)&7][pc&255][0]=sp>>8;
  keymap[(pc>>8)&7][pc&255][1]=sp&255;
}

void map_alfa(u8 pc,u8 sp) {
  /* No modifiers: */
  keymap[0][pc][0]=0;
  keymap[0][pc][1]=sp;
  /* SHIFT modifier: */
  keymap[1][pc][0]=SP_CAPS;
  keymap[1][pc][1]=sp;
}

void map_all(u8 pc,u16 sp) {
  u8 m;
  for(m=0;m<8;m++) {
    keymap[m][pc&255][0]=sp>>8;
    keymap[m][pc&255][1]=sp&255;
  }
}

void map_xall(u8 pc,u16 sp) {
  u8 m;
  /* All modifiers only: */
  for(m=1;m<8;m++) {
    keymap[m][pc&255][0]=sp>>8;
    keymap[m][pc&255][1]=sp&255;
  }
}

#include "keymap_av_fw.c"
#include "keymap_av_sd.c"
#include "keymap_es_fw.c"
#include "keymap_es_sd.c"
#include "keymap_us_fw.c"
#include "keymap_us_sd.c"

const struct keymap_t {
  const char *id,*comment,*version;
  void (*gen)();  /* keymap generator */
} keymaps[]={
  {KEYMAP_AV_FW,COMMENT_AV_FW,VERSION_AV_FW,gen_keymap_av_fw},
  {KEYMAP_AV_SD,COMMENT_AV_SD,VERSION_AV_SD,gen_keymap_av_sd},
  {KEYMAP_ES_FW,COMMENT_ES_FW,VERSION_ES_FW,gen_keymap_es_fw},
  {KEYMAP_ES_SD,COMMENT_ES_SD,VERSION_ES_SD,gen_keymap_es_sd},
  {KEYMAP_US_FW,COMMENT_US_FW,VERSION_US_FW,gen_keymap_us_fw},
  {KEYMAP_US_SD,COMMENT_US_SD,VERSION_US_SD,gen_keymap_us_sd},
  {NULL,NULL,NULL}  /* stop mark */
};

void show_version() {
  printf(
    PROGRAM ", version " VERSION " (built on " __DATE__ " " __TIME__ ")\n"
  );
}

void show_usage() {
  int i;
  show_version();
  printf(
    DESCRIPTION "\n"
    COPYRIGHT "\n"
    LICENSE "\n"
    "Home page: <" HOMEPAGE ">\n"
  );
  printf(
    "\n"
    "Usage:\n"
    "  " PROGRAM " [options...] [--] ID [OUTPUT]\n"
    "\n"
    "Options:\n"
    "  -h, --help         Show this help\n"
    "  -v, --version      Show version\n"
    "  --hex FILE1 FILE2  Write Verilog files for ZXUNO/ZXDOS core\n"
    "  --                 Stop parsing options\n"
    "\n"
    "Where:\n"
    "  ID      Keymap ID (see `Available keymaps' below)\n"
    "  OUTPUT  ZX Spectrum core's keymap file (4 KiB size)\n"
  );
  printf(
    "\n"
    "Available keymaps (ID - comment, version):\n"
  );
  for(i=0;keymaps[i].id;i++)
    printf("  %s - %s, version %s\n",
      (char*)keymaps[i].id,
      (char*)keymaps[i].comment,
      (char*)keymaps[i].version
    );
}

/* Returns 0 on success, other value on error */
int parse_arg_keymap_id(int *a,const char *arg) {
  int i;
  for(i=0;keymaps[i].id;i++)
    if(!strcmp(keymaps[i].id,arg)) {
      *a=i;
      return 0;
    }
  return -1;
}

/* Returns 0 on success, 1 if no arguments, other value on other error */
int parse_args(int argc,const char **argv) {
  int f,i;
  char optsend=0;
  if(argc==1) return 1;
  f=0;
  for(i=1;i<argc;i++) {
    if((!optsend)&&(argv[i][0]=='-')) {
      if(!strcmp(&argv[i][1],"-")) optsend=1;
      else if((!strcmp(&argv[i][1],"h"))
           || (!strcmp(&argv[i][1],"-help"))) opt_help=1;
      else if((!strcmp(&argv[i][1],"v"))
           || (!strcmp(&argv[i][1],"-version"))) opt_version=1;
      else if(!strcmp (&argv[i][1],"-hex")) {
        if(i+2>=argc) {
          error_missing_arg(argv[i],i);
          return -1;
        }
        opt_hex=1;
        opt_hexf[0]=argv[++i];
        opt_hexf[1]=argv[++i];
      } else {
        error("Unknown option \"%s\" (argument %u)",argv[i],i);
        return -1;
      }
    } else {
      switch(f++) {
      case 0:
        if(parse_arg_keymap_id(&opt_ki,argv[i])) {
          error_bad_arg("keymap ID",i);
          return -1;
        }
        break;
      case 1: opt_of=argv[i]; break;
      default:
        error("Extra parameter \"%s\" given (argument %u)",argv[i],i);
        return -1;
      }
    }
  }
  return 0;
}

int save_hex(u8 *data,size_t size,const char *name) {
  FILE *f=fopen(name,"w");
  int i;
  if(!f) {
    error("Failed to open output file \"%s\"",name);
    return 1;
  }
  for(i=0;i<size;i++) {
    if(fprintf(f,"%02hhX\n",data[i])<0) {
      fclose(f);
      error("Failed to write output file \"%s\"",name);
      return 1;
    }
  }
  fclose(f);
  return 0;
}

int save_raw(void *data,size_t size,const char *name) {
  FILE *f=fopen(name,"w");
  if(!f) {
    error("Failed to open output file \"%s\"",name);
    return 1;
  }
  if(!fwrite(data,size,1,f)) {
    fclose(f);
    error("Failed to write output file \"%s\"",name);
    return 1;
  }
  fclose(f);
  return 0;
}

int main(int argc,const char **argv) {
  switch(parse_args(argc,argv)) {
  case 0: break;
  case 1:
    message("No parameters. " HELP_HINT);
    return 0;
  default:
    return -1;
  }

  if(opt_help) {
    show_usage();
    return 0;
  }

  if(opt_version) {
    show_version();
    return 0;
  }

  if(opt_ki<0) {
    error("No keymap ID specified");
    return 1;
  }

  if(!(opt_hex||opt_of)) {
    error("Neither option \"--hex\" nor output file specified");
    return 1;
  }

  keymaps[opt_ki].gen();

  if(opt_hex) {
    u8 data[8][256];
    int i,j;
    for(i=0;i<8;i++) for(j=0;j<256;j++) data[i][j]=keymap[i][j][0];
    if(save_hex((u8*)data,sizeof(data),opt_hexf[0])) return 1;
    for(i=0;i<8;i++) for(j=0;j<256;j++) data[i][j]=keymap[i][j][1];
    if(save_hex((u8*)data,sizeof(data),opt_hexf[1])) return 1;
  }

  if(opt_of)
    if(save_raw((void*)keymap,sizeof(keymap),opt_of)) return 1;

  return 0;
}
