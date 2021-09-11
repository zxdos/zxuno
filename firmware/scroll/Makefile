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
# Test:
#   make test

include ../../sdk/common.mk

srcdir		= .

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
all: $(srcdir)/scroll.tap

$(srcdir)/fondo.rcs:\
 $(srcdir)/fondo.png\
 $(srcdir)/fondo.atr
	Png2Rcs $< $@ -a $(srcdir)/fondo.atr

$(FUENTEABIN): | tools
ifeq ($(OS),Windows_NT)
	$(MAKE) -w -C $| BUILD=mingw32
else
	$(MAKE) -w -C $|
endif

$(srcdir)/fuente6x8.bin: $(srcdir)/fuente6x8.png | $(FUENTEABIN)
	$(FUENTEABIN) $< $@

$(srcdir)/scroll.exp\
$(srcdir)/scroll.bin: $(srcdir)/scroll.asm\
 $(srcdir)/string.asm\
 $(INCLUDEDIR)/playstc.inc\
 $(INCLUDEDIR)/filestc.def\
 $(INCLUDEDIR)/ay.def\
 $(srcdir)/music.stc\
 $(srcdir)/fuente6x8.bin\
 $(srcdir)/lineas.asm\
 $(srcdir)/fondo.rcs
	$(AS) $(AFLAGS) --exp=scroll.exp --raw=scroll.bin $<

$(srcdir)/scroll.bin.zx7b: $(srcdir)/scroll.bin
	zx7b $< $@

$(srcdir)/define.asm:\
 $(srcdir)/scroll.bin\
 $(srcdir)/scroll.exp
	echo 'filesize: EQU $(shell stat -c %s $<)' >$@
	cat $(srcdir)/scroll.exp >>$@

$(srcdir)/scrolldesc.bin:\
 $(srcdir)/scrolldesc.asm\
 $(srcdir)/define.asm\
 $(INCLUDEDIR)/dzx7b.mac\
 $(srcdir)/scroll.bin.zx7b
	$(AS) $(AFLAGS) --raw=$@ $<

$(srcdir)/scroll.tap: $(srcdir)/scrolldesc.bin
	GenTape $@ basic "SCROLL" 0 $<

.PHONY: install
install:;

.PHONY: uninstall
uninstall:;

.PHONY: test
test: $(srcdir)/scroll.tap
	fuse --machine 128 --graphics-filter tv2x --auto-load --fastload --traps $<

.PHONY: clean
clean: | tools
	$(MAKE) -w -C $| $@
	rm -f\
 $(srcdir)/fuente6x8.bin\
 $(srcdir)/fondo.rcs\
 $(srcdir)/scroll.bin\
 $(srcdir)/scroll.exp\
 $(srcdir)/scroll.bin.zx7b\
 $(srcdir)/define.asm\
 $(srcdir)/scrolldesc.bin\
 $(srcdir)/scroll.tap

.PHONY: distclean
distclean: clean | tools
	$(MAKE) -w -C $| $@
