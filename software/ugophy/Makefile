all: ugoph.bin

player.bin: vtpl.asm
	sjasmplus vtpl.asm

ugoph.bin: *.asm player.bin
	sjasmplus main.asm

clean: 
	rm ugoph.bin
