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

INSTALL_DIR=SD

UTILS_TARGETS=\
 BACK16M\
 BACKZX2\
 BACKZXD\
 BACKUP\
 CORCLEAN\
 COREBIOS\
 ROMSBACK\
 ROMSUPGR\
 UPGR16M\
 UPGRZX2\
 UPGRZXD\
 UPGRADE

UTILS_INSTALL_DIR=$(INSTALL_DIR)/BIN

SOFTWARE_TARGETS=\
 ESPRST\
 IWCONFIG

SOFTWARE_INSTALL_DIR=$(INSTALL_DIR)/BIN

.PHONY: all
all:\
 install-utils\
 install-software
	@echo 'Done.'

# utils

.PHONY: install-utils
install-utils: $(foreach t,$(UTILS_TARGETS),$(UTILS_INSTALL_DIR)/$(t)) | utils

# $1 = target
define utils_rule =
$$(UTILS_INSTALL_DIR)/$1: utils/build/$1 | utils
	mv $$< $$@
utils/build/$1: | utils
	$$(MAKE) -w -C $$| build/$$(@F)
endef

$(foreach t,$(UTILS_TARGETS),$(eval $(call utils_rule,$(t))))

.PHONY: clean-utils
clean-utils: | utils
	$(MAKE) -w -C $| clean

.PHONY: uninstall-utils
uninstall-utils: clean-utils
	rm -f $(foreach t,$(UTILS_TARGETS),$(UTILS_INSTALL_DIR)/$(t))

# software

.PHONY: install-software
install-software: $(foreach t,$(SOFTWARE_TARGETS),$(SOFTWARE_INSTALL_DIR)/$(t))

$(SOFTWARE_INSTALL_DIR)/ESPRST: software/esprst/esprst
	mv $< $@

$(SOFTWARE_INSTALL_DIR)/IWCONFIG: software/iwconfig/IWCONFIG
	mv $< $@

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
	rm -f $(foreach t,$(SOFTWARE_TARGETS),$(SOFTWARE_INSTALL_DIR)/$(t))

# clean

.PHONY: clean
clean:\
 uninstall-utils\
 uninstall-software
