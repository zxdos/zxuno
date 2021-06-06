# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build the project:
#   make [all]
# Compile only:
#   make build | build-<TARGET>
# Install:
#   make install | install-<TARGET>
# Uninstall:
#   make uninstall | uninstall-<TARGET>
# Clean:
#   make clean | clean-<TARGET>
#   make distclean | distclean-<TARGET>
#
# where:
#   <TARGET> is one of the values for `SUBDIRS' variable.

include ../sdk/common.mk

# Use uppercase for FAT filesystem
prefix		?= .

SUBDIRS=\
 dmaplayw\
 esxdos\
 esprst\
 iwconfig

.PHONY: all
all: build
	@echo 'Done.'

.PHONY: $(foreach t,$(SUBDIRS),build-$(t))

define build_rule=
build-$1: | $1
	$$(MAKE) -w -C $$|
endef

$(foreach d,$(SUBDIRS),$(eval $(call build_rule,$(d))))

.PHONY: $(foreach t,$(SUBDIRS),install-$(t))

define install_rule=
install-$1: | $1
	$$(MAKE) -w -C $$| prefix=$$(shell realpath --relative-to=$$| $$(prefix)) install
endef

$(foreach d,$(SUBDIRS),$(eval $(call install_rule,$(d))))

.PHONY: $(foreach t,$(SUBDIRS),uninstall-$(t))

define uninstall_rule=
uninstall-$1: | $1
	$$(MAKE) -w -C $$| prefix=$$(shell realpath --relative-to=$$| $$(prefix)) uninstall
endef

$(foreach d,$(SUBDIRS),$(eval $(call uninstall_rule,$(d))))

.PHONY: $(foreach t,$(SUBDIRS),clean-$(t))

define clean_rule=
clean-$1: | $1
	$$(MAKE) -w -C $$| clean
endef

$(foreach d,$(SUBDIRS),$(eval $(call clean_rule,$(d))))

.PHONY: $(foreach t,$(SUBDIRS),distclean-$(t))

define distclean_rule=
distclean-$1: | $1
	$$(MAKE) -w -C $$| distclean
endef

$(foreach d,$(SUBDIRS),$(eval $(call distclean_rule,$(d))))

.PHONY: build
build: $(foreach t,$(SUBDIRS),build-$(t))

.PHONY: install
install: $(foreach t,$(SUBDIRS),install-$(t))

.PHONY: uninstall
uninstall: $(foreach t,$(SUBDIRS),uninstall-$(t))

.PHONY: clean
clean: $(foreach t,$(SUBDIRS),clean-$(t))

.PHONY: distclean
distclean: $(foreach t,$(SUBDIRS),distclean-$(t))
