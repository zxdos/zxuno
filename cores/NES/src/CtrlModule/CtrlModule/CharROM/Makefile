BASE	= 
CC      = $(BASE)gcc
LD      = $(BASE)gcc
AS      = $(BASE)as
CP      = $(BASE)objcopy
DUMP    = $(BASE)objdump

ROMGEN = charromgen

MAIN_PRJ = CharROM
MAIN_SRC = CharROM.s
MAIN_OBJ = $(patsubst %.s,%.bin,$(MAIN_SRC))


all: $(MAIN_PRJ).bin $(MAIN_PRJ)_ROM.vhd

clean:
	rm -f *.bin $(MAIN_PRJ)_ROM.vhd $(ROMGEN) $(MAIN_PRJ).o


# Convert ELF binary to bin file.
%.bin: %.o
	$(CP) -O binary $< $@

%.o: %.s Makefile
	$(CC) -c -o $@ $<

$(ROMGEN): $(ROMGEN).c
	gcc -o $@ $<
#	gcc -o $(ROMGENDIR)/$(ROMGEN) $(ROMGENDIR)/romgen.c

%_ROM.vhd: %.bin $(ROMGEN)
	sed 's/soc_firmware/$*_ROM/' >$*_ROM.vhd <bitrom_prologue.vhd
	./$(ROMGEN) $*.bin >>$*_ROM.vhd
	cat >>$*_ROM.vhd bitrom_epilogue.vhd

