# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] -w -C z88dk -f ../z88dk.mk
# Clean:
#   make [BUILD=<BUILD>] -w -C z88dk -f ../z88dk.mk clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#
# Notes:
#   BUILD variable may be set in user's environment.

include ../../common.mk

.PHONY: all
all: | build.sh
	chmod 777 $|
	./build.sh

.PHONY: clean
clean: | build.sh
	chmod 777 $|
	./build.sh -C
