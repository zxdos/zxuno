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
#   <PREFIX> is a prefix directory to install files into.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021, 2022, 2023 Ivan Tatarinov
# SPDX-FileNotice: Based on code by Antonio Villena
# SPDX-License-Identifier: GPL-3.0-or-later

include ../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
keymapsdir	?= $(prefix)/SYS/KEYMAPS

INSTALL		?= install
INSTALL_DATA	?= $(INSTALL) -m 644
RM		?= rm -f
MKDIR		?= mkdir

INCLUDEDIR	= ../sdk/include
KEYMAPSDIR	= ../cores/Spectrum/keymaps/build
FONTSDIR	= ../fonts/build
AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_BRANCH),sjasmplus)
 AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_BRANCH),z00m128)
 AFLAGS		= --nologo
else
 AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR) -I$(FONTSDIR)

KEYMAPS=\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b

IMAGES=$(patsubst images/%,%,$(wildcard images/*.png))

.PHONY: all
all:\
 build-keymaps\
 build-images\
 build-firmwares

build\
build/zxuno\
build/zxdos\
build/zxdosplus\
build/buryak\
build/unoxt\
build/v4:
	$(MKDIR) -p $@

#-----------------------------------------------------------------------------
# keymaps

build/av.zx7b: $(KEYMAPSDIR)/av-fw.bin | build
	zx7b $< $@

build/es.zx7b: $(KEYMAPSDIR)/es-fw.bin | build
	zx7b $< $@

build/us.zx7b: $(KEYMAPSDIR)/us-fw.bin | build
	zx7b $< $@

.PHONY: build-keymaps
build-keymaps: $(KEYMAPS)

.PHONY: clean-keymaps
clean-keymaps:
	$(RM) $(KEYMAPS)

.PHONY: distclean-keymaps
distclean-keymaps: clean-keymaps

#-----------------------------------------------------------------------------
# images

# $(1) = source filename
define build_image_rule =
build/$(1:.png=.rcs): images/$(1) $(wildcard images/$(1:.png=.atr)) | build
 ifneq ($(wildcard images/$(1:.png=.atr)),)
	scrconv -q -t rcs $$< $$@ -a images/$(1:.png=.atr)
 else
	scrconv -q -t rcs $$< $$@
 endif
build/$(1:.png=.rcs.zx7b): build/$(1:.png=.rcs)
	zx7b $$< $$@
endef

$(foreach i,$(IMAGES),$(eval $(call build_image_rule,$(i))))

.PHONY: build-images
build-images: $(foreach i,$(IMAGES),build/$(i:.png=.rcs.zx7b))

.PHONY: clean-images
clean-images:
	$(RM) $(foreach i,$(IMAGES),build/$(i:.png=.rcs) build/$(i:.png=.rcs.zx7b))

.PHONY: distclean-images
distclean-images: clean-images

#-----------------------------------------------------------------------------
# temporary solution (until main developer merge all these local changes upstream)

firmware-new.asm: firmware.asm Makefile
	{\
	 echo '; firmware.asm - BIOS';\
	 echo ';';\
	 echo '; SPDX-FileType: SOURCE';\
	 echo '; SPDX-FileCopyrightText: 2016-2022 Antonio Villena';\
	 echo '; SPDX-FileContributor: 2020 Aitor Gómez';\
	 echo '; SPDX-FileContributor: 2022 Ivan Tatarinov';\
	 echo '; SPDX-License-Identifier: GPL-3.0-only';\
	 echo '';\
	 echo ' include version.asm';\
	 echo '';\
	 tail -n+9 $< | sed -Ee 's,(strings)(\.asm),\1-new\2,';\
	 } > $@

strings-new.asm: strings.asm Makefile
	{\
	 echo '; strings.asm - text messages and string constants';\
	 echo ';';\
	 echo '; SPDX-FileType: SOURCE';\
	 echo '; SPDX-FileCopyrightText: 2016-2022 Antonio Villena';\
	 echo '; SPDX-FileContributor: 2020 Aitor Gómez';\
	 echo '; SPDX-FileContributor: 2022 Ivan Tatarinov';\
	 echo '; SPDX-License-Identifier: GPL-3.0-only';\
	 echo '';\
	 echo ' include version.asm';\
	 echo '';\
	 sed -Ee "s,'([^']+)\\\\'([^']+)',\"\1'\2\"," $<;\
	 } > $@

#-----------------------------------------------------------------------------
# firmware for ZXUNO

build/zxuno/version.asm: | build/zxuno
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 1 ; ZXUNO';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/zxuno/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/zxuno/version.asm
	$(AS) $(AFLAGS) -Ibuild/zxuno --raw=$@ $<

build/zxuno/strings.bin.zx7b: build/zxuno/strings.bin
	zx7b $< $@

build/zxuno/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192.rcs.zx7b\
 build/zxuno/version.asm\
 build/zxuno/strings.bin.zx7b\
 | build/zxuno
	$(AS) $(AFLAGS) -Ibuild/zxuno --raw=$@ $<

build/zxuno/firmware.rom: build/zxuno/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-zxuno
build-firmware-zxuno: | build/zxuno
	$(MAKE) -w build/zxuno/firmware.rom

.PHONY: install-firmware-zxuno
install-firmware-zxuno:;

.PHONY: uninstall-firmware-zxuno
uninstall-firmware-zxuno:;

.PHONY: clean-firmware-zxuno
clean-firmware-zxuno:
	$(RM) -r build/zxuno

#-----------------------------------------------------------------------------
# firmware for ZXDOS

build/zxdos/version.asm: | build/zxdos
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 2; ZXDOS';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/zxdos/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/zxdos/version.asm
	$(AS) $(AFLAGS) -Ibuild/zxdos --raw=$@ $<

build/zxdos/strings.bin.zx7b: build/zxdos/strings.bin
	zx7b $< $@

build/zxdos/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192d.rcs.zx7b\
 build/zxdos/version.asm\
 build/zxdos/strings.bin.zx7b\
 | build/zxdos
	$(AS) $(AFLAGS) -Ibuild/zxdos --raw=$@ $<

build/zxdos/firmware.rom: build/zxdos/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-zxdos
build-firmware-zxdos: | build/zxdos
	$(MAKE) -w build/zxdos/firmware.rom

.PHONY: install-firmware-zxdos
install-firmware-zxdos:;

.PHONY: uninstall-firmware-zxdos
uninstall-firmware-zxdos:;

.PHONY: clean-firmware-zxdos
clean-firmware-zxdos:
	$(RM) -r build/zxdos

#-----------------------------------------------------------------------------
# firmware for ZXDOS+

build/zxdosplus/version.asm: | build/zxdosplus
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 3 ; use "clones"';\
	 echo '  define clones 0 ; ZXDOS+';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/zxdosplus/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/zxdosplus/version.asm
	$(AS) $(AFLAGS) -Ibuild/zxdosplus --raw=$@ $<

build/zxdosplus/strings.bin.zx7b: build/zxdosplus/strings.bin
	zx7b $< $@

build/zxdosplus/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192dp.rcs.zx7b\
 build/zxdosplus/version.asm\
 build/zxdosplus/strings.bin.zx7b\
 | build/zxdosplus
	$(AS) $(AFLAGS) -Ibuild/zxdosplus --raw=$@ $<

build/zxdosplus/firmware.rom: build/zxdosplus/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-zxdosplus
build-firmware-zxdosplus: | build/zxdosplus
	$(MAKE) -w build/zxdosplus/firmware.rom

.PHONY: install-firmware-zxdosplus
install-firmware-zxdosplus:;

.PHONY: uninstall-firmware-zxdosplus
uninstall-firmware-zxdosplus:;

.PHONY: clean-firmware-zxdosplus
clean-firmware-zxdosplus:
	$(RM) -r build/zxdosplus

#-----------------------------------------------------------------------------
# firmware for Buryak Next

build/buryak/version.asm: | build/buryak
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 3 ; use "clones"';\
	 echo '  define clones 1 ; Buryak Next';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/buryak/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/buryak/version.asm
	$(AS) $(AFLAGS) -Ibuild/buryak --raw=$@ $<

build/buryak/strings.bin.zx7b: build/buryak/strings.bin
	zx7b $< $@

build/buryak/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192dp.rcs.zx7b\
 build/buryak/version.asm\
 build/buryak/strings.bin.zx7b\
 | build/buryak
	$(AS) $(AFLAGS) -Ibuild/buryak --raw=$@ $<

build/buryak/firmware.rom: build/buryak/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-buryak
build-firmware-buryak: | build/buryak
	$(MAKE) -w build/buryak/firmware.rom

.PHONY: install-firmware-buryak
install-firmware-buryak:;

.PHONY: uninstall-firmware-buryak
uninstall-firmware-buryak:;

.PHONY: clean-firmware-buryak
clean-firmware-buryak:
	$(RM) -r build/buryak

#-----------------------------------------------------------------------------
# firmware for UnoXT

build/unoxt/version.asm: | build/unoxt
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 3 ; use "clones"';\
	 echo '  define clones 2 ; UnoXT';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/unoxt/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/unoxt/version.asm
	$(AS) $(AFLAGS) -Ibuild/unoxt --raw=$@ $<

build/unoxt/strings.bin.zx7b: build/unoxt/strings.bin
	zx7b $< $@

build/unoxt/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192ut.rcs.zx7b\
 build/unoxt/version.asm\
 build/unoxt/strings.bin.zx7b\
 | build/unoxt
	$(AS) $(AFLAGS) -Ibuild/unoxt --raw=$@ $<

build/unoxt/firmware.rom: build/unoxt/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-unoxt
build-firmware-unoxt: | build/unoxt
	$(MAKE) -w build/unoxt/firmware.rom

.PHONY: install-firmware-unoxt
install-firmware-unoxt:;

.PHONY: uninstall-firmware-unoxt
uninstall-firmware-unoxt:;

.PHONY: clean-firmware-unoxt
clean-firmware-unoxt:
	$(RM) -r build/unoxt

#-----------------------------------------------------------------------------
# firmware version 4 (?)

build/v4/version.asm: | build/v4
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 4 ; ?';\
	 echo '  define clones 0 ; ?';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo ' endif';\
	 } > $@

build/v4/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/v4/version.asm
	$(AS) $(AFLAGS) -Ibuild/v4 --raw=$@ $<

build/v4/strings.bin.zx7b: build/v4/strings.bin
	zx7b $< $@

build/v4/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 $(FONTSDIR)/fuente6x8.bin\
 build/logo256x192dp.rcs.zx7b\
 build/v4/version.asm\
 build/v4/strings.bin.zx7b\
 | build/v4
	$(AS) $(AFLAGS) -Ibuild/v4 --raw=$@ $<

build/v4/firmware.rom: build/v4/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-v4
build-firmware-v4: | build/v4
	$(MAKE) -w build/v4/firmware.rom

.PHONY: install-firmware-v4
install-firmware-v4:;

.PHONY: uninstall-firmware-v4
uninstall-firmware-v4:;

.PHONY: clean-firmware-v4
clean-firmware-v4:
	$(RM) -r build/v4

#-----------------------------------------------------------------------------
# firmwares (all)

.PHONY: build-firmwares
build-firmwares:\
 build-firmware-zxuno\
 build-firmware-zxdos\
 build-firmware-zxdosplus\
 build-firmware-buryak\
 build-firmware-unoxt\
 build-firmware-v4

.PHONY: install-firmwares
install-firmwares:\
 install-firmware-zxuno\
 install-firmware-zxdos\
 install-firmware-zxdosplus\
 install-firmware-buryak\
 install-firmware-unoxt\
 install-firmware-v4

.PHONY: uninstall-firmwares
uninstall-firmwares:\
 uninstall-firmware-zxuno\
 uninstall-firmware-zxdos\
 uninstall-firmware-zxdosplus\
 uninstall-firmware-buryak\
 uninstall-firmware-unoxt\
 uninstall-firmware-v4

.PHONY: clean-firmwares
clean-firmwares:\
 clean-firmware-zxuno\
 clean-firmware-zxdos\
 clean-firmware-zxdosplus\
 clean-firmware-buryak\
 clean-firmware-unoxt\
 clean-firmware-v4
	$(RM) firmware-new.asm strings-new.asm

#-----------------------------------------------------------------------------
# install

.PHONY: install
install:\
 install-firmwares

#-----------------------------------------------------------------------------
# uninstall

.PHONY: uninstall
uninstall:\
 uninstall-firmwares

#-----------------------------------------------------------------------------
# clean

.PHONY: clean
clean:\
 clean-keymaps\
 clean-images\
 clean-firmwares

#-----------------------------------------------------------------------------
# distclean

.PHONY: distclean
distclean:
	$(RM) -r build
