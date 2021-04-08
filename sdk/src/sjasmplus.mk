# Build:
#   make -w -C sjasmplus -f ../sjasmplus.mk
# Clean:
#   make -w -C sjasmplus -f ../sjasmplus.mk clean
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

ifeq ($(OS),Windows_NT)
SJASMPLUS	:= sjasmplus.exe
else
SJASMPLUS	:= sjasmplus
endif

build/$(SJASMPLUS): | build/Makefile
	$(MAKE) -w -C build

build/Makefile: | build
	cd build && cmake ..

build:
	mkdir -p build

.PHONY: clean
clean: | build/Makefile
	$(MAKE) -w -C build clean
