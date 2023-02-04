# sjasmplus-z00m128.inc.mk - script to download and build SJAsmPlus by aprisobal.
#
# This file is a part of main Makefile.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021-2023 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

$(DOWNLOADS)/sjasmplus-z00m128:
	mkdir -p $@

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-sjasmplus)

ifeq ($(_DoBuild),1)

 ifeq ($(USE_SJASMPLUS_VERSION),1.18.2)

SJASMPLUS_ARCHIVE		= v1.18.2.tar.gz
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/archive/refs/tags/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 114807bf53d3526b4d1ae7d40f3050b9ee98220df74931efc1e6d1fe5aba3d02
SJASMPLUS_ARCHIVE_TYPE		= .tar.gz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.2

 else ifeq ($(USE_SJASMPLUS_VERSION),1.18.3)

SJASMPLUS_ARCHIVE		= v1.18.3.tar.gz
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/archive/refs/tags/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= ce0707070946e3439756c0577dd9c4b16a1a4b75cc8bbf1b2be9c6638957be85
SJASMPLUS_ARCHIVE_TYPE		= .tar.gz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.3

 else ifeq ($(USE_SJASMPLUS_VERSION),1.19.0)

SJASMPLUS_ARCHIVE		= v1.19.0.tar.gz
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/archive/refs/tags/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 3f71b256bde11dbe034c0f18587c7a0b5bcbd8f9ebd124672d135342439b124a
SJASMPLUS_ARCHIVE_TYPE		= .tar.gz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.19.0

 else ifeq ($(USE_SJASMPLUS_VERSION),1.20.0)

SJASMPLUS_ARCHIVE		= sjasmplus-1.20.0-src.tar.xz
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.20.0/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 37c01c4ee34e22ce11f7359ff42759368a5b3745f1fb9e4ede862026c0ca598a
SJASMPLUS_ARCHIVE_TYPE		= .tar.xz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.20.0

 else ifeq ($(USE_SJASMPLUS_VERSION),1.20.1)

SJASMPLUS_ARCHIVE		= sjasmplus-1.20.1-src.tar.xz
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.20.1/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= a4a024917d971c6afc98ec09c3b1222a0cc31378f3522528d11ea4f26bfa51aa
SJASMPLUS_ARCHIVE_TYPE		= .tar.xz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.20.1

 else ifeq ($(USE_SJASMPLUS_VERSION),current)

SJASMPLUS_ARCHIVE		= master.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/archive/refs/heads/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-master

 else
  $(error Unknown SJAsmPlus version selected: $(USE_SJASMPLUS_VERSION))
 endif

ifeq ($(USE_SJASMPLUS_VERSION),current)

$(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE): | $(DOWNLOADS)/sjasmplus-z00m128
	wget $(SJASMPLUS_ARCHIVE_URL) -O $@

sjasmplus-z00m128/.extracted: $(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE)
	$(RM) -r $(@D)
	extract.sh $<\
	 --type $(SJASMPLUS_ARCHIVE_TYPE)\
	 --subdir $(SJASMPLUS_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

else

$(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE): | $(DOWNLOADS)/sjasmplus-z00m128
	wget -c $(SJASMPLUS_ARCHIVE_URL) -O $@

sjasmplus-z00m128/.extracted: $(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE)
	$(RM) -r $(@D)
	extract.sh $<\
	 --sha256 $(SJASMPLUS_ARCHIVE_SHA256)\
	 --type $(SJASMPLUS_ARCHIVE_TYPE)\
	 --subdir $(SJASMPLUS_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

endif

build-sjasmplus: | sjasmplus-z00m128/.extracted sjasmplus-z00m128.mk
	$(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix))

install-sjasmplus: | sjasmplus-z00m128/.extracted sjasmplus-z00m128.mk
	$(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix)) install

ifeq ($(_DoClean),1)

