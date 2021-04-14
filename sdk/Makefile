# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [<TARGET>]
# Clean:
#   make [BUILD=<BUILD>] [FORCECLEAN=<FC_FLAG>] clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of values of TOOLS variable (see below).
#
# Notes:
#   BUILD, FORCEBUILD, FORCECLEAN variables may be set in user's environment.

include common.mk

ifeq ($(BUILD),mingw32)
FORCEBUILD:=1
else ifeq ($(BUILD),mingw64)
FORCEBUILD:=1
else
BUILD:=
FORCEBUILD:=0
endif

ifdef $(FORCECLEAN)
ifneq ($(FORCECLEAN),1)
FORCECLEAN:=0
else
FORCECLEAN:=0
endif
endif

export BUILD
export FORCEBUILD
export FORCECLEAN

SJASMPLUS	:= sjasmplus$(EXECEXT)
ZX7B		:= zx7b$(EXECEXT)
BIN2HEX		:= bin2hex$(EXECEXT)
FCUT		:= fcut$(EXECEXT)
FPAD		:= fpad$(EXECEXT)
FPOKE		:= fpoke$(EXECEXT)
GENROM		:= GenRom$(EXECEXT)
ADDITEM		:= AddItem$(EXECEXT)

TOOLS:=\
 bin/$(SJASMPLUS) \
 bin/$(ZX7B) \
 bin/$(BIN2HEX) \
 bin/$(FCUT) \
 bin/$(FPAD) \
 bin/$(FPOKE) \
 bin/$(GENROM) \
 bin/$(ADDITEM)

.PHONY: all
all: $(TOOLS)

$(TOOLS): | src/Makefile
	$(MAKE) -w -C src ../bin/$(@F)

.PHONY: clean
clean: | src/Makefile
	$(MAKE) -w -C src clean
