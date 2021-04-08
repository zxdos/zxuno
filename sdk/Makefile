# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

include common.mk

ifeq ($(OS),Windows_NT)
SJASMPLUS	:= sjasmplus.exe
else
SJASMPLUS	:= sjasmplus
endif

TOOLS:=\
 bin/$(SJASMPLUS)

.PHONY: all
all: $(TOOLS)

$(TOOLS): | src/Makefile
	$(MAKE) -w -C src ../bin/$(@F)

.PHONY: clean
clean: | src/Makefile
	$(MAKE) -w -C src clean
