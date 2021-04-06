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
all: | FLASHempty.ZX1 $(GENROM) $(ADDITEM) ./addroms.sh ./addcores.sh
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
	rm -f FLASH.ZX1
else
	rm -f $(GENROM) $(ADDITEM) FLASH.ZX1
endif
