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
includedir	?= $(prefix)/include
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin
libdir		?= $(exec_prefix)/lib

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

BINS:=\
 bin2hex$(EXESUFFIX)\
 fcut$(EXESUFFIX)\
 fontconv$(EXESUFFIX)\
 fpad$(EXESUFFIX)\
 fpoke$(EXESUFFIX)\
 rcs$(EXESUFFIX)\
 Png2Rcs$(EXESUFFIX)\
 GenTape$(EXESUFFIX)\
 GenRom$(EXESUFFIX)\
 AddItem$(EXESUFFIX)\
 Bit2Bin$(EXESUFFIX)

LOCAL_LIBS=\
 $(srcdir)/liblodepng$(DLLSUFFIX)

CFLAGS := -I$(DESTDIR)$(includedir) -L$(DESTDIR)$(libdir) -fPIC -O3 -W $(CFLAGS)

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

$(srcdir)/liblodepng$(DLLSUFFIX): $(DESTDIR)$(libdir)/liblodepng$(DLLSUFFIX)
	ln -fs $< $@

build/fontconv$(EXESUFFIX): $(srcdir)/fontconv.c\
 $(DESTDIR)$(includedir)/lodepng.h\
 $(srcdir)/liblodepng$(DLLSUFFIX)\
 Makefile | build
	$(CC) -ansi -Wall -Wextra -Wpedantic $(CFLAGS) -o $@ $< $(foreach l,liblodepng$(DLLSUFFIX),-l:$(l) $(l))

build/Png2Rcs$(EXESUFFIX): $(srcdir)/Png2Rcs.c\
 $(DESTDIR)$(includedir)/lodepng.h\
 $(srcdir)/liblodepng$(DLLSUFFIX)\
 Makefile | build
	$(CC) $(CFLAGS) -o $@ $< $(foreach l,liblodepng$(DLLSUFFIX),-l:$(l) $(l))

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
	$(RM) $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	$(RM) $(foreach t,$(BINS),build/$(t))
	$(RM) $(LOCAL_LIBS)

.PHONY: distclean
distclean:
	$(RM) -r build
	$(RM) $(LOCAL_LIBS)
