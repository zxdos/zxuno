# lodepng.inc.mk - script to build LodePNG.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-lodepng)

ifeq ($(_DoBuild),1)

build-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix))

install-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

else	# !_DoBuild

build-lodepng:;

install-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install-headers

endif	# !_DoBuild

ifeq ($(_DoClean),1)

uninstall-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

clean-lodepng: | lodepng
	$(MAKE) -w -C $| clean

distclean-lodepng: | lodepng
	$(MAKE) -w -C $| distclean

else	# !_DoClean

uninstall-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall-headers

clean-lodepng distclean-lodepng:;

endif	# !_DoClean
