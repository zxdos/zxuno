#!/bin/make -f
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [<TARGET> ...]
# Install / Uninstall:
#   make [prefix=<PREFIX>] install | uninstall
# Clean:
#   make clean | distclean
#
# where:
#   <TARGET> is one of values for target `all'.
#   <PREFIX> is a prefix directory to install files into.
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021, 2023 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

include ../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/BIN
bpluginsdir	?= $(exec_prefix)/BIN/BPLUGINS
sysdir		?= $(exec_prefix)/SYS

# Disable execution mode for FAT filesystem
INSTALL		?= install -m 644
INSTALL_PROGRAM	?= $(INSTALL)
RM		= rm -f

INCLUDEDIR	= ../sdk/include
FONTSDIR	= ../firmware
AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
AFLAGS		= --nologo
else
AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR) -I$(FONTSDIR)

BINS=\
 BACK16M\
 BACKZX2\
 BACKZXD\
 BACKUP\
 CORCLEAN\
 COREBIOS\
 DATE\
 ROMSBACK\
 ROMSUPGR\
 UPGR16M\
 UPGRZX2\
 UPGRZXD\
 UPGRADE\
 ZXUNOCFG

BPLUGINS=\
 ZX1

SYSS=\
 RTC.SYS

TMPS=\
 back32m.def\
 upgr32m.def

.PHONY: all
all: $(foreach t,$(BINS) $(BPLUGINS) $(SYSS),build/$(t))

build\
$(DESTDIR)$(bindir)\
$(DESTDIR)$(bpluginsdir)\
$(DESTDIR)$(sysdir):
	mkdir -p $@

build/BACK16M: $(srcdir)/back16m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/BACKZX2: $(srcdir)/back32m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	echo ' define zxdos 1' >back32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f back32m.def

build/BACKZXD: $(srcdir)/back32m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	echo ' define zxdos 0' >back32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f back32m.def

build/BACKUP: $(srcdir)/backup.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/CORCLEAN: $(srcdir)/corclean.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/COREBIOS: $(srcdir)/corebios.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/ROMSBACK: $(srcdir)/romsback.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/ROMSUPGR: $(srcdir)/romsupgr.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/UPGR16M: $(srcdir)/upgr16m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/UPGRZX2: $(srcdir)/upgr32m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	echo ' define zxdos 1' >upgr32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f upgr32m.def

build/UPGRZXD: $(srcdir)/upgr32m.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	echo ' define zxdos 0' >upgr32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f upgr32m.def

build/UPGRADE: $(srcdir)/upgrade.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/ZX1: $(srcdir)/zx1.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 $(INCLUDEDIR)/rdflsh.inc\
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 $(FONTSDIR)/fuente6x8.bin\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/DATE: $(srcdir)/date.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 $(INCLUDEDIR)/Print.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/RTC.SYS: $(srcdir)/rtc.asm\
 $(INCLUDEDIR)/zxuno.def\
 $(INCLUDEDIR)/esxdos.def\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/ZXUNOCFG: $(srcdir)/zxunocfg.asm\
 $(INCLUDEDIR)/zxuno.def\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

# $1 = target
define install_bin_rule =
$$(DESTDIR)$$(bindir)/$1: build/$1 | $$(DESTDIR)$$(bindir)
	$$(INSTALL_PROGRAM) $$< $$@
endef

$(foreach t,$(BINS),$(eval $(call install_bin_rule,$(t))))

# $1 = target
define install_bplugin_rule =
$$(DESTDIR)$$(bpluginsdir)/$1: build/$1 | $$(DESTDIR)$$(bpluginsdir)
	$$(INSTALL_PROGRAM) $$< $$@
endef

$(foreach t,$(BPLUGINS),$(eval $(call install_bplugin_rule,$(t))))

# $1 = target
define install_sys_rule =
$$(DESTDIR)$$(sysdir)/$1: build/$1 | $$(DESTDIR)$$(sysdir)
	$$(INSTALL_PROGRAM) $$< $$@
endef

$(foreach t,$(SYSS),$(eval $(call install_sys_rule,$(t))))

.PHONY: install
install:\
 $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))\
 $(foreach t,$(BPLUGINS),$(DESTDIR)$(bpluginsdir)/$(t))\
 $(foreach t,$(SYSS),$(DESTDIR)$(sysdir)/$(t))

.PHONY: uninstall
uninstall:
	$(RM)\
	 $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))\
	 $(foreach t,$(BPLUGINS),$(DESTDIR)$(bpluginsdir)/$(t))\
	 $(foreach t,$(SYSS),$(DESTDIR)$(sysdir)/$(t))

.PHONY: clean
clean:
	$(RM) $(TMPS) $(foreach t,$(BINS) $(BPLUGINS) $(SYSS),build/$(t))

.PHONY: distclean
distclean:
	$(RM) $(TMPS)
	$(RM) -r build
