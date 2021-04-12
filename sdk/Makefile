# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

include common.mk

ifeq ($(OS),Windows_NT)
SJASMPLUS	:= sjasmplus.exe
ZX7B		:= zx7b.exe
else
SJASMPLUS	:= sjasmplus
ZX7B		:= zx7b
endif

TOOLS:=\
 bin/$(SJASMPLUS) \
 bin/$(ZX7B)

.PHONY: all
all: $(TOOLS)

$(TOOLS): | src/Makefile
	$(MAKE) -w -C src ../bin/$(@F)

.PHONY: clean
clean: | src/Makefile
	$(MAKE) -w -C src clean
