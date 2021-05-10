# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C sjasmplus -f ../sjasmplus.mk
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] -w -C sjasmplus -f ../sjasmplus.mk install | uninstall
# Clean:
#   make [BUILD=<BUILD>] -w -C sjasmplus -f ../sjasmplus.mk clean
#
# where:
#   <BUILD> - see included `common.mk'.
#   <PREFIX> is a prefix directory to install files into.

include ../../common.mk

srcdir		= .
prefix		?= /usr/local
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

BINS		= sjasmplus$(EXESUFFIX)

ifeq ($(BUILD),mingw32)
CMAKEFLAGS	:= -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw32.cmake
else ifeq ($(BUILD),mingw64)
CMAKEFLAGS	:= -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw64.cmake
else
CMAKEFLAGS	:=
endif

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/sjasmplus$(EXESUFFIX): | build/Makefile
	$(MAKE) -w -C build

build/Makefile: | build
	cd $| && cmake $(CMAKEFLAGS) ..

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): build/sjasmplus$(EXESUFFIX) | $(DESTDIR)$(bindir)
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
