CP = copy
RM = rm -f
CC = sdcc
AS = sdasz80
LD = sdcc
H2B = hex2bin
ROMGEN = romgen

SDIR = src
IDIR = inc
ODIR = obj

CFLAGS = -mz80 --opt-code-size --fomit-frame-pointer -I$(IDIR) -I..
LDFLAGS = -mz80 --code-loc 0x0100 --data-loc 0x6000 --no-std-crt0

_OBJS = crt0.rel main.rel vdp.rel mmc.rel joy.rel fat.rel
OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

all: dir loader

loader: loader.bin
	fillfile $< 8192
	$(ROMGEN) $< loaderrom a r > ../../src/rom/loaderrom.vhd

loader.bin: loader.ihx

loader.ihx: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

.PHONY: clean dir

clean:
	$(RM) $(ODIR)/* *.map *.lk *.noi *.bin *.ihx

dir:
	if not exist obj mkdir obj

$(ODIR)/%.rel: $(SDIR)/%.S
	$(AS) -o $@ $<

$(ODIR)/%.rel: $(SDIR)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.bin: %.ihx
	$(H2B) -e bin $<
