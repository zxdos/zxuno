# therighttools.mk - build and install The Right Tools from sources.
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C therighttools -f ../therighttools.mk [all | build]
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] -w -C therighttools -f ../therighttools.mk install | uninstall
# Clean:
#   make [BUILD=<BUILD>] -w -C therighttools -f ../therighttools.mk clean | distclean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <PREFIX> is a prefix directory to install files into.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2022 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../common.mk

INCLUDEDIR	?= $(shell realpath --relative-to=. $(ZXSDK_PLATFORM)/include)
LIBDIR		?= $(shell realpath --relative-to=. $(ZXSDK_PLATFORM)/lib)

.PHONY: all
all: build

$(DESTDIR)$(prefix):
	mkdir -p $@

.PHONY: build
build: | Makefile $(DESTDIR)$(prefix) $(INCLUDEDIR) $(LIBDIR)
	$(MAKE) STATIC_BUILD=0 INCLUDEDIR=$(INCLUDEDIR) LIBDIR=$(LIBDIR) $@-tools

.PHONY: install
install: build | Makefile $(DESTDIR)$(prefix) $(INCLUDEDIR) $(LIBDIR)
	$(MAKE) STATIC_BUILD=0 INCLUDEDIR=$(INCLUDEDIR) LIBDIR=$(LIBDIR) $@-tools

.PHONY: uninstall
uninstall: | Makefile
	$(MAKE) STATIC_BUILD=0 $@-tools

.PHONY: clean distclean
clean distclean: | Makefile
	$(MAKE) STATIC_BUILD=0 $@-tools
