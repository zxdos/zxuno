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

ifeq ($(OS),Windows_NT)
 ifeq ($(PROCESSOR_ARCHITECTURE),X86)
  ZXSDK_PLATFORM= $(ZXSDK)/windows-x86
 else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
  ZXSDK_PLATFORM= $(ZXSDK)/windows-x86
 else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
  ZXSDK_PLATFORM= $(ZXSDK)/windows-x86
 else
  $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
  ZXSDK_PLATFORM= $(ZXSDK)/windows-x86
 endif
else
 ZXSDK_PLATFORM	= $(ZXSDK)
endif

Z88DK		:= $(ZXSDK)/src/z88dk
ZCCCFG		:= $(Z88DK)/lib/config
PATH		:= $(ZXSDK_PLATFORM)/bin:$(Z88DK)/bin:$(PATH)

ifeq ($(OS),Windows_NT)
PATH		:= $(ZXSDK_PLATFORM)/lib:$(PATH)
# Fix paths under Cygwin for z88dk on Windows
ifeq ($(shell echo $$OSTYPE),cygwin)
ZCCCFG		:= $(shell cygpath -m $(ZCCCFG))
endif
else	# $(OS)!=Windows_NT
export LD_LIBRARY_PATH:=$(ZXSDK_PLATFORM)/lib
endif	# $(OS)!=Windows_NT

export ZXSDK
export ZXSDK_PLATFORM
export ZCCCFG
export PATH

endif	# !ZXSDK

-include $(ZXSDK)/conf.mk

ifeq ($(OS),Windows_NT)
EXESUFFIX	:= .exe
DLLSUFFIX	:= .dll
else
EXESUFFIX	:=
DLLSUFFIX	:= .so
endif

ifeq ($(BUILD),mingw32)
CC		:= i686-w64-mingw32-gcc
EXESUFFIX	:= .exe
DLLSUFFIX	:= .dll
USE_PREFIX	?= $(ZXSDK)/windows-x86
else ifeq ($(BUILD),mingw64)
CC		:= x86_64-w64-mingw32-gcc
EXESUFFIX	:= .exe
DLLSUFFIX	:= .dll
USE_PREFIX	?= $(ZXSDK)/windows-x86_64
endif

# Default values
USE_PREFIX		?= $(ZXSDK_PLATFORM)
USE_SJASMPLUS_VERSION	?= z00m128
