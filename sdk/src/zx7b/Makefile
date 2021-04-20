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
#   <TARGET> is the value of TARGET variable (see below).
#
# Notes:
#   BUILD variable may be set in user's environment.

include ../../common.mk

TARGET	:= zx7b$(EXESUFFIX)

.PHONY: all
all: $(TARGET)

%$(EXESUFFIX): %.c Makefile
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f $(TARGET)
