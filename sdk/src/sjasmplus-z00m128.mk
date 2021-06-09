# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk
# Install / Uninstall:
#   make [BUILD=<BUILD>] [prefix=<PREFIX>] -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk install | uninstall
# Clean:
#   make [BUILD=<BUILD>] -w -C sjasmplus-z00m128 -f ../sjasmplus-z00m128.mk clean
#
# where:
#   <BUILD> - see included `common.mk'.
#   <PREFIX> is a prefix directory to install files into.

include ../../common.mk

srcdir		= .
prefix		?= /usr/local
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)
RM		?= rm -f

BINS		= sjasmplus$(EXESUFFIX)

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

$(srcdir)/sjasmplus$(EXESUFFIX): | Makefile
	$(MAKE) clean
	$(MAKE)

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

$(DESTDIR)$(bindir)/sjasmplus$(EXESUFFIX): sjasmplus$(EXESUFFIX) | $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) -m 755 $< $@

.PHONY: uninstall
uninstall:
	$(RM) $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	$(MAKE) clean

.PHONY: distclean
distclean: clean
