/*
 * errors.h - routines to print common error messages.
 *
 * SPDX-FileType: SOURCE
 * SPDX-FileCopyrightText: 2023 Ivan Tatarinov
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef ERRORS_H
#define ERRORS_H

#include <stdarg.h>

void message(const char *format,...);
void error(const char *format,...);
void error_missing_arg(const char *name,unsigned index);
void error_bad_arg(const char *name,unsigned index);

#endif  /* !ERRORS_H */
