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

ifeq ($(BUILD),mingw32)
CMAKEFLAGS	:= -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw32.cmake
else ifeq ($(BUILD),mingw64)
CMAKEFLAGS	:= -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw64.cmake
else
CMAKEFLAGS	:=
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
