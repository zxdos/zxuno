@call ..\..\sdk\setvars.bat
FuenteABin
Png2Rcs fondo.png fondo.rcs -a fondo.atr
sjasmplus scroll.asm
call :getfilesize scroll.bin
echo  define  filesize %_filesize% > define.asm
zx7b scroll.bin scroll.bin.zx7b
sjasmplus scrolldesc.asm
GenTape scroll.tap basic "SCROLL" 0 scrolldesc.bin
goto :eof

:getfilesize
set _filesize=%~z1
goto :eof