uninstall-sjasmplus: | sjasmplus-z00m128.mk
	if test -d sjasmplus-z00m128; then\
		$(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix)) uninstall;\
	else\
		$(RM) $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX);\
	fi

clean-sjasmplus: | sjasmplus-z00m128.mk
	if test -d sjasmplus-z00m128; then $(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk clean; fi

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _DoBuild

#-----------------------------------------------------------------------------

ifeq ($(_UsePrecompiledOnWindows),1)

build-sjasmplus: sjasmplus-z00m128/sjasmplus$(EXESUFFIX)

sjasmplus-z00m128/sjasmplus$(EXESUFFIX): | sjasmplus-z00m128/.extracted

ifeq ($(PROCESSOR_ARCHITECTURE),X86)
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
else
 $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
endif

 ifeq ($(USE_SJASMPLUS_VERSION),1.18.2)

SJASMPLUS_ARCHIVE		= sjasmplus-1.18.2.win.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.18.2/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 848bca2522d6febbf3e3c48c634731ecd61899166f5922ed15857e8063c3dc4b
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.2.win

 else ifeq ($(USE_SJASMPLUS_VERSION),1.18.3)

SJASMPLUS_ARCHIVE		= sjasmplus-1.18.3.win.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.18.3/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 62a833089179ad86d3e028dfdd23e8031bff40f0d2658188378081cf0ac20eda
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.3.win

 else ifeq ($(USE_SJASMPLUS_VERSION),1.19.0)

SJASMPLUS_ARCHIVE		= sjasmplus-1.19.0.win.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.19.0/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 38aed2d67b99cfbec94c0b5be258f312063a5a9ec62b4f315e749e553d01bbcb
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.19.0.win

 else ifeq ($(USE_SJASMPLUS_VERSION),1.20.0)

SJASMPLUS_ARCHIVE		= sjasmplus-1.20.0.win.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.20.0/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= abe675817aa1a117d01401d6e700476f09f0ec77242b6918962e50952905f0d7
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.20.0.win

 else ifeq ($(USE_SJASMPLUS_VERSION),1.20.1)

SJASMPLUS_ARCHIVE		= sjasmplus-1.20.1.win.zip
SJASMPLUS_ARCHIVE_URL		= https://github.com/z00m128/sjasmplus/releases/download/v1.20.1/$(SJASMPLUS_ARCHIVE)
SJASMPLUS_ARCHIVE_SHA256	= 3d7921a38e246ace3a7befe5e730fb615a64732414dbf14f36e3f2b2b40afdab
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.20.1.win

 else ifeq ($(USE_SJASMPLUS_VERSION),current)
  $(error There is no current precompiled SJAsmPlus version for Windows NT)
 else
  $(error Unknown SJAsmPlus version selected: $(USE_SJASMPLUS_VERSION))
 endif

$(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE): | $(DOWNLOADS)/sjasmplus-z00m128
	wget -c $(SJASMPLUS_ARCHIVE_URL) -O $@

sjasmplus-z00m128/.extracted: $(DOWNLOADS)/sjasmplus-z00m128/$(SJASMPLUS_ARCHIVE)
	$(RM) -r $(@D)
	extract.sh $<\
	 --sha256 $(SJASMPLUS_ARCHIVE_SHA256)\
	 --type $(SJASMPLUS_ARCHIVE_TYPE)\
	 --subdir $(SJASMPLUS_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): sjasmplus-z00m128/sjasmplus$(EXESUFFIX) | $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $< $@

install-sjasmplus: $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

ifeq ($(_DoClean),1)

uninstall-sjasmplus:
	$(RM) $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

clean-sjasmplus:
	$(RM) -r sjasmplus-z00m128

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _UsePrecompiledOnWindows

ifeq ($(_DoClean),1)

distclean-sjasmplus:
	$(RM) -r $(DOWNLOADS)/sjasmplus-z00m128
	$(RM) -r sjasmplus-z00m128

else	# !_DoClean

distclean-sjasmplus:;

endif	# !_DoClean
