if not exist strings.bin.zx7b echo > strings.bin.zx7b
if not exist version.asm echo  define version 1 > version.asm
sjasmplus firmware.asm
fcut      firmware_strings.rom  7e00 -7e00  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  firmware.rom
copy /y firmware.rom FIRMWARE.ZX1
rem GenRom sm12 BIOS firmware.rom firm.TAP
rem cgleches firm.tap firm.wav 3
rem firm.wav
