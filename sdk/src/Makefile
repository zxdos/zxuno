# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make [BUILD=<BUILD>] [FORCEBUILD=<FB_FLAG>] [<TARGET>]
# Clean:
#   make [BUILD=<BUILD>] [FORCECLEAN=<FC_FLAG>] clean
#
# where:
#   <BUILD> is one of: mingw32, mingw64.
#   <FB_FLAG> is 1 to force build, otherwise do not (default).
#   <FC_FLAG> is 1 to force clean, otherwise do not (default).
#   <TARGET> is one of values of TOOLS variable (see below).
#
# Notes:
#   BUILD, FORCEBUILD, FORCECLEAN variables may be set in user's environment.

include ../common.mk

SJASMPLUS	:= sjasmplus$(EXECEXT)
ZX7B		:= zx7b$(EXECEXT)
FCUT		:= fcut$(EXECEXT)
FPAD		:= fpad$(EXECEXT)
FPOKE		:= fpoke$(EXECEXT)
GENROM		:= GenRom$(EXECEXT)

TOOLS:= \
 ../bin/$(SJASMPLUS) \
 ../bin/$(ZX7B) \
 ../bin/$(FCUT) \
 ../bin/$(FPAD) \
 ../bin/$(FPOKE) \
 ../bin/$(GENROM)

.PHONY: all
all: $(TOOLS)

ifeq ($(OS),Windows_NT)
ifeq ($(FORCEBUILD),1)
_DoBuild:=1
else
_DoBuild:=0
endif
else
_DoBuild:=1
endif

ifeq ($(OS),Windows_NT)
ifeq ($(FORCECLEAN),1)
_DoClean:=1
else
_DoClean:=0
endif
else
_DoClean:=1
endif

ifeq ($(_DoBuild),1)
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

../bin/$(ZX7B): zx7b/$(ZX7B)
	cp $< $@

zx7b/$(ZX7B): | zx7b
	$(MAKE) -w -C $|

../bin/$(FCUT): tools/$(FCUT)
	cp $< $@

../bin/$(FPAD): tools/$(FPAD)
	cp $< $@

../bin/$(FPOKE): tools/$(FPOKE)
	cp $< $@

../bin/$(GENROM): tools/$(GENROM)
	cp $< $@

tools/$(FCUT) \
tools/$(FPAD) \
tools/$(FPOKE) \
tools/$(GENROM): | tools
	$(MAKE) -w -C $|
endif

.PHONY: clean
ifneq ($(_DoClean),1)
clean:;
else
clean: | sjasmplus sjasmplus.mk zx7b tools
	$(MAKE) -w -C sjasmplus -f ../sjasmplus.mk clean
	$(MAKE) -w -C zx7b clean
	$(MAKE) -w -C tools clean
	rm -f $(TOOLS)
endif
