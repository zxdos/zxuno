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

INCLUDEDIR	= ../../sdk/include
FUENTEABIN	= tools/build/FuenteABin$(EXESUFFIX)
AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
$(error Original SJAsmPlus is not supported for now - use version by `z00m128')
AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
AFLAGS		= --nologo
else
AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR)

.PHONY: all
all: scroll.tap

scroll.tap: scrolldesc.bin
	GenTape $@ basic "SCROLL" 0 $<

scrolldesc.bin: scrolldesc.asm define.asm scroll.bin.zx7b
	$(AS) $(AFLAGS) --raw=$@ $<

define.asm: scroll.bin scroll.exp
	echo ' define filesize $(shell stat -c %s $<)' >$@
	cat scroll.exp >>$@

scroll.bin.zx7b: scroll.bin
	zx7b $< $@

scroll.bin scroll.exp:\
 scroll.asm\
 string.asm\
 $(INCLUDEDIR)/playstc.inc\
 $(INCLUDEDIR)/filestc.def\
 $(INCLUDEDIR)/ay.def\
 music.stc\
 fuente6x8.bin\
 lineas.asm\
 fondo.rcs
	$(AS) $(AFLAGS) --raw=scroll.bin --exp=scroll.exp $<

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
clean: | tools
	$(MAKE) -w -C $| $@
	rm -f fuente6x8.bin fondo.rcs scroll.bin scroll.exp scroll.bin.zx7b define.asm scrolldesc.bin scroll.tap

.PHONY: distclean
distclean:;
