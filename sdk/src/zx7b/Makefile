# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [<TARGET>]
# Clean:
#   make [BUILD=<BUILD>] clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <TARGET> is one of values of TOOLS variable (see below).
#
# Notes:
#   BUILD variable may be set in user's environment.

include ../../common.mk

ZX7B	:= zx7b$(EXECEXT)

$(ZX7B): zx7b.c
	$(CC) $(CFLAGS) -o $@ $<

zx7b.c:
	wget -c https://github.com/antoniovillena/zx7b/raw/master/zx7b.c

clean:
	rm -f $(ZX7B)
