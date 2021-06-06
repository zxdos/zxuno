# tools.inc.mk - script to build tools.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-tools)

ifeq ($(_DoBuild),1)

build-tools: | tools
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix))

install-tools: | tools
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

else	# !_DoBuild

build-tools install-tools:;

endif	# !_DoBuild

ifeq ($(_DoClean),1)

uninstall-tools: | tools
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

clean-tools: | tools
	$(MAKE) -w -C $| clean

distclean-tools: | tools
	$(MAKE) -w -C $| distclean

else	# !_DoClean

uninstall-tools clean-tools distclean-tools:;

endif	# !_DoClean
