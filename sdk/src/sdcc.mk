# sdcc.mk - build and install SDCC from sources.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C sdcc -f ../sdcc.mk [all | build]
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] -w -C sdcc -f ../sdcc.mk install | uninstall
# Clean:
#   make [BUILD=<BUILD>] -w -C sdcc -f ../sdcc.mk clean | distclean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <PREFIX> is a prefix directory to install files into.

include ../../common.mk

# Use absolute path for install/uninstall (a feature of SDCC build process)

prefix	?= $(USE_PREFIX)/opt/sdcc

.PHONY: all
all: build

$(DESTDIR)$(prefix):
	mkdir -p $@

Makefile: configure
	./configure

.PHONY: build
build: | Makefile
	$(MAKE)

.PHONY: install
install: | Makefile $(DESTDIR)$(prefix)
	$(MAKE) prefix=$(shell realpath $(DESTDIR)$(prefix)) $@

.PHONY: uninstall
uninstall: | Makefile
	$(MAKE) prefix=$(shell realpath $(DESTDIR)$(prefix)) $@

.PHONY: clean distclean
clean distclean: | Makefile
	$(MAKE) $@
