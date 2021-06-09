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

include ../../sdk/common.mk

srcdir		= .
# Use uppercase for FAT filesystem
prefix		?= .
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/BIN

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)
RM		= rm -f

BINS=\
 JOYCONF

CC = sdcc
CFLAGS = -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node 30000
ESXDOS_ORG = 8192
TMPS =

.PHONY: all
all: $(foreach t,$(BINS),build/$(t))

build\
$(DESTDIR)$(bindir):
	mkdir -p $@

build/joyconf.ihx: $(srcdir)/joyconf.c | build
	$(CC) $(CFLAGS) --nostdlib --nostdinc --no-std-crt0 --code-loc $(ESXDOS_ORG) -o $@ $<
TMPS += $(foreach s,ihx asm lk lst map noi rel sym,build/joyconf.$(s))

build/joyconf.bin: build/joyconf.ihx
	makebin -p $< $@
TMPS += build/joyconf.bin

build/JOYCONF: build/joyconf.bin
	dd if=$< of=$@ bs=1 skip=$(ESXDOS_ORG) status=noxfer

# $1 = target
# No need in execution mode for FAT filesystem
define install_bin_rule =
$$(DESTDIR)$$(bindir)/$1: build/$1 | $$(DESTDIR)$$(bindir)
	$$(INSTALL_PROGRAM) -m 644 $$< $$@
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
	rm -rf build
