@echo off
rem SPDX-FileCopyrightText: 2016, 2021 Antonio Villena
rem
rem SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
rem
rem SPDX-License-Identifier: GPL-3.0-only

call ..\..\sdk\setenv.bat

set FuenteABin=tools\build\FuenteABin
set AS=sjasmplus
set AFLAGS="-I%ZXSDK%\include"

%FuenteABin% fuente6x8.png fuente6x8.bin
Png2Rcs fondo.png fondo.rcs -a fondo.atr
%AS% %AFLAGS% --exp=scroll.exp --raw=scroll.bin scroll.asm
call :getfilesize _filesize scroll.bin
echo  define filesize %_filesize% > define.asm
type scroll.exp >> define.asm
zx7b scroll.bin scroll.bin.zx7b
%AS% %AFLAGS% --raw=scrolldesc.bin scrolldesc.asm
GenTape scroll.tap basic "SCROLL" 0 scrolldesc.bin

rem Clean
del /q fuente6x8.bin fondo.rcs scroll.exp scroll.bin define.asm scroll.bin.zx7b scrolldesc.bin >nul

goto :eof

:getfilesize
set %1=%~z2
goto :eof
