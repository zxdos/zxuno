# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make
# Clean:
#   make clean

include ../../sdk/common.mk

FUENTEABIN	= tools/build/FuenteABin$(EXESUFFIX)
AS		= sjasmplus
AFLAGS		= --nobanner -I../../sdk/include

.PHONY: all
all: scroll.tap

scroll.tap: scrolldesc.bin
	GenTape $@ basic "SCROLL" 0 $<

scrolldesc.bin: scrolldesc.asm scroll.bin scroll.bin.zx7b
	echo ' define filesize $(shell stat -c %s scroll.bin)' >define.asm
	$(AS) $(AFLAGS) --raw=$@ $<

scroll.bin.zx7b: scroll.bin
	zx7b $< $@

scroll.bin: scroll.asm string.asm music.bin fuente6x8.bin lineas.asm fondo.rcs
	$(AS) $(AFLAGS) --raw=$@ $<

music.bin: playstc.bin music.stc
	cat $^ >$@

fuente6x8.bin: fuente6x8.png | $(FUENTEABIN)
	$(FUENTEABIN) $< $@

$(FUENTEABIN): | tools
ifeq ($(OS),Windows_NT)
	$(MAKE) -w -C $| BUILD=mingw32
else
	$(MAKE) -w -C $|
endif

fondo.rcs: fondo.png fondo.atr
	Png2Rcs $< $@ -a fondo.atr

.PHONY: install
install:;

.PHONY: uninstall
uninstall:;

.PHONY: clean
clean:
	rm -f music.bin fuente6x8.bin fondo.rcs scroll.bin scroll.bin.zx7b define.asm scrolldesc.bin scroll.tap

.PHONY: distclean
distclean:;
