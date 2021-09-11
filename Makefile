# Updates content of SD directory.
#
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
#   <TARGET> is one of the values for `TARGETS' variable.

include sdk/common.mk

# Use uppercase for FAT filesystem
prefix		?= SD

TARGETS=\
 keymaps\
 utils\
 software

.PHONY: all
all: install
	@echo 'Done.'

# keymaps

.PHONY: build-keymaps
build-keymaps: | firmware
	$(MAKE) -w -C $|

.PHONY: install-keymaps
install-keymaps: | firmware
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

.PHONY: uninstall-keymaps
uninstall-keymaps: | firmware
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

.PHONY: clean-keymaps
clean-keymaps: | firmware
	$(MAKE) -w -C $| clean

.PHONY: distclean-keymaps
distclean-keymaps: | firmware
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
