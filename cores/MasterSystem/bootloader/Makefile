CC = zcc
LD = zcc

CFLAGS = +sms #-DDEBUG #-DDEBUG_FAT

C_FILES=main.c console.c debug.c sd.c fat.c
OBJECT_FILES=$(C_FILES:%.c=%.o)

PATH_EMU=/home/backup/workspace/JSMS
EMU=java -cp $(PATH_EMU)/bin/ org.jsms.awt.SwingJsms

all.mem: vram.mem boot.mem
	cat boot.mem vram.mem > all.mem

boot.mem: boot.o
	srec_cat boot.o -binary -line_length 59 -o boot.mem -vmem 8

vram.mem: font.mem
	cat font.mem > vram.mem

font.mem: font.bin
	srec_cat font.bin -binary -offset 0x8400 -line_length 59 -o font.mem -vmem 8


boot.o: $(OBJECT_FILES)
	$(LD) $(CFLAGS) $(OBJECT_FILES) -o $@ -m

%.o: %.c
	$(CC) $(CFLAGS) -c $<

crt0.opt: crt0.asm
	cp $< $@





run: boot.sms vram.bin
	$(EMU) -vram vram.bin boot.sms

boot.sms: boot.o
	srec_cat boot.o -binary -fill 0 0 0x8000 -o boot.sms -binary

vram.bin: vram.mem
	srec_cat vram.mem -vmem -offset -0x8000 -fill 0 0 0x4000 -o vram.bin -binary


clean:
	rm -f *.o *.opt boot.map zcc_opt.def
	rm -f *.mem vram.bin boot.sms

