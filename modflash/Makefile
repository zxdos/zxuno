# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

include ../sdk/common.mk

ifeq ($(OS),Windows_NT)
ADDITEM	= AddItem.exe
else
ADDITEM	= AddItem
endif

.PHONY: all
all: | FLASHempty.ZX1 $(ADDITEM) ./addroms.sh ./addcores.sh roms.txt cores.txt
	cp FLASHempty.ZX1 FLASH.ZX1
	./addroms.sh
	./addcores.sh

ifneq ($(OS),Windows_NT)
$(ADDITEM): AddItem.c
	$(CC) $(CFLAGS) $< -o $@
endif

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	# Nothing to do
else
	rm -f $(ADDITEM)
endif

.PHONY: dist-clean
dist-clean: clean
	rm -f FLASH.ZX1
