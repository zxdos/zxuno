BASE	= /home/nestor/Projects/zpu/zpugcc/toolchain/install/bin/zpu-elf
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump


# A utility to convert binary ROM files into VHDL
ZPUFLEXDIR = ../../ZPUFlex
ROMGEN = $(ZPUFLEXDIR)/Firmware/zpuromgen

# we use mincrt0.s from here
STARTUP_DIR = $(ZPUFLEXDIR)/Firmware/startup

# we fetch ROM prologue / epilogue from here
RTL_DIR = $(ZPUFLEXDIR)/RTL/

BUILD_DIR=zpu_obj

MINSTARTUP_SRC = $(STARTUP_DIR)/mincrt0.s $(STARTUP_DIR)/premain.s
MINSTARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(MINSTARTUP_SRC))


# We need to use different compilation options for OSD.c.  Most of the code is compiled with
# -mnoshortop -mnobyteop to avoid our hardware having to deal with 8- or 16-bit memory accesses.
# However, the character ROM is 8-bit oriented, so we need to use byte ops when compiling
# osd.c
HW_SRC = osd.c
HW_OBJ = $(COMMON_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.hwo,$(HW_SRC))

# Regular C files

MAIN_PRJ = CtrlROM
MAIN_SRC = main.c interrupts.c keyboard.c ps2.c menu.c spi.c minfat.c swap.c fileselector.c
MAIN_OBJ = $(HW_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_SRC))

LINKMAP  = $(ZPUFLEXDIR)/Firmware/standalone_simple.ld


# Commandline options for each tool.

# Instruct GCC not to emit instructions that we're neither implementing nor emulating.
# (N.B. No-neg requires bugfixed toolchain)
ZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-shortop -mno-byteop -mno-neg -mno-div -mno-mod

HWZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-neg -mno-div -mno-mod

CFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(ZPUOPTS) -ffunction-sections -fdata-sections $(FWOPTS)
HWCFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(HWZPUOPTS) -ffunction-sections -fdata-sections $(FWOPTS)
LFLAGS  = -nostartfiles -nostdlib -Wl,--relax -Wl,--gc-sections -Os -g
LIBS = -lgcc


# Our target.
all: $(BUILD_DIR) $(MAIN_PRJ).bin $(MAIN_PRJ)_ROM.vhd $(MAIN_PRJ).rpt

clean:
	rm -f $(BUILD_DIR)/*.o *.hex *.elf *.map *.lst *.srec $(MAIN_PRJ).rom *~ */*.o *.bin


# Convert ELF binary to bin file.
%.bin: %.elf
	$(CP) -O binary $< $@

%.rpt: %.elf
	echo >$@ -n "End of code:\t"
	$(DUMP) -x $< | grep >>$@ _romend
	echo >>$@ -n "Start of BSS:\t"
	$(DUMP) -x $< | grep  >>$@ __bss_start__
	echo >>$@ -n "End of BSS:\t"
	$(DUMP) -x $< | grep >>$@ __bss_end__
	cat $@

$(ROMGEN): $(ZPUFLEXDIR)/Firmware/zpuromgen.c
	gcc -o $(ZPUFLEXDIR)/Firmware/zpuromgen $(ZPUFLEXDIR)/Firmware/zpuromgen.c

%_ROM.vhd: %.bin $(ROMGEN)
	sed 's/dualportram/$*_ROM/' >$*_ROM.vhd <$(RTL_DIR)/rom_prologue.vhd
	$(ROMGEN) $*.bin >>$*_ROM.vhd
	cat >>$*_ROM.vhd $(RTL_DIR)/rom_epilogue.vhd

# Link - this produces an ELF binary.

$(MAIN_PRJ).elf: $(MINSTARTUP_OBJ) $(MAIN_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.hwo: %.c Makefile
	$(CC) $(HWCFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(COMMON_DIR)/%.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(AS) -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(AS) -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

