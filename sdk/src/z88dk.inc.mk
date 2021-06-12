# z88dk.inc.mk - script to download and build original Z88DK.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

$(DOWNLOADS)/z88dk:
	mkdir -p $@

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-z88dk)

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

build-z88dk install-z88dk: z88dk/.done

ifeq ($(_DoBuild),1)

Z88DK_ARCHIVE		= $(DOWNLOADS)/z88dk/z88dk-src-2.1.tgz
Z88DK_ARCHIVE_SHA256	= f3579ee59b4af552721173165af38223b115ccb67179e79d2f3c0ae64338dc7c
Z88DK_ARCHIVE_TYPE	= .tar.gz
Z88DK_ARCHIVE_SUBDIR	= z88dk

# Force Win32 build for Windows
ifeq ($(OS),Windows_NT)
export CC=i686-w64-mingw32-gcc
endif

z88dk/.done: | z88dk/.extracted z88dk.mk
	$(MAKE) -w -C z88dk -f ../z88dk.mk
	cd z88dk/bin && test x $(patsubst %,-a -x %,$(Z88DK_BINS))
	touch $@

z88dk/.extracted: $(Z88DK_ARCHIVE) | z88dk.patch
	rm -rf $(@D)
	extract.sh $<\
	 --sha256 $(Z88DK_ARCHIVE_SHA256)\
	 --type $(Z88DK_ARCHIVE_TYPE)\
	 --subdir $(Z88DK_ARCHIVE_SUBDIR)\
	 --output $(@D)
	patch -N -p0 -s <$| || true
	touch $@

$(DOWNLOADS)/z88dk/z88dk-src-2.1.tgz: | $(DOWNLOADS)/z88dk
	wget -c https://github.com/z88dk/z88dk/releases/download/v2.1/$(@F) -O $@

uninstall-z88dk:;

ifeq ($(_DoClean),1)

# This does not work:
#clean-z88dk: | z88dk.mk
#	if test -d z88dk; then $(MAKE) -w -C z88dk -f ../z88dk.mk clean && rm -f z88dk/.done; fi
clean-z88dk:
	rm -rf z88dk

else	#  !_DoClean

clean-z88dk:;

endif	#  !_DoClean
endif	# _DoBuild

ifeq ($(_UsePrecompiledOnWindows),1)

ifeq ($(PROCESSOR_ARCHITECTURE),X86)
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
else
 $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
endif

Z88DK_ARCHIVE		= $(DOWNLOADS)/z88dk/z88dk-win32-2.1.zip
Z88DK_ARCHIVE_SHA256	= f4abedfae429ea159e388b5c76758ace4dcb86e9a00dbd928862b0a30f6874d6
Z88DK_ARCHIVE_TYPE	= .zip
Z88DK_ARCHIVE_SUBDIR	= z88dk

z88dk/.done: $(Z88DK_ARCHIVE)
	rm -rf $(@D)
	extract.sh $<\
	 --sha256 $(Z88DK_ARCHIVE_SHA256)\
	 --type $(Z88DK_ARCHIVE_TYPE)\
	 --subdir $(Z88DK_ARCHIVE_SUBDIR)\
	 --output $(@D)
	touch $@

$(DOWNLOADS)/z88dk/z88dk-win32-2.1.zip: | $(DOWNLOADS)/z88dk
	wget -c https://github.com/z88dk/z88dk/releases/download/v2.1/$(@F) -O $@

uninstall-z88dk:;

ifeq ($(_DoClean),1)

clean-z88dk:
	rm -rf z88dk

else	#  !_DoClean

clean-z88dk:;

endif	#  !_DoClean
endif	# _UsePrecompiledOnWindows

ifeq ($(_DoClean),1)

distclean-z88dk: clean-z88dk
	rm -rf $(DOWNLOADS)/z88dk

else	# !_DoClean

distclean-z88dk:;

endif	# !_DoClean
