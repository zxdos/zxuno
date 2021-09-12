# SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
#
# SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
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

include ../../sdk/common.mk

# Use uppercase for FAT filesystem
srcdir		= .
prefix		?= .
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/BIN

# Disable execution mode for FAT filesystem
INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL) -m 644
RM		= rm -f

AS		= sjasmplus
ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
AFLAGS		= --nobanner
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
AFLAGS		= --nologo
else
AFLAGS		=
endif

BINS=\
 UGOPH

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/UGOPH: $(srcdir)/main.asm\
 $(srcdir)/tscreen.asm\
 $(srcdir)/keyboard.asm\
 $(srcdir)/utils.asm\
 $(srcdir)/wifi.asm\
 $(srcdir)/gopher.asm\
 $(srcdir)/render.asm\
 $(srcdir)/textrender.asm\
 $(srcdir)/uart.asm\
 $(srcdir)/ring.asm\
 $(srcdir)/esxdos.asm\
 $(srcdir)/vtpl.asm\
 | build
	$(AS) $(AFLAGS) --raw=$@ $<

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: uninstall
uninstall:
	$(RM) $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	rm -f $(foreach t,$(BINS),build/$(t))

.PHONY: distclean
distclean:
	rm -rf build
