# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Configure:
#   make configure [<CFG_PARAMS>]
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
#   <CFG_PARAMS> is a set of parameters of type <CFG_VAR>=<VALUE>
#     USE_SJASMPLUS_VERSION: sjasmplus, z00m128 (default).
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

TARGETS=sjasmplus z88dk lodepng zx7b tools

.PHONY: all
all: install

.PHONY: $(TARGETS)
$(TARGETS): | src
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) install-$@

.PHONY:\
 configure build install uninstall clean distclean\
 $(foreach t,$(TARGETS),build-$(t) install-$(t) uninstall-$(t) clean-$(t) distclean-$(t))

configure:
	@echo '# This is a local configuration file for Make.' >conf.mk;\
	echo '# This file is generated automatically by `make configure`.' >>conf.mk;\
	echo 'USE_SJASMPLUS_VERSION=$(USE_SJASMPLUS_VERSION)' >>conf.mk

build install uninstall clean distclean \
$(foreach t,$(TARGETS),build-$(t) install-$(t) uninstall-$(t) clean-$(t) distclean-$(t)): | src
	$(MAKE) -w -C $| prefix=$(shell realpath --relative-to=$| $(prefix)) $@
