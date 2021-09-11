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
#   <TARGET> is one of values for `LIBS' variable prefixed with "build/"
#     (see target `all' below).
#   <PREFIX> is a prefix directory to install files into.

include ../../common.mk

srcdir		= .
prefix		?= /usr/local
libdir		?= $(prefix)/lib
includedir	?= $(prefix)/include

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

LIBS		= liblodepng$(DLLSUFFIX)
HEADERS		= lodepng.h

CFLAGS := -W -Wall -Wextra -ansi -pedantic -O3 -Wno-unused-function $(CFLAGS)

.PHONY: all
all: $(foreach t,$(LIBS),build/$(t))

build \
$(DESTDIR)$(libdir) \
$(DESTDIR)$(includedir):
	mkdir -p $@

build/liblodepng$(DLLSUFFIX):\
 $(srcdir)/lodepng.c\
 $(srcdir)/lodepng.h\
 Makefile | build
	$(CC) -fPIC -shared $(CFLAGS) -o $@ $<

.PHONY: install
install:\
 $(foreach t,$(LIBS),$(DESTDIR)$(libdir)/$(t)) \
 $(foreach t,$(HEADERS),$(DESTDIR)$(includedir)/$(t))

$(DESTDIR)$(libdir)/%$(DLLSUFFIX): build/%$(DLLSUFFIX) | $(DESTDIR)$(libdir)
	$(INSTALL) -m 644 $< $@

$(DESTDIR)$(includedir)/%.h: %.h | $(DESTDIR)$(includedir)
	$(INSTALL) -m 644 $< $@

.PHONY: uninstall
uninstall:
	rm -f $(foreach t,$(LIBS),$(DESTDIR)$(libdir)/$(t))
	rm -f $(foreach t,$(HEADERS),$(DESTDIR)$(includedir)/$(t))

.PHONY: clean
clean:
	rm -f $(foreach t,$(LIBS),build/$(t))

.PHONY: distclean
distclean:
	rm -rf build
