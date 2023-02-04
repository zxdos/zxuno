# zx7b.inc.mk - script to build zx7b tools.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

.PHONY: $(foreach a,build install uninstall clean distclean,$(a)-zx7b)

ifeq ($(_DoBuild),1)

build-zx7b: | zx7b
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix))

install-zx7b: | zx7b
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

else	# !_DoBuild

build-zx7b install-zx7b:;

endif	# !_DoBuild

ifeq ($(_DoClean),1)

uninstall-zx7b: | zx7b
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

clean-zx7b: | zx7b
	$(MAKE) -w -C $| clean

distclean-zx7b: | zx7b
	$(MAKE) -w -C $| distclean

else	# !_DoClean

uninstall-zx7b clean-zx7b distclean-zx7b:;

endif	# !_DoClean
