# Common declarations for Makefiles.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)

ifndef ZXSDK

ZXSDK		:= $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
Z88DK		:= $(ZXSDK)/src/z88dk
ZCCCFG		:= $(Z88DK)/lib/config
PATH		:= $(ZXSDK)/bin:$(Z88DK)/bin:$(PATH)

# Fix paths under Cygwin for z88dk on Windows
ifeq ($(OS),Windows_NT)
ifeq ($(shell echo $$OSTYPE),cygwin)
ZCCCFG		:= $(shell cygpath -m $(ZCCCFG))
endif
endif

export ZXSDK
export ZCCCFG
export PATH

endif

ifeq ($(OS),Windows_NT)
EXESUFFIX	:= .exe
else
EXESUFFIX	:=
endif

ifeq ($(BUILD),mingw32)
CC		:= i686-w64-mingw32-gcc
EXESUFFIX	:= .exe
else ifeq ($(BUILD),mingw64)
CC		:= x86_64-w64-mingw32-gcc
EXESUFFIX	:= .exe
endif
