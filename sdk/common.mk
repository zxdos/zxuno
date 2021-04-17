# Common declarations for Makefiles.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)

ifndef ZXUNOSDK

ZXUNOSDK	:= $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
PATH		:= $(ZXUNOSDK)/bin:$(PATH)

export ZXUNOSDK
export PATH

endif

ifeq ($(OS),Windows_NT)
EXECEXT		:= .exe
else
EXECEXT		:=
endif

ifeq ($(BUILD),mingw32)
CC		:= i686-w64-mingw32-gcc
EXECEXT		:= .exe
else ifeq ($(BUILD),mingw64)
CC		:= x86_64-w64-mingw32-gcc
EXECEXT		:= .exe
endif
