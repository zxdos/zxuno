#!/bin/make -f
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [<TARGET> ...]
# Install / Uninstall:
#   make [prefix=<PREFIX>] install | uninstall
# Clean:
#   make clean | distclean
#
# where:
#   <TARGET> is one of the values for `all' target.
#   <PREFIX> is a prefix directory to install files into.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2023 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

include ../sdk/common.mk

fontsdir	= .
# Use uppercase for FAT filesystem
prefix		?= .

RM		= rm -f

FONTS=\
 chloe6x8.bin\
 fuente6x8.bin\
 fuente8x6.bin

.PHONY: all
all:\
 build-fonts

build:
	mkdir -p $@

#-----------------------------------------------------------------------------
# fonts

build/chloe6x8.bin: $(fontsdir)/chloe6x8.png | build
	fontconv -q -f 6x8 $< $@

build/fuente6x8.bin: $(fontsdir)/fuente6x8.png | build
	fontconv -q -f 6x8 $< $@

build/fuente8x6.bin: $(fontsdir)/fuente6x8.png | build
	fontconv -q -f 6x8 -t 8x8 -r $< $@

.PHONY: build-fonts
build-fonts: $(foreach f,$(FONTS),build/$(f))

.PHONY: install-fonts
install-fonts:;

.PHONY: uninstall-fonts
uninstall-fonts:;

.PHONY: clean-fonts
clean-fonts:
	$(RM) $(foreach f,$(FONTS),build/$(f))

.PHONY: distclean-fonts
distclean-fonts:
	$(RM) -r build

#-----------------------------------------------------------------------------
# install

.PHONY: install
install:\
 install-fonts

#-----------------------------------------------------------------------------
# uninstall

.PHONY: uninstall
uninstall:\
 uninstall-fonts

#-----------------------------------------------------------------------------
# clean

.PHONY: clean
clean:\
 clean-fonts

#-----------------------------------------------------------------------------
# distclean

.PHONY: distclean
distclean:
	$(RM) -r build
