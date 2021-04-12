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
	wget -c https://github.com/sjasmplus/sjasmplus/archive/refs/tags/20190306.1.tar.gz -O sjasmplus.tgz
	echo 'f3f6d28af19880ed2cb427b6b427e9bd42371929c7d263dac840fb71de1302d6  sjasmplus.tgz' >sjasmplus.sha256sum
	sha256sum -c sjasmplus.sha256sum
	rm -f sjasmplus.sha256sum
	tar -xzf sjasmplus.tgz
	mv sjasmplus-20190306.1 sjasmplus
	rm -f sjasmplus.tgz
endif

.PHONY: clean
ifeq ($(OS),Windows_NT)
clean:;
else
clean: | sjasmplus sjasmplus.mk
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean
	rm -f ../bin/$(SJASMPLUS)
endif
