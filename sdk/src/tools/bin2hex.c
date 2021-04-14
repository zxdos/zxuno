/*
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

int main (int argc, char *argv[]){
  FILE *f;
  unsigned char *scr;
  char nombre[256];
  int i,leido;

  if (argc<2)
    return 1;

  scr = (unsigned char *) malloc(65536);
  f = fopen (argv[1],"rb");
  if (!f)
    return 1;

  leido = fread (scr, 1, 65536, f);
  fclose (f);

  strcpy (nombre, argv[1]);
  nombre[strlen(nombre)-3]=0;
  strcat (nombre, "hex");

  f = fopen (nombre, "wt");
  for (i=0;i<leido;i++)
    fprintf (f, "%.2X\n", scr[i]);
  fclose(f);

  return 0;
}
