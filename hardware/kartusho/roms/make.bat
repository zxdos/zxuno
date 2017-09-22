echo  define version 0 > version.asm
call _make.bat
copy /y kartusho.bin kartusho4.rom
echo  define version 1 > version.asm
call _make.bat
copy /y kartusho.bin kartushoROM.rom
