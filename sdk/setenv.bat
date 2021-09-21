@REM SPDX-FileType: SOURCE
@REM SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
@REM SPDX-License-Identifier: GPL-3.0-or-later

@IF NOT "%ZXSDK%" == "" EXIT /b

@SET ZXSDK=%~dp0
@SET ZXSDK=%ZXSDK:~0,-1%
@SET _path=%ZXSDK%

@REM *** Platform ***

@IF "%PROCESSOR_ARCHITECTURE%" == "X86" (
  SET ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) ELSE IF "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  SET ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) ELSE IF "%PROCESSOR_ARCHITECTURE%" == "EM64T" (
  SET ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) ELSE (
  ECHO WARNING: Unsupported processor architecture: %PROCESSOR_ARCHITECTURE%
  SET ZXSDK_PLATFORM=%ZXSDK%\unknown
)
@SET _path=%_path%;%ZXSDK_PLATFORM%\bin
@SET _path=%_path%;%ZXSDK_PLATFORM%\lib

@REM *** SDCC ***

@SET SDCCHOME=%ZXSDK_PLATFORM%\opt\sdcc
@SET _path=%_path%;%SDCCHOME%\bin
@SET SDCCINCLUDE=%SDCCHOME%\include
@SET SDCCLIB=%SDCCHOME%\lib

@REM *** z88dk ***

@SET Z88DK=%ZXSDK_PLATFORM%\opt\z88dk
@SET _path=%_path%;%Z88DK%\bin
@SET ZCCCFG=%Z88DK%\lib\config

@REM *** PATH variable ***

@SET PATH=%_path%;%PATH%
@SET _path=
