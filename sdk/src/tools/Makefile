# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [<TARGET> ...]
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] install | uninstall
# Clean:
#   make [BUILD=<BUILD>] clean
#   make distclean
#
# where:
#   <BUILD> - see included `common.mk'.
#   <TARGET> is one of values for `BINS' variable prefixed with "build/"
#     (see target `all' below).
#   <PREFIX> is a prefix directory to install files into.

include ../../common.mk

srcdir		= .
prefix		?= /usr/local
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

BINS:=\
 bin2hex$(EXESUFFIX)\
 fcut$(EXESUFFIX)\
 fpad$(EXESUFFIX)\
 fpoke$(EXESUFFIX)\
 rcs$(EXESUFFIX)\
 Png2Rcs$(EXESUFFIX)\
 GenTape$(EXESUFFIX)\
 GenRom$(EXESUFFIX)\
 AddItem$(EXESUFFIX)\
 Bit2Bin$(EXESUFFIX)

INCLUDEDIR	= $(ZXSDK)/include
LIBDIR		= $(ZXSDK)/lib

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/Png2Rcs$(EXESUFFIX):\
 $(srcdir)/Png2Rcs.c\
 $(INCLUDEDIR)/lodepng.h\
 $(LIBDIR)/liblodepng$(DLLSUFFIX)\
 Makefile | build
	$(CC) -I$(INCLUDEDIR) -L$(LIBDIR) -l:liblodepng$(DLLSUFFIX) $(CFLAGS) -o $@ $<

build/%$(EXESUFFIX): $(srcdir)/%.c Makefile | build
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

# $1 = target
define install_bin_rule =
$$(DESTDIR)$$(bindir)/$1: build/$1 | $$(DESTDIR)$$(bindir)
	$$(INSTALL_PROGRAM) -m 755 $$< $$@
endef

$(foreach t,$(BINS),$(eval $(call install_bin_rule,$(t))))

.PHONY: uninstall
uninstall:
	rm -f $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	rm -f $(foreach t,$(BINS),build/$(t))

.PHONY: distclean
distclean:
	rm -rf build/*
