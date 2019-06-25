all: ugoph.tap

ugoph.tap: *.asm *.pg
	sjasmplus main.asm

clean: 
	rm *.tap
