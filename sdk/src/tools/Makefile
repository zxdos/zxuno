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
#   <TARGET> is one of values for TOOLS variable (see below).
#
# Notes:
#   BUILD variable may be set in user's environment.

include ../../common.mk

BIN2HEX	:= bin2hex$(EXECEXT)
FCUT	:= fcut$(EXECEXT)
FPAD	:= fpad$(EXECEXT)
FPOKE	:= fpoke$(EXECEXT)
GENROM	:= GenRom$(EXECEXT)
ADDITEM	:= AddItem$(EXECEXT)

TOOLS:=\
 $(BIN2HEX) \
 $(FCUT) \
 $(FPAD) \
 $(FPOKE) \
 $(GENROM) \
 $(ADDITEM)

.PHONY: all
all: $(TOOLS)

$(BIN2HEX): bin2hex.c
	$(CC) $(CFLAGS) -o $@ $<

$(FCUT): fcut.c
	$(CC) $(CFLAGS) -o $@ $<

$(FPAD): fpad.c
	$(CC) $(CFLAGS) -o $@ $<

$(FPOKE): fpoke.c
	$(CC) $(CFLAGS) -o $@ $<

$(GENROM): GenRom.c
	$(CC) $(CFLAGS) -o $@ $<

$(ADDITEM): AddItem.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f $(TOOLS)
