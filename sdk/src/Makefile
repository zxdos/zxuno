# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [<TARGET>]
# Clean:
#   make [BUILD=<BUILD>] [FORCECLEAN=<FC_FLAG>] clean|dist-clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of:
#     * external-sjasmplus
#     * external-z88dk
#     * local-zx7b
#     * local-tools
#
# Notes:
#   BUILD, FORCEBUILD, FORCECLEAN variables may be set in user's environment.

include ../common.mk

INSTALLDIR=../bin

.PHONY: all
all:\
 external-sjasmplus\
 external-z88dk\
 local-zx7b\
 local-tools

_DoBuild:=1
_UsePrecompiledOnWindows:=0

ifeq ($(OS),Windows_NT)
ifneq ($(FORCEBUILD),1)
_DoBuild:=0
_UsePrecompiledOnWindows:=1
endif
endif

_DoClean:=1
ifeq ($(OS),Windows_NT)
ifneq ($(FORCECLEAN),1)
_DoClean:=0
endif
endif

# sjasmplus

.PHONY: external-sjasmplus clean-sjasmplus

external-sjasmplus: $(INSTALLDIR)/sjasmplus$(EXESUFFIX)

ifeq ($(_DoBuild),1)

$(INSTALLDIR)/sjasmplus$(EXESUFFIX): sjasmplus/build/sjasmplus$(EXESUFFIX)
	cp $< $@

sjasmplus/build/sjasmplus$(EXESUFFIX): | sjasmplus/.extracted sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk

sjasmplus/.extracted: sjasmplus-src.tgz
	echo 'f3f6d28af19880ed2cb427b6b427e9bd42371929c7d263dac840fb71de1302d6  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf $(@D) sjasmplus-20190306.1
	tar -xzf $<
	mv sjasmplus-20190306.1 $(@D)
	touch $@

sjasmplus-src.tgz:
	wget -c https://github.com/sjasmplus/sjasmplus/archive/refs/tags/20190306.1.tar.gz -O $@

