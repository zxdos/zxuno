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
INSTALL_DATA	?= $(INSTALL) -m 644

LIBS		= liblodepng$(DLLSUFFIX)
HEADERS		= lodepng.h

CFLAGS := -ansi -W -Wall -Wextra -Wpedantic -O3 -Wno-unused-function $(CFLAGS)

.PHONY: all
all: build-libs

build \
$(DESTDIR)$(libdir) \
$(DESTDIR)$(includedir):
	mkdir -p $@

build/liblodepng$(DLLSUFFIX):\
 $(srcdir)/lodepng.c\
 $(srcdir)/lodepng.h\
 Makefile | build
	$(CC) -fPIC -shared $(CFLAGS) -o $@ $<

.PHONY: build-libs
build-libs: $(foreach f,$(LIBS),build/$(f))

$(DESTDIR)$(libdir)/%$(DLLSUFFIX): build/%$(DLLSUFFIX) | $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $< $@

.PHONY: install-libs
install-libs: $(foreach f,$(LIBS),$(DESTDIR)$(libdir)/$(f))

$(DESTDIR)$(includedir)/%.h: $(srcdir)/%.h | $(DESTDIR)$(includedir)
	$(INSTALL_DATA) $< $@

.PHONY: install-headers
install-headers: $(foreach f,$(HEADERS),$(DESTDIR)$(includedir)/$(f))

.PHONY: install
install: install-libs install-headers

.PHONY: uninstall-libs
uninstall-libs:
	$(RM) $(foreach f,$(LIBS),$(DESTDIR)$(libdir)/$(f))

.PHONY: uninstall-headers
uninstall-headers:
	$(RM) $(foreach f,$(HEADERS),$(DESTDIR)$(includedir)/$(f))

.PHONY: uninstall
uninstall: uninstall-libs uninstall-headers

.PHONY: clean
clean:
	$(RM) $(foreach f,$(LIBS),build/$(f))

.PHONY: distclean
distclean:
	$(RM) -r build
