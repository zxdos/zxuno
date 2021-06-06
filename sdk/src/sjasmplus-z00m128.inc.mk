# sjasmplus-z00m128.inc.mk - script to download and build SJAsmPlus by aprisobal.
#
# This file is a part of main Makefile.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

.downloads/sjasmplus-z00m128:
	mkdir -p $@

.PHONY: $(foreach t,build install uninstall clean distclean,$(t)-sjasmplus)

ifeq ($(_DoBuild),1)

SJASMPLUS_ARCHIVE		= .downloads/sjasmplus-z00m128/v1.18.2.tar.gz
SJASMPLUS_ARCHIVE_SHA256	= 114807bf53d3526b4d1ae7d40f3050b9ee98220df74931efc1e6d1fe5aba3d02
SJASMPLUS_ARCHIVE_TYPE		= .tar.gz
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.2

build-sjasmplus: | sjasmplus-z00m128/.extracted sjasmplus-z00m128.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix))

sjasmplus-z00m128/.extracted: $(SJASMPLUS_ARCHIVE)
	echo '$(SJASMPLUS_ARCHIVE_SHA256)  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf $(@D)
	test '$(@D)' = '$(SJASMPLUS_ARCHIVE_SUBDIR)' -o '$(SJASMPLUS_ARCHIVE_SUBDIR)' = . || rm -rf $(SJASMPLUS_ARCHIVE_SUBDIR)
ifeq ($(SJASMPLUS_ARCHIVE_TYPE),.tar.gz)
 ifeq ($(SJASMPLUS_ARCHIVE_SUBDIR),.)
  $(error Not implemented)
 else
	tar -xzf $<
 endif
else
 $(error Not implemented)
endif
	test '$(@D)' = '$(SJASMPLUS_ARCHIVE_SUBDIR)' -o '$(SJASMPLUS_ARCHIVE_SUBDIR)' = . || mv $(SJASMPLUS_ARCHIVE_SUBDIR) $(@D)
	touch $@

.downloads/sjasmplus-z00m128/v1.18.2.tar.gz: | .downloads/sjasmplus-z00m128
	wget -c https://github.com/z00m128/sjasmplus/archive/refs/tags/$(@F) -O $@

install-sjasmplus: | sjasmplus-z00m128/.extracted sjasmplus-z00m128.mk
	$(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix)) install

ifeq ($(_DoClean),1)

uninstall-sjasmplus: | sjasmplus-z00m128.mk
	if test -d sjasmplus-z00m128; then\
		$(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk prefix=$(shell realpath --relative-to=sjasmplus-z00m128 $(prefix)) uninstall;\
	else\
		rm -f $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX);\
	fi

clean-sjasmplus: | sjasmplus-z00m128.mk
	if test -d sjasmplus-z00m128; then $(MAKE) -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk clean; fi

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _DoBuild

ifeq ($(_UsePrecompiledOnWindows),1)

build-sjasmplus: sjasmplus-z00m128/sjasmplus$(EXESUFFIX)

sjasmplus-z00m128/sjasmplus$(EXESUFFIX): | sjasmplus-z00m128/.extracted

ifeq ($(PROCESSOR_ARCHITECTURE),X86)
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
else
 $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
endif

SJASMPLUS_ARCHIVE		= .downloads/sjasmplus-z00m128/sjasmplus-1.18.2.win.zip
SJASMPLUS_ARCHIVE_SHA256	= 848bca2522d6febbf3e3c48c634731ecd61899166f5922ed15857e8063c3dc4b
SJASMPLUS_ARCHIVE_TYPE		= .zip
SJASMPLUS_ARCHIVE_SUBDIR	= sjasmplus-1.18.2.win

sjasmplus-z00m128/.extracted: $(SJASMPLUS_ARCHIVE)
	echo '$(SJASMPLUS_ARCHIVE_SHA256)  $<' >$<.sha256
	sha256sum -c $<.sha256
	rm -f $<.sha256
	rm -rf $(@D)
	test '$(@D)' = '$(SJASMPLUS_ARCHIVE_SUBDIR)' -o '$(SJASMPLUS_ARCHIVE_SUBDIR)' = . || rm -rf $(SJASMPLUS_ARCHIVE_SUBDIR)
ifeq ($(SJASMPLUS_ARCHIVE_TYPE),.zip)
 ifeq ($(SJASMPLUS_ARCHIVE_SUBDIR),.)
	unzip -nq -d $(@D) $<
 else
	unzip -nq $<
 endif
else
 $(error Not implemented)
endif
	test '$(@D)' = '$(SJASMPLUS_ARCHIVE_SUBDIR)' -o '$(SJASMPLUS_ARCHIVE_SUBDIR)' = . || mv $(SJASMPLUS_ARCHIVE_SUBDIR) $(@D)
	touch $@

.downloads/sjasmplus-z00m128/sjasmplus-1.18.2.win.zip: | .downloads/sjasmplus-z00m128
	wget -c https://github.com/z00m128/sjasmplus/releases/download/v1.18.2/$(@F) -O $@

install-sjasmplus: $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): sjasmplus-z00m128/sjasmplus$(EXESUFFIX) | $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $< $@

ifeq ($(_DoClean),1)

uninstall-sjasmplus:
	rm -f $(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX)

clean-sjasmplus:
	rm -rf sjasmplus-z00m128

else	#  !_DoClean

uninstall-sjasmplus clean-sjasmplus:;

endif	#  !_DoClean
endif	# _UsePrecompiledOnWindows

ifeq ($(_DoClean),1)

distclean-sjasmplus:
	rm -rf\
 .downloads/sjasmplus-z00m128\
 sjasmplus-z00m128

else	# !_DoClean

distclean-sjasmplus:;

endif	# !_DoClean
