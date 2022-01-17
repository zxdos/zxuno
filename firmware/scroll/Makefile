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
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021, 2022 Ivan Tatarinov
# SPDX-FileNotice: Based on code by Antonio Villena
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../sdk/common.mk

-include conf.mk
VERSION ?= 1

srcdir		= .

INCLUDEDIR	= ../../sdk/include

INCLUDEDIRS	= $(INCLUDEDIR) build

AS = sjasmplus
ifeq ($(USE_SJASMPLUS_BRANCH),sjasmplus)
 $(error Original SJAsmPlus is not supported for now - use version by Aprisobal ("z00m128"))
 AFLAGS = --nobanner
else ifeq ($(USE_SJASMPLUS_BRANCH),z00m128)
 AFLAGS = --nologo
else
 AFLAGS =
endif
AFLAGS += $(addprefix -I,$(INCLUDEDIRS))

.PHONY: all
all: build/scroll.tap

build:
	mkdir -p $@

ifeq ($(VERSION),1)

build/fondo.rcs:\
 images/fondo.png\
 images/fondo.atr\
 | build
	scrconv -q -t rcs $< $@ -a images/fondo.atr

SCROLL_DEPS = build/fondo.rcs

else ifeq ($(VERSION),2)

build/fondo2.rcs:\
 images/fondo2.png\
 images/fondo2.atr\
 | build
	scrconv -q -t rcs $< $@ -a images/fondo2.atr

SCROLL_DEPS = build/fondo2.rcs

else
 $(error Unknown version selected: $(VERSION))
endif

build/fuente6x8.bin: fonts/fuente6x8.png | build
	fontconv -q -f 6x8 $< $@

build/scroll.exp build/scroll.bin: $(srcdir)/scroll.asm\
 $(INCLUDEDIR)/ay.def\
 $(INCLUDEDIR)/filestc.def\
 $(INCLUDEDIR)/memcpy.mac\
 $(INCLUDEDIR)/playstc.inc\
 $(INCLUDEDIR)/prn6x8f.mac\
 $(INCLUDEDIR)/rcs.mac\
 $(INCLUDEDIR)/rever.mac\
 $(srcdir)/music.stc\
 $(srcdir)/string.asm\
 build/fuente6x8.bin\
 $(SCROLL_DEPS)\
 | build
	$(AS) $(AFLAGS) -DVERSION=$(VERSION) --exp=build/scroll.exp --raw=build/scroll.bin $<

build/scroll.bin.zx7b: build/scroll.bin
	zx7b $< $@

build/define.asm:\
 build/scroll.bin\
 build/scroll.exp
	echo 'filesize: EQU $(shell stat -c %s $<)' >$@
	cat build/scroll.exp >>$@

build/scrolldesc.bin:\
 $(srcdir)/scrolldesc.asm\
 build/define.asm\
 $(INCLUDEDIR)/dzx7b.mac\
 build/scroll.bin.zx7b
	$(AS) $(AFLAGS) --raw=$@ $<

build/scroll.tap: build/scrolldesc.bin
	GenTape $@ basic "SCROLL" 0 $<

.PHONY: install
install:;

.PHONY: uninstall
uninstall:;

.PHONY: test
test: build/scroll.tap
	fuse --machine 128 --graphics-filter tv2x --auto-load --fastload --traps $<

.PHONY: clean
clean:
	$(RM)\
 build/fuente6x8.bin\
 $(SCROLL_DEPS)\
 build/scroll.bin\
 build/scroll.exp\
 build/scroll.bin.zx7b\
 build/define.asm\
 build/scrolldesc.bin\
 build/scroll.tap

.PHONY: distclean
distclean:
	$(RM) -r build
