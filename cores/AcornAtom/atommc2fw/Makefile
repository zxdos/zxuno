# Paths that will need changing

ATOMFPGA=$(HOME)/atom/AtomFpga
PAPILIO_LOADER=/opt/GadgetFactory/papilio-loader/programmer
XILINX=/opt/Xilinx/14.7

# Shouldn't need to make changes below this point

BIT_FILE=$(ATOMFPGA)/working/Atomic_top_duo.bit
BMM_FILE=$(ATOMFPGA)/src/Atomic_duo_bd.bmm


# Papilio dev environment
PROG=${PAPILIO_LOADER}/linux32/papilio-prog
BSCAN=${PAPILIO_LOADER}/bscan_spi_xc6slx9.bit
SREC_CAT=srec_cat
GAWK=gawk
DATA2MEM=${XILINX}/ISE_DS/ISE/bin/lin/data2mem

# AVR dev environment
MCU=atmega103
F_CPU=16000000
CC=avr-gcc
OBJCOPY=avr-objcopy

# Use these flags to include SDDOS (missing out serial console)
CFLAGS=-DF_CPU=${F_CPU}UL -mmcu=$(MCU) -Wall -Wstrict-prototypes -Os -mcall-prologues

# Use these flags to enable serial console (missing out SDDOS)
# CFLAGS=-DF_CPU=${F_CPU}UL -DSERIAL_STATUS -DCOOKED_SERIAL -DNOUSART1 -mmcu=$(MCU) -Wall -Wstrict-prototypes -Os -mcall-prologues

OBJECTS=atom-kbdio.o status.o atomio.o ff.o diskio.o mmcio.o atmmc2core.o atmmc2wfn.o wildcard.o

load: avr.bit
#	sudo $(PROG) -v -f avr.bit
	sudo $(PROG) -v -b $(BSCAN) -f avr.bit -sa -r
	sudo $(PROG) -c

avr.bit: avr_progmem.mem
	$(DATA2MEM) -bm $(BMM_FILE) -bd avr_progmem.mem -bt $(BIT_FILE) -o b avr.bit

avr_progmem.mem: avr_progmem.hex
	$(SREC_CAT)  $< -Intel -Byte_Swap 2  -Data_Only -o tmp.mem -vmem 8
	$(GAWK) ' BEGIN{FS=" ";} { $$1= ""; print}' tmp.mem > $@
	rm tmp.mem


avr_progmem.hex : avr_progmem.out 
	$(OBJCOPY) -R .eeprom -O ihex avr_progmem.out avr_progmem.hex 
avr_progmem.out : $(OBJECTS)
	$(CC) $(CFLAGS) -o avr_progmem.out -Wl,-Map,avr_progmem.map $^
%.o : %.c 
	$(CC) $(CFLAGS) -Os -c $<
%.o : %.S
	$(CC) $(CFLAGS) -Os -c $<

.phony: clean

clean:
	rm -f avr.bit avr_progmem.mem avr_progmem.hex avr_progmem.out avr_progmem.map *.o