clean-sjasmplus:
	if test -d sjasmplus; then $(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean; fi
	rm -f $(INSTALLDIR)/sjasmplus$(EXESUFFIX)

endif

ifeq ($(_UsePrecompiledOnWindows),1)

$(INSTALLDIR)/sjasmplus$(EXESUFFIX): sjasmplus/sjasmplus$(EXESUFFIX)
	cp $< $@

sjasmplus/sjasmplus$(EXESUFFIX): | sjasmplus/.extracted

ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
SJASMPLUS_ARCHIVE		:= sjasmplus-win64.7z
SJASMPLUS_ARCHIVE_SHA256	:= ef352b50ce7c9e9971c6fc3143e378d3e9f4069f11eb0c33022195c6e9b34fcb
else
SJASMPLUS_ARCHIVE		:= sjasmplus-win32.7z
SJASMPLUS_ARCHIVE_SHA256	:= c84731640930afc4f4cc3c0f30f891916b9b77d63dc0e4cfdcd226682b8545b1
endif

sjasmplus/.extracted: $(SJASMPLUS_ARCHIVE)
	echo '$(SJASMPLUS_ARCHIVE_SHA256)  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf $(@D)
	7z x -bd -o$(@D) $<
	touch $@

sjasmplus-win32.7z:
	wget -c https://github.com/sjasmplus/sjasmplus/releases/download/20190306.1/sjasmplus-win32-20190306.1.7z -O $@

sjasmplus-win64.7z:
	wget -c https://github.com/sjasmplus/sjasmplus/releases/download/20190306.1/sjasmplus-win64-20190306.1.7z -O $@

clean-sjasmplus:
	rm -rf sjasmplus
	rm -f $(INSTALLDIR)/sjasmplus$(EXESUFFIX)

endif

.PHONY: dist-clean-sjasmplus
dist-clean-sjasmplus:
	rm -rf sjasmplus
	rm -f $(INSTALLDIR)/sjasmplus$(EXESUFFIX)
	rm -f\
 sjasmplus-src.tgz\
 sjasmplus-src.tgz.sha256\
 sjasmplus-win32.7z\
 sjasmplus-win32.7z.sha256\
 sjasmplus-win64.7z\
 sjasmplus-win64.7z.sha256

# z88dk

.PHONY: external-z88dk clean-z88dk

Z88DK_TARGETS:=\
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

external-z88dk: z88dk/.done

ifeq ($(_DoBuild),1)

# Force Win32 build for Windows
ifeq ($(OS),Windows_NT)
export CC=i686-w64-mingw32-gcc
endif

z88dk/.done: | z88dk/.extracted z88dk.mk
	$(MAKE) -w -C z88dk -f ../z88dk.mk
	cd z88dk/bin && test x $(patsubst %,-a -x %,$(Z88DK_TARGETS))
	touch $@

z88dk/.extracted: z88dk-src.tgz
	echo 'f3579ee59b4af552721173165af38223b115ccb67179e79d2f3c0ae64338dc7c  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf z88dk
	tar -xzf $<
	patch -N -p0 -s <z88dk.patch || true
	touch $@

z88dk-src.tgz:
	wget -c https://github.com/z88dk/z88dk/releases/download/v2.1/z88dk-src-2.1.tgz -O $@

# This does not work:
#clean-z88dk: | z88dk.mk
#	if test -d z88dk; then $(MAKE) -w -C z88dk -f ../z88dk.mk clean && rm -f z88dk/.done; fi
clean-z88dk:
	rm -rf z88dk

endif

ifeq ($(_UsePrecompiledOnWindows),1)

z88dk/.done: z88dk-win32.zip
	echo 'f4abedfae429ea159e388b5c76758ace4dcb86e9a00dbd928862b0a30f6874d6  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf z88dk
	unzip -nq $<
	touch $@

z88dk-win32.zip:
	wget -c https://github.com/z88dk/z88dk/releases/download/v2.1/z88dk-win32-2.1.zip -O $@

clean-z88dk:
	rm -rf z88dk

endif

.PHONY: dist-clean-z88dk
dist-clean-z88dk:
	rm -rf z88dk
	rm -f\
 z88dk-src.tgz\
 z88dk-src.tgz.sha256\
 z88dk-win32.zip\
 z88dk-win32.zip.sha256

# zx7b

.PHONY: local-zx7b clean-zx7b

local-zx7b: $(INSTALLDIR)/zx7b$(EXESUFFIX)

ifeq ($(_DoBuild),1)

$(INSTALLDIR)/zx7b$(EXESUFFIX): zx7b/zx7b$(EXESUFFIX)
	cp $< $@

zx7b/zx7b$(EXESUFFIX): | zx7b
	$(MAKE) -w -C $|

clean-zx7b: | zx7b
	$(MAKE) -w -C $| clean
	rm -f $(INSTALLDIR)/zx7b$(EXESUFFIX)

else

clean-zx7b:;

endif

.PHONY: dist-clean-zx7b
dist-clean-zx7b: clean-zx7b

# tools

INSTALLED_TOOLS:=\
 $(INSTALLDIR)/bin2hex$(EXESUFFIX)\
 $(INSTALLDIR)/fcut$(EXESUFFIX)\
 $(INSTALLDIR)/fpad$(EXESUFFIX)\
 $(INSTALLDIR)/fpoke$(EXESUFFIX)\
 $(INSTALLDIR)/rcs$(EXESUFFIX)\
 $(INSTALLDIR)/GenRom$(EXESUFFIX)\
 $(INSTALLDIR)/AddItem$(EXESUFFIX)\
 $(INSTALLDIR)/Bit2Bin$(EXESUFFIX)

.PHONY: local-tools clean-tools

local-tools: $(INSTALLED_TOOLS)

ifeq ($(_DoBuild),1)

$(INSTALLDIR)/bin2hex$(EXESUFFIX): tools/bin2hex$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/fcut$(EXESUFFIX): tools/fcut$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/fpad$(EXESUFFIX): tools/fpad$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/fpoke$(EXESUFFIX): tools/fpoke$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/rcs$(EXESUFFIX): tools/rcs$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/GenRom$(EXESUFFIX): tools/GenRom$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/AddItem$(EXESUFFIX): tools/AddItem$(EXESUFFIX)
	cp $< $@

$(INSTALLDIR)/Bit2Bin$(EXESUFFIX): tools/Bit2Bin$(EXESUFFIX)
	cp $< $@

tools/%$(EXESUFFIX): | tools
	$(MAKE) -w -C $| $(@F)

clean-tools: | tools
	$(MAKE) -w -C $| clean
	rm -f $(INSTALLED_TOOLS)

else

clean-tools:;

endif

.PHONY: dist-clean-tools
dist-clean-tools: clean-tools

.PHONY: clean
ifeq ($(_DoClean),1)
clean: clean-sjasmplus clean-z88dk clean-zx7b clean-tools
else
clean: clean-sjasmplus clean-z88dk
endif

.PHONY: dist-clean
ifeq ($(_DoClean),1)
dist-clean: dist-clean-sjasmplus dist-clean-z88dk dist-clean-zx7b dist-clean-tools
else
dist-clean: dist-clean-sjasmplus dist-clean-z88dk
endif
