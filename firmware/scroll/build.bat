@REM SPDX-FileType: SOURCE
@REM SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
@REM SPDX-FileNotice: Based on code by Antonio Villena <espineter@yahoo.com>
@REM SPDX-License-Identifier: GPL-3.0-or-later

SETLOCAL ENABLEEXTENSIONS
@IF NOT ERRORLEVEL 0 GOTO Error

CALL ..\..\sdk\setenv.bat
@IF NOT ERRORLEVEL 0 GOTO Error

IF EXIST conf.bat CALL conf.bat
@IF NOT ERRORLEVEL 0 GOTO Error

@IF "%VERSION%" == "" SET VERSION=1

@SET INCLUDEDIR=..\..\sdk\include
@SET AS=sjasmplus
@SET AFLAGS=--nologo -I%INCLUDEDIR% -Ibuild

@IF "%1" == "" GOTO Build
@IF "%1" == "build" GOTO Build
@IF "%1" == "clean" GOTO Clean
@IF "%1" == "distclean" GOTO DistClean

@ECHO ERROR: Unknown target: %1
@EXIT /B 1

:Build
IF NOT EXIST build MKDIR build
@IF NOT ERRORLEVEL 0 GOTO Error

IF %VERSION% == 1 Png2Rcs images\fondo.png build\fondo.rcs -a images\fondo.atr
@IF NOT ERRORLEVEL 0 GOTO Error

IF %VERSION% == 2 Png2Rcs images\fondo2.png build\fondo2.rcs -a images\fondo2.atr
@IF NOT ERRORLEVEL 0 GOTO Error

fontconv -q -f 6x8 fonts\fuente6x8.png build\fuente6x8.bin
@IF NOT ERRORLEVEL 0 GOTO Error

%AS% %AFLAGS% -DVERSION=%VERSION% --exp=build\scroll.exp --raw=build\scroll.bin scroll.asm
@IF NOT ERRORLEVEL 0 GOTO Error

@CALL :GetFileSize x build\scroll.bin
ECHO filesize: EQU %x% >build\define.asm
TYPE build\scroll.exp >>build\define.asm

zx7b build\scroll.bin build\scroll.bin.zx7b
@IF NOT ERRORLEVEL 0 GOTO Error

%AS% %AFLAGS% --raw=build\scrolldesc.bin scrolldesc.asm
@IF NOT ERRORLEVEL 0 GOTO Error

GenTape build\scroll.tap basic "SCROLL" 0 build\scrolldesc.bin
@IF NOT ERRORLEVEL 0 GOTO Error

@EXIT /B

:GetFileSize
@SET %1=%~z2
@EXIT /B

:Clean
IF EXIST build DEL /Q build\*
@IF NOT ERRORLEVEL 0 GOTO Error

@EXIT /B

:DistClean
IF EXIST build RMDIR /S /Q build
@IF NOT ERRORLEVEL 0 GOTO Error

@EXIT /B

:Error
@ECHO ERROR: Exit status %ERRORLEVEL%. Stopped.
@EXIT /B %ERRORLEVEL%
