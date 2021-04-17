# SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
#
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../sdk/common.mk

.PHONY: all
all: ugoph.bin

ugoph.bin ugoph.tap: main.asm tscreen.asm keyboard.asm utils.asm wifi.asm gopher.asm render.asm textrender.asm uart.asm ring.asm esxdos.asm vtpl.asm
	sjasmplus $<

.PHONY: clean
clean:
	rm -f ugoph.bin ugoph.tap
