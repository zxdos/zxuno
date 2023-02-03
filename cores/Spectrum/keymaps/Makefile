#!/bin/make -f
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2023 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
keymapsdir	?= $(prefix)/SYS/KEYMAPS

INSTALL		?= install
INSTALL_DATA	?= $(INSTALL) -m 644
MKDIR		?= mkdir
RM		?= rm -f

BINS=\
 build/dumpkeybmap$(EXESUFFIX)\
 build/genkeybmap$(EXESUFFIX)

KEYMAPS=\
 build/av-fw.bin\
 build/av-sd.bin\
 build/es-fw.bin\
 build/es-sd.bin\
 build/us-fw.bin\
 build/us-sd.bin

.PHONY: all
all: $(BINS) $(KEYMAPS)

build\
$(DESTDIR)$(keymapsdir):
	$(MKDIR) -p $@

build/dumpkeybmap$(EXESUFFIX): $(srcdir)/dumpkeybmap.c\
 $(srcdir)/errors.h\
 $(srcdir)/errors.c\
 Makefile | build
	$(CC) $(CFLAGS) -std=c99 -Wall -o $@ $<

build/genkeybmap$(EXESUFFIX): $(srcdir)/genkeybmap.c\
 $(srcdir)/errors.h\
 $(srcdir)/errors.c\
 $(srcdir)/keys_pc.h\
 $(srcdir)/keys_sp.h\
 $(srcdir)/keymap_av_fw.c\
 $(srcdir)/keymap_av_sd.c\
 $(srcdir)/keymap_es_fw.c\
 $(srcdir)/keymap_es_sd.c\
 $(srcdir)/keymap_us_fw.c\
 $(srcdir)/keymap_us_sd.c\
 Makefile | build
	$(CC) $(CFLAGS) -std=c99 -Wall -o $@ $<

build/av-fw.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< av-fw $@

build/av-sd.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< av-sd $@

build/es-fw.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< es-fw $@

build/es-sd.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< es-sd $@

build/us-fw.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< us-fw $@

build/us-sd.bin: build/genkeybmap$(EXESUFFIX) Makefile | build
	./$< us-sd $@

$(DESTDIR)$(keymapsdir)/AV: build/av-sd.bin | $(DESTDIR)$(keymapsdir)
	$(INSTALL_DATA) $< $@

$(DESTDIR)$(keymapsdir)/ES: build/es-sd.bin | $(DESTDIR)$(keymapsdir)
	$(INSTALL_DATA) $< $@

$(DESTDIR)$(keymapsdir)/US: build/us-sd.bin | $(DESTDIR)$(keymapsdir)
	$(INSTALL_DATA) $< $@

.PHONY: install
install:\
 $(DESTDIR)$(keymapsdir)/AV\
 $(DESTDIR)$(keymapsdir)/ES\
 $(DESTDIR)$(keymapsdir)/US\
 | $(DESTDIR)$(keymapsdir)

.PHONY: uninstall
uninstall:
	$(RM)\
	 $(DESTDIR)$(keymapsdir)/AV\
	 $(DESTDIR)$(keymapsdir)/ES\
	 $(DESTDIR)$(keymapsdir)/US

.PHONY: clean
clean:
	$(RM) $(BINS) $(KEYMAPS)

.PHONY: distclean
distclean:
	$(RM) -r build
