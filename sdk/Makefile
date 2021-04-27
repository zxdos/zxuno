# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [<FLAGS>] build | build-<TARGET>
# Install:
#   make [<FLAGS>] [all | <TARGET> | install-<TARGET>]
# Uninstall:
#   make [<FLAGS>] uninstall | uninstall-<TARGET>
# Clean:
#   make [<FLAGS>] clean | clean-<TARGET>
#   make [<FLAGS>] distclean | distclean-<TARGET>
#
# where:
#   <FLAGS> are these flags:
#     [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [FORCECLEAN=<FC_FLAG>]
# where values are:
#   <BUILD> - see included `common.mk'.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of the values of `TARGETS' variable.
#
# NOTE: `FORCEBUILD' and `FORCECLEAN' are mainly for Windows platform.

include common.mk

prefix	?= .

ifeq ($(BUILD),mingw32)
FORCEBUILD:=1
else ifeq ($(BUILD),mingw64)
FORCEBUILD:=1
else
BUILD:=
FORCEBUILD:=0
endif

ifdef $(FORCECLEAN)
ifneq ($(FORCECLEAN),1)
FORCECLEAN:=0
else
FORCECLEAN:=0
endif
endif

export BUILD
export FORCEBUILD
export FORCECLEAN

TARGETS=sjasmplus z88dk zx7b tools

.PHONY: all
all: install

.PHONY: $(TARGETS)
$(TARGETS): | src
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install-$@

.PHONY:\
 build install uninstall clean distclean\
 $(foreach t,$(TARGETS),build-$(t) install-$(t) uninstall-$(t) clean-$(t) distclean-$(t))
build install uninstall clean distclean \
$(foreach t,$(TARGETS),build-$(t) install-$(t) uninstall-$(t) clean-$(t) distclean-$(t)): | src
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) $@
