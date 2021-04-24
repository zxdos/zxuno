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

.PHONY: all
all:\
 install-utils
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

# clean

.PHONY: clean
clean: uninstall-utils
