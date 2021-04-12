# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)

include ../../common.mk

ifeq ($(OS),Windows_NT)
ZX7B	:= zx7b.exe
else
ZX7B	:= zx7b
endif

ifneq ($(OS),Windows_NT)
$(ZX7B): zx7b.c
	$(CC) $(CFLAGS) -o $@ $<

zx7b.c:
	wget -c https://github.com/antoniovillena/zx7b/raw/master/zx7b.c
endif

.PHONY: clean
ifeq ($(OS),Windows_NT)
clean:;
else
clean:
	rm -f $(ZX7B)
endif
