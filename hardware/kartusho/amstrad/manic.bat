@call ..\..\..\sdk\setenv.bat
rem 51F0-A4FF ep 6e3f
rem b900-bf7f
fcut Manic.sna 52F0 4a30 Manic.bin
saukav f1o5g0 Manic.bin
sjasmplus kartusho.asm
copy /y kartusho.rom \zesarux\src
