# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

include ../common.mk

ifeq ($(OS),Windows_NT)
SJASMPLUS	:= sjasmplus.exe
else
SJASMPLUS	:= sjasmplus
endif

.PHONY: all
all: \
 ../bin/$(SJASMPLUS)

ifneq ($(OS),Windows_NT)
../bin/$(SJASMPLUS): sjasmplus/build/$(SJASMPLUS)
	cp $< $@

sjasmplus/build/$(SJASMPLUS): | sjasmplus sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk

sjasmplus:
	git clone https://github.com/sjasmplus/sjasmplus.git $@
endif

.PHONY: clean
ifeq ($(OS),Windows_NT)
clean:;
else
clean: | sjasmplus sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean
	rm -f ../bin/$(SJASMPLUS)
endif
