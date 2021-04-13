# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C sjasmplus -f ../sjasmplus.mk
# Clean:
#   make [BUILD=<BUILD>] -w -C sjasmplus -f ../sjasmplus.mk clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#
# Notes:
#   BUILD variable may be set in user's environment.


include ../../common.mk

CMAKEFLAGS	:=

ifeq ($(BUILD),mingw32)
CMAKEFLAGS	+= CMAKE_SYSTEM_NAME=Windows
CMAKEFLAGS	+= CMAKE_SYSTEM_PROCESSOR=x86
CMAKEFLAGS	+= CMAKE_C_COMPILER=i686-w64-mingw32-gcc
CMAKEFLAGS	+= CMAKE_CXX_COMPILER=i686-w64-mingw32-g++
CMAKEFLAGS	:= $(patsubst %,-D%,$(CMAKEFLAGS))
else ifeq ($(BUILD),mingw64)
CMAKEFLAGS	+= CMAKE_SYSTEM_NAME=Windows
CMAKEFLAGS	+= CMAKE_SYSTEM_PROCESSOR=AMD64
CMAKEFLAGS	+= CMAKE_C_COMPILER=x86_64-w64-mingw32-gcc
CMAKEFLAGS	+= CMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++
CMAKEFLAGS	:= $(patsubst %,-D%,$(CMAKEFLAGS))
endif

SJASMPLUS	:= sjasmplus$(EXECEXT)

build/$(SJASMPLUS): | build/Makefile
	$(MAKE) -w -C build

build/Makefile: | build
	cd build && cmake $(CMAKEFLAGS) ..

build:
	mkdir $@

.PHONY: clean
clean:
	rm -rf build
