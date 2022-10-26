# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
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
#   <TARGET> is one of values for `BINS' variable prefixed with "build/"
#     (see target `all' below).
#   <PREFIX> is a prefix directory to install files into.

include ../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/BIN

# Disable execution mode for FAT filesystem
INSTALL		?= install -m 644
INSTALL_PROGRAM	?= $(INSTALL)
RM		= rm -f

INCLUDEDIR	= ../sdk/include
AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
AFLAGS		= --nologo
else
AFLAGS		=
endif
AFLAGS		+= -I$(INCLUDEDIR)

BINS=\
 BACK16M\
 BACKZX2\
 BACKZXD\
 BACKUP\
 CORCLEAN\
 COREBIOS\
 ZX1\
 SETDATE\
 RTC.SYS\
 ROMSBACK\
 ROMSUPGR\
 UPGR16M\
 UPGRZX2\
 UPGRZXD\
 UPGRADE\
 ZXUNOCFG

TMPS=\
 back32m.def\
 upgr32m.def

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
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
 $(INCLUDEDIR)/wrflsh.inc\
 $(INCLUDEDIR)/rst28.inc\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

build/SETDATE: $(srcdir)/setdate.asm\
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

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: uninstall
uninstall:
	$(RM) $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	rm -f $(TMPS) $(foreach t,$(BINS),build/$(t))

.PHONY: distclean
distclean:
	rm -f $(TMPS)
	rm -rf build
