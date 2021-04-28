@call ..\sdk\setenv.bat
echo  define version 1 > version.asm
sjasmplus firmware.asm
fcut      firmware_strings.rom  7e00 -7e00  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  FIRMWARE.ZX1
echo  define version 2 > version.asm
sjasmplus firmware.asm
fcut      firmware_strings.rom  7e00 -7e00  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  FIRMWARE.ZX2
echo  define version 3 > version.asm
sjasmplus firmware.asm
fcut      firmware_strings.rom  7e00 -7e00  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  FIRMWARE.ZXD
echo  define version 4 > version.asm
sjasmplus firmware.asm
fcut      firmware_strings.rom  7e00 -7e00  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  FIRMWARE.ZX3
rem GenRom sm12 BIOS firmware.rom firm.TAP
rem cgleches firm.tap firm.wav 3
rem firm.wav
