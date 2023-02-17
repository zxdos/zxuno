# Common declarations for Makefiles.
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021, 2022 Ivan Tatarinov
# SPDX-License-Identifier: GPL-3.0-or-later

#-----------------------------------------------------------------------------
# ZXSDK

ifndef ZXSDK

# Root (if set acts as a flag of the properly configured environment variables)
export ZXSDK := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
_path = $(ZXSDK)

# Root of platform specific files
ifeq ($(OS),Windows_NT)
 ifeq ($(PROCESSOR_ARCHITECTURE),X86)
  ZXSDK_PLATFORM = $(ZXSDK)/windows-x86
 else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
  ZXSDK_PLATFORM = $(ZXSDK)/windows-x86
 else ifeq ($(PROCESSOR_ARCHITECTURE),EM64T)
  ZXSDK_PLATFORM = $(ZXSDK)/windows-x86
 else
  $(warning Unsupported platform: "$(PROCESSOR_ARCHITECTURE)")
  ZXSDK_PLATFORM = $(ZXSDK)/unknown
 endif
else ifeq ($(shell uname -s),Linux)
 ZXSDK_PLATFORM = $(ZXSDK)/linux
else
 $(warning Unsupported platform)
 ZXSDK_PLATFORM = $(ZXSDK)/unknown
endif
export ZXSDK_PLATFORM

# "bin" directory (platform specific)
_path := $(_path):$(ZXSDK_PLATFORM)/bin

# "lib" directory (platform specific)
ifeq ($(OS),Windows_NT)
 _path := $(_path):$(ZXSDK_PLATFORM)/lib
else
 export LD_LIBRARY_PATH = $(ZXSDK_PLATFORM)/lib
endif

# SDCC

# Root (platform specific)
export SDCCHOME = $(ZXSDK_PLATFORM)/opt/sdcc

# "bin" directory (platform specific)
_path := $(_path):$(SDCCHOME)/bin

# "include" directory (platform specific)
ifeq ($(OS),Windows_NT)
 SDCCINCLUDE = $(SDCCHOME)/include
else
 SDCCINCLUDE = $(SDCCHOME)/share/sdcc/include
endif
export SDCCINCLUDE

# "lib" directory (platform specific)
ifeq ($(OS),Windows_NT)
 SDCCLIB = $(SDCCHOME)/lib
else
 SDCCLIB = $(SDCCHOME)/share/sdcc/lib
endif
export SDCCLIB

# Z88DK

# Root
export Z88DK = $(ZXSDK_PLATFORM)/opt/z88dk

# "bin" directory
_path := $(_path):$(Z88DK)/bin

# Configuration file
ZCCCFG = $(Z88DK)/lib/config
ifeq ($(OS),Windows_NT)
 # Fix paths under Cygwin for Z88DK on Windows
 ifeq ($(shell echo $$OSTYPE),cygwin)
  ZCCCFG := $(shell cygpath -m $(ZCCCFG))
 endif
endif
export ZCCCFG

# PATH

export PATH := $(_path):$(PATH)
undefine _path

endif	# !ZXSDK

#-----------------------------------------------------------------------------
# Default values

-include $(ZXSDK)/conf.mk

# Shared directory for downloaded files
DOWNLOADS ?= $(shell realpath -m $(ZXSDK)/../.downloads)

# C compiler
ifeq ($(BUILD),mingw32)
 export CC = i686-w64-mingw32-gcc
else ifeq ($(BUILD),mingw64)
 export CC = x86_64-w64-mingw32-gcc
endif

# Filename suffixes (platform specific)
ifeq ($(BUILD),mingw32)
 EXESUFFIX = .exe
 DLLSUFFIX = .dll
else ifeq ($(BUILD),mingw64)
 EXESUFFIX = .exe
 DLLSUFFIX = .dll
else
 ifeq ($(OS),Windows_NT)
  EXESUFFIX = .exe
  DLLSUFFIX = .dll
 else
  EXESUFFIX =
  DLLSUFFIX = .so
 endif
endif

# Default path where to install files (platform specific)
ifeq ($(BUILD),mingw32)
 USE_PREFIX ?= $(ZXSDK)/windows-x86
else ifeq ($(BUILD),mingw64)
 USE_PREFIX ?= $(ZXSDK)/windows-x86_64
else
 USE_PREFIX ?= $(ZXSDK_PLATFORM)
endif

# Version of SJAsmPlus compiler to use
USE_SJASMPLUS_BRANCH ?= z00m128
ifeq ($(USE_SJASMPLUS_BRANCH),sjasmplus)
else ifeq ($(USE_SJASMPLUS_BRANCH),z00m128)
 USE_SJASMPLUS_VERSION ?= 1.20.2
endif

# Version of SDCC to use
USE_SDCC_VERSION ?= 4.1.0

# Version of Z88DK to use
USE_Z88DK_VERSION ?= 2.2

# Version of The Right Tools to use
USE_THERIGHTTOOLS_VERSION ?= 0.2.1
