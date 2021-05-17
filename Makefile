# Updates content of SD directory.
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make
# Clean:
#   make clean
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

include sdk/common.mk

# Use uppercase for FAT filesystem
prefix		?= SD
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/BIN

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)
RM		= rm -f

SOFTWARE_TARGETS=\
 ESPRST\
 IWCONFIG

.PHONY: all
all:\
 install-utils\
 install-software
	@echo 'Done.'

# utils

.PHONY: install-utils
install-utils: | utils
	$(MAKE) -w -C $| bindir=$(shell realpath --relative-to=$| $(bindir)) install

.PHONY: clean-utils
clean-utils: | utils
	$(MAKE) -w -C $| clean

.PHONY: uninstall-utils
uninstall-utils: clean-utils | utils
	$(MAKE) -w -C $| bindir=$(shell realpath --relative-to=$| $(bindir)) uninstall

# software

.PHONY: install-software
install-software: $(foreach t,$(SOFTWARE_TARGETS),$(DESTDIR)$(bindir)/$(t))

$(DESTDIR)$(bindir)/ESPRST: software/esprst/esprst
	$(INSTALL) $< $@

$(DESTDIR)$(bindir)/IWCONFIG: software/iwconfig/IWCONFIG
	$(INSTALL) $< $@

software/esprst/esprst: | software/esprst
	$(MAKE) -w -C $|

software/iwconfig/IWCONFIG: | software/iwconfig
	$(MAKE) -w -C $|

.PHONY: clean-software
clean-software: |\
 software/esprst\
 software/iwconfig
	$(MAKE) -w -C software/esprst clean
	$(MAKE) -w -C software/iwconfig clean

.PHONY: uninstall-software
uninstall-software: clean-software
	$(RM) $(foreach t,$(SOFTWARE_TARGETS),$(DESTDIR)$(bindir)/$(t))

# clean

.PHONY: clean
clean:\
 uninstall-utils\
 uninstall-software
