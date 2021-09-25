# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
# SPDX-FileNotice: Based on code by Antonio Villena <espineter@yahoo.com>
# SPDX-License-Identifier: GPL-3.0-or-later
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
 build-images

build\
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
	rm -f $(foreach f,$(KEYMAPS),build/$(subst .bin/,,$(dir $(f))).zx7b)

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
	rm -f $(foreach f,$(FONTS),build/$(f))

.PHONY: distclean-fonts
distclean-fonts: clean-fonts

#-----------------------------------------------------------------------------
# images

# $(1) = source filename
define build_image_rule =
build/$(1:.png=.rcs): images/$(1) $(wildcard images/$(1:.png=.atr)) | build
 ifneq ($(wildcard images/$(1:.png=.atr)),)
	Png2Rcs $$< $$@ -a images/$(1:.png=.atr)
 else
	Png2Rcs $$< $$@
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
	rm -f $(foreach i,$(IMAGES),build/$(i:.png=.rcs) build/$(i:.png=.rcs.zx7b))

.PHONY: distclean-images
distclean-images: clean-images

#-----------------------------------------------------------------------------
# install

.PHONY: install
install:\
 install-keymaps\
 install-fonts\
 install-images

#-----------------------------------------------------------------------------
# uninstall

.PHONY: uninstall
uninstall:\
 uninstall-keymaps\
 uninstall-fonts\
 uninstall-images

#-----------------------------------------------------------------------------
# clean

.PHONY: clean
clean:\
 clean-keymaps\
 clean-fonts\
 clean-images

#-----------------------------------------------------------------------------
# distclean

.PHONY: distclean
distclean:
	rm -rf build
