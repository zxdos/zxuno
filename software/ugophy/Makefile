# SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
#
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../sdk/common.mk

.PHONY: all
all: ugoph.bin

ugoph.bin: *.asm
	sjasmplus main.asm

.PHONY: clean
clean:
	rm -f ugoph.bin
