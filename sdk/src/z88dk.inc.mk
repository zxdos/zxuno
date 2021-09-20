# z88dk.inc.mk - script to download and build original Z88DK.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

$(DOWNLOADS)/z88dk \
z88dk:
	mkdir -p $@

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-z88dk)

ifeq ($(USE_Z88DK_VERSION),2.1)
 Z88DK_BINS:=\
  asmpp.pl\
  sccz80$(EXESUFFIX)\
  z80asm$(EXESUFFIX)\
  z88dk-appmake$(EXESUFFIX)\
  z88dk-basck$(EXESUFFIX)\
  z88dk-copt$(EXESUFFIX)\
  z88dk-dis$(EXESUFFIX)\
  z88dk-dzx7$(EXESUFFIX)\
  z88dk-font2pv1000$(EXESUFFIX)\
  z88dk-lib$(EXESUFFIX)\
  z88dk-ticks$(EXESUFFIX)\
  z88dk-ucpp$(EXESUFFIX)\
  z88dk-z80asm$(EXESUFFIX)\
  z88dk-z80nm$(EXESUFFIX)\
  z88dk-z80svg$(EXESUFFIX)\
  z88dk-zcpp$(EXESUFFIX)\
  z88dk-zobjcopy$(EXESUFFIX)\
  z88dk-zpragma$(EXESUFFIX)\
  z88dk-zx7$(EXESUFFIX)\
  zcc$(EXESUFFIX)
else
 $(error Unknown Z88DK version: "$(USE_Z88DK_VERSION)")
endif

ifeq ($(_DoBuild),1)

ifeq ($(USE_Z88DK_VERSION),2.1)
 Z88DK_ARCHIVE		= z88dk-src-2.1.tgz
 Z88DK_ARCHIVE_URL	= https://github.com/z88dk/z88dk/releases/download/v2.1/$(Z88DK_ARCHIVE)
 Z88DK_ARCHIVE_SHA256	= f3579ee59b4af552721173165af38223b115ccb67179e79d2f3c0ae64338dc7c
 Z88DK_ARCHIVE_TYPE	= .tar.gz
 Z88DK_ARCHIVE_SUBDIR	= z88dk
else
 $(error Unknown Z88DK version: "$(USE_Z88DK_VERSION)")
endif

# Force Win32 build for Windows
ifeq ($(OS),Windows_NT)
 export CC=i686-w64-mingw32-gcc
endif

$(DOWNLOADS)/z88dk/$(Z88DK_ARCHIVE): | $(DOWNLOADS)/z88dk
	wget -c $(Z88DK_ARCHIVE_URL) -O $@

$(Z88DK)/.extracted: $(DOWNLOADS)/z88dk/$(Z88DK_ARCHIVE)
	$(RM) -r $(Z88DK)
	extract.sh $<\
	 --sha256 $(Z88DK_ARCHIVE_SHA256)\
	 --type $(Z88DK_ARCHIVE_TYPE)\
	 --subdir $(Z88DK_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $(Z88DK)/.extracted

$(Z88DK)/z88dk.patch: z88dk.patch
	cp $< $@

$(Z88DK)/.built: $(Z88DK)/.extracted $(Z88DK)/z88dk.patch z88dk.mk
	patch -d $(<D) -N -p0 -s <z88dk.patch || true
	$(MAKE) -w -f z88dk.mk
	cd $(@D)/bin && test x $(patsubst %,-a -x %,$(Z88DK_BINS))
	touch $@

$(Z88DK)/.installed: $(Z88DK)/.built
	touch $@

build-z88dk install-z88dk: $(Z88DK)/.installed

uninstall-z88dk:
	$(RM) -r $(Z88DK)

ifeq ($(_DoClean),1)

# This does not work for Z88DK version 2.1:
#clean-z88dk: z88dk.mk
#	if test -d $(Z88DK); then $(MAKE) -w $< clean && $(RM) $(Z88DK)/.built; fi

clean-z88dk:;

else	#  !_DoClean

clean-z88dk:;

endif	#  !_DoClean
endif	# _DoBuild

ifeq ($(_UsePrecompiledOnWindows),1)

ifeq ($(PROCESSOR_ARCHITECTURE),X86)
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
else
 $(warning Unsupported processor architecture: "$(PROCESSOR_ARCHITECTURE)")
endif

ifeq ($(USE_Z88DK_VERSION),2.1)
 Z88DK_ARCHIVE		= z88dk-win32-2.1.zip
 Z88DK_ARCHIVE_URL	= https://github.com/z88dk/z88dk/releases/download/v2.1/$(Z88DK_ARCHIVE)
 Z88DK_ARCHIVE_SHA256	= f4abedfae429ea159e388b5c76758ace4dcb86e9a00dbd928862b0a30f6874d6
 Z88DK_ARCHIVE_TYPE	= .zip
 Z88DK_ARCHIVE_SUBDIR	= z88dk
else
 $(error Unknown Z88DK version: "$(USE_Z88DK_VERSION)")
endif

$(DOWNLOADS)/z88dk/$(Z88DK_ARCHIVE): | $(DOWNLOADS)/z88dk
	wget -c $(Z88DK_ARCHIVE_URL) -O $@

$(Z88DK)/.extracted: $(DOWNLOADS)/z88dk/$(Z88DK_ARCHIVE)
	$(RM) -r $(Z88DK)
	extract.sh $<\
	 --sha256 $(Z88DK_ARCHIVE_SHA256)\
	 --type $(Z88DK_ARCHIVE_TYPE)\
	 --subdir $(Z88DK_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

$(Z88DK)/.built: $(Z88DK)/.extracted
	touch $@

build-z88dk: $(Z88DK)/.built

$(Z88DK)/.installed: $(Z88DK)/.built
	touch $@

install-z88dk: $(Z88DK)/.installed

uninstall-z88dk:
	$(RM) -r $(Z88DK)

ifeq ($(_DoClean),1)

clean-z88dk:;

else	#  !_DoClean

clean-z88dk:;

endif	#  !_DoClean
endif	# _UsePrecompiledOnWindows

ifeq ($(_DoClean),1)

distclean-z88dk:
	$(RM) -r $(DOWNLOADS)/z88dk z88dk

else	# !_DoClean

distclean-z88dk:;

endif	# !_DoClean
