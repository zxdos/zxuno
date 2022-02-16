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
# SPDX-FileCopyrightText: 2021, 2022 Ivan Tatarinov
# SPDX-FileNotice: Based on code by Antonio Villena
# SPDX-License-Identifier: GPL-3.0-or-later

include ../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
keymapsdir	?= $(prefix)/SYS/KEYMAPS

INSTALL		?= install
INSTALL_DATA	?= $(INSTALL) -m 644
RM		= rm -f

INCLUDEDIR	= ../sdk/include
AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_BRANCH),sjasmplus)
 AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_BRANCH),z00m128)
 AFLAGS		= --nologo
else
 AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR)

# Each item is in form "source_filename/destination_filename"
KEYMAPS=\
 av.bin/AV\
 es.bin/ES\
 us.bin/US

FONTS=\
 chloe6x8.bin\
 fuente6x8.bin\
 fuente8x6.bin

IMAGES=$(patsubst images/%,%,$(wildcard images/*.png))

.PHONY: all
all:\
 build-keymaps\
 build-fonts\
 build-images\
 build-firmwares

build\
build/v1\
build/v2\
build/v3\
build/v4\
$(DESTDIR)$(keymapsdir):
	mkdir -p $@

#-----------------------------------------------------------------------------
# keymaps

# $(1) = source filename
define build_keymap_rule =
build/$(1:.bin=).zx7b: keymaps/$(1) | build
	zx7b $$< $$@
endef

$(foreach f,$(KEYMAPS),$(eval $(call build_keymap_rule,$(subst /,,$(dir $(f))))))

.PHONY: build-keymaps
build-keymaps: $(foreach f,$(KEYMAPS),build/$(subst .bin/,,$(dir $(f))).zx7b)

# $(1) = source filename, $(2) = destination filename
define install_keymap_rule =
$$(DESTDIR)$$(keymapsdir)/$(2): keymaps/$(1) | $$(DESTDIR)$$(keymapsdir)
	$$(INSTALL_DATA) $$< $$@
endef

$(foreach f,$(KEYMAPS),$(eval $(call install_keymap_rule,$(subst /,,$(dir $(f))),$(notdir $(f)))))

.PHONY: install-keymaps
install-keymaps: $(foreach f,$(KEYMAPS),$(DESTDIR)$(keymapsdir)/$(notdir $(f))) | $(DESTDIR)$(keymapsdir)

.PHONY: uninstall-keymaps
uninstall-keymaps:
	$(RM) $(foreach f,$(KEYMAPS),$(DESTDIR)$(keymapsdir)/$(notdir $(f)))

.PHONY: clean-keymaps
clean-keymaps:
	$(RM) $(foreach f,$(KEYMAPS),build/$(subst .bin/,,$(dir $(f))).zx7b)

.PHONY: distclean-keymaps
distclean-keymaps: clean-keymaps

#-----------------------------------------------------------------------------
# fonts

build/chloe6x8.bin: fonts/chloe6x8.png | build
	fontconv -q -f 6x8 $< $@

build/fuente6x8.bin: fonts/fuente6x8.png | build
	fontconv -q -f 6x8 $< $@

build/fuente8x6.bin: fonts/fuente6x8.png | build
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
distclean-fonts: clean-fonts

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

.PHONY: install-images
install-images:;

.PHONY: uninstall-images
uninstall-images:;

.PHONY: clean-images
clean-images:
	$(RM) $(foreach i,$(IMAGES),build/$(i:.png=.rcs) build/$(i:.png=.rcs.zx7b))

.PHONY: distclean-images
distclean-images: clean-images

#-----------------------------------------------------------------------------
# firmware version 1: ZXUNO+ with an FPGA LX16 board

build/v1/version.asm: | build/v1
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 1';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo '  define buryak 0';\
	 echo ' endif';\
	 } > $@

build/v1/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/v1/version.asm
	$(AS) $(AFLAGS) -Ibuild/v1 --raw=$@ $<

build/v1/strings.bin.zx7b: build/v1/strings.bin
	zx7b $< $@

build/v1/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 build/fuente6x8.bin\
 build/logo256x192.rcs.zx7b\
 build/v1/version.asm\
 build/v1/strings.bin.zx7b\
 | build/v1
	$(AS) $(AFLAGS) -Ibuild/v1 --raw=$@ $<

build/v1/firmware.rom: build/v1/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-v1
build-firmware-v1: | build/v1
	$(MAKE) -w build/v1/firmware.rom

.PHONY: install-firmware-v1
install-firmware-v1:;

.PHONY: uninstall-firmware-v1
uninstall-firmware-v1:;

.PHONY: clean-firmware-v1
clean-firmware-v1:
	$(RM) -r build/v1

#-----------------------------------------------------------------------------
# firmware version 2: ZXDOS+ with an FPGA LX16 board

build/v2/version.asm: | build/v2
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 2';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo '  define buryak 0';\
	 echo ' endif';\
	 } > $@

build/v2/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/v2/version.asm
	$(AS) $(AFLAGS) -Ibuild/v2 --raw=$@ $<

build/v2/strings.bin.zx7b: build/v2/strings.bin
	zx7b $< $@

build/v2/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 build/fuente6x8.bin\
 build/logo256x192d.rcs.zx7b\
 build/v2/version.asm\
 build/v2/strings.bin.zx7b\
 | build/v2
	$(AS) $(AFLAGS) -Ibuild/v2 --raw=$@ $<

build/v2/firmware.rom: build/v2/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-v2
build-firmware-v2: | build/v2
	$(MAKE) -w build/v2/firmware.rom

.PHONY: install-firmware-v2
install-firmware-v2:;

.PHONY: uninstall-firmware-v2
uninstall-firmware-v2:;

.PHONY: clean-firmware-v2
clean-firmware-v2:
	$(RM) -r build/v2

#-----------------------------------------------------------------------------
# firmware version 3: ZXDOS+ with an FPGA LX25 board

build/v3/version.asm: | build/v3
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 3';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo '  define buryak 0';\
	 echo ' endif';\
	 } > $@

build/v3/strings.bin:\
 $(srcdir)/strings-new.asm\
 build/v3/version.asm
	$(AS) $(AFLAGS) -Ibuild/v3 --raw=$@ $<

build/v3/strings.bin.zx7b: build/v3/strings.bin
	zx7b $< $@

build/v3/firmware_strings.rom:\
 $(srcdir)/firmware-new.asm\
 $(srcdir)/crctable.bin\
 $(srcdir)/sd.asm\
 build/av.zx7b\
 build/es.zx7b\
 build/us.zx7b\
 build/fuente6x8.bin\
 build/logo256x192dp.rcs.zx7b\
 build/v3/version.asm\
 build/v3/strings.bin.zx7b\
 | build/v3
	$(AS) $(AFLAGS) -Ibuild/v3 --raw=$@ $<

build/v3/firmware.rom: build/v3/firmware_strings.rom
	dd if=$< of=$@ bs=16384 count=1

.PHONY: build-firmware-v3
build-firmware-v3: | build/v3
	$(MAKE) -w build/v3/firmware.rom

.PHONY: install-firmware-v3
install-firmware-v3:;

.PHONY: uninstall-firmware-v3
uninstall-firmware-v3:;

.PHONY: clean-firmware-v3
clean-firmware-v3:
	$(RM) -r build/v3

#-----------------------------------------------------------------------------
# firmware version 4

build/v4/version.asm: | build/v4
	{\
	 echo ' ifndef VERSION_ASM';\
	 echo '  define VERSION_ASM 1';\
	 echo '  define version 3';\
	 echo '  define chloe 0';\
	 echo '  define recovery 0';\
	 echo '  define recodire 0';\
	 echo '  define zesarux 0';\
	 echo '  define vertical 0';\
	 echo '  define buryak 0';\
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
 build/fuente6x8.bin\
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
 build-firmware-v1\
 build-firmware-v2\
 build-firmware-v3\
 build-firmware-v4

.PHONY: install-firmwares
install-firmwares:\
 install-firmware-v1\
 install-firmware-v2\
 install-firmware-v3\
 install-firmware-v4

.PHONY: uninstall-firmwares
uninstall-firmwares:\
 uninstall-firmware-v1\
 uninstall-firmware-v2\
 uninstall-firmware-v3\
 uninstall-firmware-v4

.PHONY: clean-firmwares
clean-firmwares:\
 clean-firmware-v1\
 clean-firmware-v2\
 clean-firmware-v3\
 clean-firmware-v4

#-----------------------------------------------------------------------------
# install

.PHONY: install
install:\
 install-keymaps\
 install-fonts\
 install-images\
 install-firmwares

#-----------------------------------------------------------------------------
# uninstall

.PHONY: uninstall
uninstall:\
 uninstall-keymaps\
 uninstall-fonts\
 uninstall-images\
 uninstall-firmwares

#-----------------------------------------------------------------------------
# clean

.PHONY: clean
clean:\
 clean-keymaps\
 clean-fonts\
 clean-images\
 clean-firmwares

#-----------------------------------------------------------------------------
# distclean

.PHONY: distclean
distclean:
	$(RM) -r build
