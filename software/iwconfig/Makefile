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

BINS=\
 IWCONFIG

# `zcc' compiler's behavior:
#   * produces binary file in source's directory only
#   * creates temporary files
TMPS=\
 $(foreach t,$(BINS),$(t)_CODE.bin $(t)_UNASSIGNED.bin)

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/IWCONFIG: $(srcdir)/iwconfig.c | build
	zcc +zx -vn -startup=30 -clib=new $< -SO3 -o $(@F) -subtype=dot -create-app
# Workaround for zcc:
	rm -f $(TMPS)
	mv $(@F) $@

$(DESTDIR)$(bindir)/%: build/% | $(DESTDIR)$(bindir)
	cp $< $@

.PHONY: install
install: $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: uninstall
uninstall:
	$(RM) $(foreach t,$(BINS),$(DESTDIR)$(bindir)/$(t))

.PHONY: clean
clean:
	rm -f $(BINS) $(TMPS) $(foreach t,$(BINS),build/$(t))

.PHONY: distclean
distclean:
	rm -rf build
