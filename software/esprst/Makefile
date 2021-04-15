# SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
#
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../sdk/common.mk

.PHONY: all
all: esprst

esprst: main.asm uart.asm ring.asm
	sjasmplus $<

.PHONY: clean
clean:
	rm -f esprst
