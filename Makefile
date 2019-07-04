all: ugoph.bin

ugoph.bin: *.asm *.pg
	sjasmplus main.asm

clean: 
	rm ugoph.bin
