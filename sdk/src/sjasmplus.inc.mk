# sjasmplus.inc.mk - script to download and build original SJAsmPlus.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

.downloads/sjasmplus:
	mkdir -p $@

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-sjasmplus)

ifeq ($(_DoBuild),1)

SJASMPLUS_ARCHIVE		= .downloads/sjasmplus/20190306.1.tar.gz
SJASMPLUS_ARCHIVE_SHA256	= f3f6d28af19880ed2cb427b6b427e9bd42371929c7d263dac840fb71de1302d6
SJASMPLUS_ARCHIVE_TYPE		= .tar.gz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-20190306.1

build-sjasmplus: | sjasmplus/.extracted sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix))

sjasmplus/.extracted: $(SJASMPLUS_ARCHIVE)
	rm -rf $(@D)
	extract.sh $<\
	 --sha256 $(SJASMPLUS_ARCHIVE_SHA256)\
	 --type $(SJASMPLUS_ARCHIVE_TYPE)\
	 --subdir $(SJASMPLUS_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

.downloads/sjasmplus/20190306.1.tar.gz: | .downloads/sjasmplus
	wget -c https://github.com/sjasmplus/sjasmplus/archive/refs/tags/$(@F) -O $@

install-sjasmplus: | sjasmplus/.extracted sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix)) install

ifeq ($(_DoClean),1)

uninstall-sjasmplus: | sjasmplus.mk
	if test -d sjasmplus; then\
		$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix)) uninstall;\
	else\
		rm -f $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX);\
	fi

clean-sjasmplus: | sjasmplus.mk
	if test -d sjasmplus; then $(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean; fi

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _DoBuild

ifeq ($(_UsePrecompiledOnWindows),1)

build-sjasmplus: sjasmplus/sjasmplus$(EXESUFFIX)

sjasmplus/sjasmplus$(EXESUFFIX): | sjasmplus/.extracted

ifeq ($(PROCESSOR_ARCHITECTURE),X86)
 SJASMPLUS_ARCHIVE		= .downloads/sjasmplus/sjasmplus-win32-20190306.1.7z
 SJASMPLUS_ARCHIVE_SHA256	= c84731640930afc4f4cc3c0f30f891916b9b77d63dc0e4cfdcd226682b8545b1
 SJASMPLUS_ARCHIVE_TYPE		= .7z
 SJASMPLUS_ARCHIVE_SUBDIR	= .
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
 SJASMPLUS_ARCHIVE		= .downloads/sjasmplus/sjasmplus-win64-20190306.1.7z
 SJASMPLUS_ARCHIVE_SHA256	= ef352b50ce7c9e9971c6fc3143e378d3e9f4069f11eb0c33022195c6e9b34fcb
 SJASMPLUS_ARCHIVE_TYPE		= .7z
 SJASMPLUS_ARCHIVE_SUBDIR	= .
else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
 SJASMPLUS_ARCHIVE		= .downloads/sjasmplus/sjasmplus-win64-20190306.1.7z
 SJASMPLUS_ARCHIVE_SHA256	= ef352b50ce7c9e9971c6fc3143e378d3e9f4069f11eb0c33022195c6e9b34fcb
 SJASMPLUS_ARCHIVE_TYPE		= .7z
 SJASMPLUS_ARCHIVE_SUBDIR	= .
else
 $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
 SJASMPLUS_ARCHIVE		= .downloads/sjasmplus/sjasmplus-win32-20190306.1.7z
 SJASMPLUS_ARCHIVE_SHA256	= c84731640930afc4f4cc3c0f30f891916b9b77d63dc0e4cfdcd226682b8545b1
 SJASMPLUS_ARCHIVE_TYPE		= .7z
 SJASMPLUS_ARCHIVE_SUBDIR	= .
endif

sjasmplus/.extracted: $(SJASMPLUS_ARCHIVE)
	rm -rf $(@D)
	extract.sh $<\
	 --sha256 $(SJASMPLUS_ARCHIVE_SHA256)\
	 --type $(SJASMPLUS_ARCHIVE_TYPE)\
	 --subdir $(SJASMPLUS_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

.downloads/sjasmplus/sjasmplus-win32-20190306.1.7z: | .downloads/sjasmplus
	wget -c https://github.com/sjasmplus/sjasmplus/releases/download/20190306.1/$(@F) -O $@

.downloads/sjasmplus/sjasmplus-win64-20190306.1.7z: | .downloads/sjasmplus
	wget -c https://github.com/sjasmplus/sjasmplus/releases/download/20190306.1/$(@F) -O $@

install-sjasmplus: $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): sjasmplus/sjasmplus$(EXESUFFIX) | $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $< $@

ifeq ($(_DoClean),1)

uninstall-sjasmplus:
	rm -f $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

clean-sjasmplus:
	rm -rf sjasmplus

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _UsePrecompiledOnWindows

ifeq ($(_DoClean),1)

distclean-sjasmplus: clean-sjasmplus
	rm -rf .downloads/sjasmplus

else	# !_DoClean

distclean-sjasmplus:;

endif	# !_DoClean
