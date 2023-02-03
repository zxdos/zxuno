#!/bin/make -f
#
# Updates content of SD directory.
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
#   <TARGET> is one of the values for `TARGETS' variable.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021, 2023 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

include sdk/common.mk

# Use uppercase for FAT filesystem
prefix		?= SD

TARGETS=\
 fonts\
 keymaps\
 firmwares\
 utils\
 software

.PHONY: all
all: build-fonts install
	@echo 'Done.'

# fonts

.PHONY: build-fonts
build-fonts: | fonts
	$(MAKE) -w -C $|

.PHONY: install-fonts
install-fonts: | fonts
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-fonts
uninstall-fonts: | fonts
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-fonts
clean-fonts: | fonts
	$(MAKE) -w -C $| clean

.PHONY: distclean-fonts
distclean-fonts: | fonts
	$(MAKE) -w -C $| distclean

# keymaps

.PHONY: build-keymaps
build-keymaps: | cores/Spectrum/keymaps
	$(MAKE) -w -C $|

.PHONY: install-keymaps
install-keymaps: | cores/Spectrum/keymaps
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-keymaps
uninstall-keymaps: | cores/Spectrum/keymaps
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-keymaps
clean-keymaps: | cores/Spectrum/keymaps
	$(MAKE) -w -C $| clean

.PHONY: distclean-keymaps
distclean-keymaps: | cores/Spectrum/keymaps
	$(MAKE) -w -C $| distclean

# firmwares

.PHONY: build-firmwares
build-firmwares: | firmware
	$(MAKE) -w -C $|

.PHONY: install-firmwares
install-firmwares: | firmware
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-firmwares
uninstall-firmwares: | firmware
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-firmwares
clean-firmwares: | firmware
	$(MAKE) -w -C $| clean

.PHONY: distclean-firmwares
distclean-firmwares: | firmware
	$(MAKE) -w -C $| distclean

# utils

.PHONY: build-utils
build-utils: | utils
	$(MAKE) -w -C $|

.PHONY: install-utils
install-utils: | utils
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-utils
uninstall-utils: | utils
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-utils
clean-utils: | utils
	$(MAKE) -w -C $| clean

.PHONY: distclean-utils
distclean-utils: | utils
	$(MAKE) -w -C $| distclean

# software

.PHONY: build-software
build-software: | software
	$(MAKE) -w -C $|

.PHONY: install-software
install-software: | software
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-software
uninstall-software: | software
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-software
clean-software: | software
	$(MAKE) -w -C $| clean

.PHONY: distclean-software
distclean-software: | software
	$(MAKE) -w -C $| distclean

# all

.PHONY: build
build: $(foreach t,$(TARGETS),build-$(t))

.PHONY: install
install: $(foreach t,$(TARGETS),install-$(t))

.PHONY: uninstall
uninstall: $(foreach t,$(TARGETS),uninstall-$(t))

.PHONY: clean
clean: $(foreach t,$(TARGETS),clean-$(t))

.PHONY: distclean
distclean: $(foreach t,$(TARGETS),distclean-$(t))
