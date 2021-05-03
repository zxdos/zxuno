# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [<TARGET> ...]
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] install | uninstall
# Clean:
#   make [BUILD=<BUILD>] clean
#   make distclean
#
# where:
#   <BUILD> - see included `common.mk'.
#   <TARGET> is one of values for `BINS' variable prefixed with "build/"
#     (see target `all' below).
#   <PREFIX> is a prefix directory to install files into.

include ../../../sdk/common.mk

srcdir		= .
prefix		?= .
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

BINS		:= FuenteABin$(EXESUFFIX)

INCLUDEDIR	= $(ZXSDK)/include
LIBDIR		= $(ZXSDK)/lib

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/FuenteABin$(EXESUFFIX):\
 $(srcdir)/FuenteABin.c\
 $(INCLUDEDIR)/lodepng.h\
 $(LIBDIR)/liblodepng$(DLLSUFFIX)\
 Makefile | build
	$(CC) -I$(INCLUDEDIR) -L$(LIBDIR) -l:liblodepng$(DLLSUFFIX) $(CFLAGS) -o $@ $<

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

$(DESTDIR)$(bindir)/%$(EXESUFFIX): build/%$(EXESUFFIX) | $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $< $@

.PHONY: uninstall
uninstall:
	rm -f $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	rm -f $(foreach t,$(BINS),build/$(t))

.PHONY: distclean
distclean:
	rm -rf build/*
