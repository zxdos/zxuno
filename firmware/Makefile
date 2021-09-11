# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
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
ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
AFLAGS		= --nologo
else
AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR)

# Each item is in form "source/destination" ("source" must be without extension)
KEYMAPS=\
 av/AV\
 es/ES\
 us/US

.PHONY: all
all: build-keymaps

build\
$(DESTDIR)$(keymapsdir):
	mkdir -p $@

# build-keymaps

# $(1) = key map
define build_keymap_rule =
build/$(1).zx7b: keymaps/$(1).bin | build
	zx7b $$< $$@
endef

$(foreach k,$(KEYMAPS),$(eval $(call build_keymap_rule,$(subst /,,$(dir $(k))))))

.PHONY: build-keymaps
build-keymaps: $(foreach k,$(KEYMAPS),build/$(subst /,,$(dir $(k))).zx7b)

# install-keymaps

# $(1) = key map
define install_keymap_rule =
$$(DESTDIR)$$(keymapsdir)/$(2): keymaps/$(1).bin | $$(DESTDIR)$$(keymapsdir)
	$$(INSTALL) -m 644 $$< $$@
endef

$(foreach k,$(KEYMAPS),$(eval $(call install_keymap_rule,$(subst /,,$(dir $(k))),$(notdir $(k)))))

.PHONY: install-keymaps
install-keymaps: $(foreach k,$(KEYMAPS),$(DESTDIR)$(keymapsdir)/$(notdir $(k))) | $(DESTDIR)$(keymapsdir)

# uninstall-keymaps

.PHONY: uninstall-keymaps
uninstall-keymaps:
	$(RM) $(foreach k,$(KEYMAPS),$(DESTDIR)$(keymapsdir)/$(notdir $(k)))

# clean-keymaps

.PHONY: clean-keymaps
clean-keymaps:
	rm -f $(foreach k,$(KEYMAPS),build/$(subst /,,$(dir $(k))).zx7b)

# distclean-keymaps

.PHONY: distclean-keymaps
distclean-keymaps: clean-keymaps

# install

.PHONY: install
install: install-keymaps

# uninstall

.PHONY: uninstall
uninstall: uninstall-keymaps

# clean

.PHONY: clean
clean: clean-keymaps

# distclean

.PHONY: distclean
distclean:
	rm -rf build
