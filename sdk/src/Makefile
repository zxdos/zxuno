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
#   make [<FLAGS>] [all | install | install-<TARGET>]
# Uninstall:
#   make [<FLAGS>] uninstall | uninstall-<TARGET>
# Clean:
#   make [<FLAGS>] clean | clean-<TARGET>
#   make [<FLAGS>] distclean | distclean-<TARGET>
#
# where:
#   <FLAGS> are:
#     [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [FORCECLEAN=<FC_FLAG>]
# where values are:
#   <BUILD> - see included `common.mk'.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of the values of `TARGETS' variable.
#
# NOTE: `FORCEBUILD' and `FORCECLEAN' are mainly for Windows platform.

include ../common.mk

prefix		?= $(shell realpath --relative-base=. $(USE_PREFIX))
exec_prefix	?= $(prefix)
bindir		?= $(exec_prefix)/bin

INSTALL		?= install
INSTALL_PROGRAM	?= $(INSTALL)

TARGETS=\
 sjasmplus\
 sdcc\
 z88dk\
 lodepng\
 zx7b\
 tools

.PHONY: all build install uninstall clean distclean
all: install
build: $(foreach t,$(TARGETS),build-$(t))
install: $(foreach t,$(TARGETS),install-$(t))
uninstall: $(foreach t,$(TARGETS),uninstall-$(t))
clean: $(foreach t,$(TARGETS),clean-$(t))
distclean: $(foreach t,$(TARGETS),distclean-$(t))

_DoBuild			= 1
_UsePrecompiledOnWindows	= 0
_DoClean			= 1

ifeq ($(OS),Windows_NT)
 ifneq ($(FORCEBUILD),1)
  _DoBuild			= 0
  _UsePrecompiledOnWindows	= 1
 endif
 ifneq ($(FORCECLEAN),1)
  _DoClean			= 0
 endif
endif	# $(OS)==Windows_NT

.downloads\
$(DESTDIR)$(bindir):
	mkdir -p $@

ifeq ($(USE_SJASMPLUS_VERSION),sjasmplus)
 include sjasmplus.inc.mk
else ifeq ($(USE_SJASMPLUS_VERSION),z00m128)
 include sjasmplus-z00m128.inc.mk
else
 $(error Unknown SJAsmPlus version selected: `$(USE_SJASMPLUS_VERSION)')
endif

include sdcc.inc.mk
include z88dk.inc.mk
include lodepng.inc.mk
include tools.inc.mk
