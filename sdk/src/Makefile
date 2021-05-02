# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [<FLAGS>] build | build-<TARGET>
# Install:
#   make [<FLAGS>] [all | install | install-<TARGET>]
# Uninstall:
#   make [<FLAGS>] uninstall | uninstall-<TARGET>
# Clean:
#   make [<FLAGS>] clean | clean-<TARGET>
#   make [<FLAGS>] distclean | distclean-<TARGET>
#
# where:
#   <FLAGS> are:
#     [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [FORCECLEAN=<FC_FLAG>]
# where values are:
#   <BUILD> - see included `common.mk'.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of the values of `TARGETS' variable.
#
# NOTE: `FORCEBUILD' and `FORCECLEAN' are mainly for Windows platform.

include ../common.mk

prefix		?= ..
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

TARGETS=\
 sjasmplus\
 z88dk\
 lodepng\
 zx7b\
 tools

.PHONY: all build install uninstall clean distclean
all: install
build: $(foreach t,$(TARGETS),build-$(t))
install: $(foreach t,$(TARGETS),install-$(t))
uninstall: $(foreach t,$(TARGETS),uninstall-$(t))
clean: $(foreach t,$(TARGETS),clean-$(t))
distclean: $(foreach t,$(TARGETS),distclean-$(t))

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

.PHONY: $(foreach a,build install uninstall clean distclean,$(a)-sjasmplus)

ifeq ($(_DoBuild),1)

build-sjasmplus: | sjasmplus/.extracted sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix))

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

install-sjasmplus: | sjasmplus/.extracted sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix)) install

ifeq ($(_DoClean),1)

uninstall-sjasmplus: | sjasmplus.mk
	if test -f sjasmplus; then\
		$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk prefix=$(shell realpath --relative-to=sjasmplus $(prefix)) uninstall;\
	else\
		rm -f $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX);\
	fi

clean-sjasmplus: | sjasmplus.mk
	if test -f sjasmplus; then $(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean; fi

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _DoBuild

ifeq ($(_UsePrecompiledOnWindows),1)

build-sjasmplus: sjasmplus/sjasmplus$(EXESUFFIX)

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

install-sjasmplus: $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): sjasmplus/sjasmplus$(EXESUFFIX)
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
	rm -f\
 sjasmplus-src.tgz\
 sjasmplus-src.tgz.sha256\
 sjasmplus-win32.7z\
 sjasmplus-win32.7z.sha256\
 sjasmplus-win64.7z\
 sjasmplus-win64.7z.sha256

else	# !_DoClean

distclean-sjasmplus:;

endif	# !_DoClean

# z88dk

.PHONY: $(foreach a,build install uninstall clean distclean,$(a)-z88dk)

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

# Force Win32 build for Windows
ifeq ($(OS),Windows_NT)
export CC=i686-w64-mingw32-gcc
endif

z88dk/.done: | z88dk/.extracted z88dk.mk
	$(MAKE) -w -C z88dk -f ../z88dk.mk
	cd z88dk/bin && test x $(patsubst %,-a -x %,$(Z88DK_BINS))
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

z88dk/.done: z88dk-win32.zip
	echo 'f4abedfae429ea159e388b5c76758ace4dcb86e9a00dbd928862b0a30f6874d6  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf z88dk
	unzip -nq $<
	touch $@

z88dk-win32.zip:
	wget -c https://github.com/z88dk/z88dk/releases/download/v2.1/z88dk-win32-2.1.zip -O $@

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
	rm -f\
 z88dk-src.tgz\
 z88dk-src.tgz.sha256\
 z88dk-win32.zip\
 z88dk-win32.zip.sha256

else	# !_DoClean

distclean-z88dk:;

endif	# !_DoClean

# lodepng

.PHONY: $(foreach a,build install uninstall clean distclean,$(a)-lodepng)

ifeq ($(_DoBuild),1)

build-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix))

install-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install

else	# !_DoBuild

build-lodepng install-lodepng:;

endif	# !_DoBuild

ifeq ($(_DoClean),1)

uninstall-lodepng: | lodepng
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) uninstall

clean-lodepng: | lodepng
	$(MAKE) -w -C $| clean

distclean-lodepng: | lodepng
	$(MAKE) -w -C $| distclean

else	# !_DoClean

uninstall-lodepng clean-lodepng distclean-lodepng:;

endif	# !_DoClean

# zx7b

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

# tools

.PHONY: $(foreach a,build install uninstall clean distclean,$(a)-tools)

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
