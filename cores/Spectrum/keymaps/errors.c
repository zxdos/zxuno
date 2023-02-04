/*
 * errors.c
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2023 Ivan Tatarinov
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "errors.h"

void message(const char *format,...) {
  va_list ap;
  va_start(ap,format);
  fprintf(stderr,PROGRAM ": ");
  vfprintf(stderr,format,ap);
  fprintf(stderr,"\n");
  va_end(ap);
}

void error(const char *format,...) {
  va_list ap;
  va_start(ap,format);
  fprintf(stderr,PROGRAM ": ERROR: ");
  vfprintf(stderr,format,ap);
  fprintf(stderr,"\n");
  va_end(ap);
}

void error_missing_arg(const char *name,unsigned index) {
  error("Missing parameter for \"%s\" (argument %u).",name,index);
}

void error_bad_arg(const char *name,unsigned index) {
  error("Bad parameter value for \"%s\" (argument %u).",name,index);
}
