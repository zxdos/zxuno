@call ..\sdk\setenv.bat
sjasmplus firmware.asm
zx7b firmware_strings.rom firmware.rom.zx7b 
sjasmplus bootloader.asm
bin2hex bootloader.rom
copy /y bootloader.hex ..\cores\Spectrum\bootloader_hex.txt
