# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

ifeq ($(OS),Windows_NT)
GENROM	= GenRom.exe
ADDITEM	= AddItem.exe
else
GENROM	= GenRom
ADDITEM	= AddItem
endif

.PHONY: all
all: | FLASHempty.ZX1 $(GENROM) $(ADDITEM) ./addroms.sh ./addcores.sh roms.txt cores.txt
	cp FLASHempty.ZX1 FLASH.ZX1
	./addroms.sh
	./addcores.sh

ifneq ($(OS),Windows_NT)
$(GENROM): GenRom.c
	$(CC) $(CFLAGS) $< -o $@

$(ADDITEM): AddItem.c
	$(CC) $(CFLAGS) $< -o $@
endif

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	# Nothing to do
else
	rm -f $(GENROM) $(ADDITEM)
endif

.PHONY: dist-clean
dist-clean: clean
	rm -f FLASH.ZX1
