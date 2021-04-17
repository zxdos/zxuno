# SPDX-FileCopyrightText: Copyright (C) 2019 Alexander Sharikhin
#
# SPDX-License-Identifier: GPL-3.0-or-later

include ../../sdk/common.mk

.PHONY: all
all: IWCONFIG

IWCONFIG: iwconfig.c
	zcc +zx -vn -startup=30 -clib=new $< -SO3 -o $@ -subtype=dot -create-app

.PHONY: clean
clean:
	rm -f *.bin *.def IWCONFIG
