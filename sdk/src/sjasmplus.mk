# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make -w -C sjasmplus -f ../sjasmplus.mk
# Clean:
#   make -w -C sjasmplus -f ../sjasmplus.mk clean

ifeq ($(OS),Windows_NT)
SJASMPLUS	:= sjasmplus.exe
else
SJASMPLUS	:= sjasmplus
endif

build/$(SJASMPLUS): | build/Makefile
	$(MAKE) -w -C build

build/Makefile: | build
	cd build && cmake ..

build:
	mkdir -p build

.PHONY: clean
clean: | build/Makefile
	$(MAKE) -w -C build clean
