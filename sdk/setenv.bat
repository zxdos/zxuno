@echo off
rem SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
rem
rem SPDX-License-Identifier: GPL-3.0-or-later

if not x%ZXSDK% == x exit /b
set ZXSDK=%~dp0
set ZXSDK=%ZXSDK:~0,-1%
set _path=%ZXSDK%
if %PROCESSOR_ARCHITECTURE% == X86 (
  set ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) else if %PROCESSOR_ARCHITECTURE% == AMD64 (
  set ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) else if %PROCESSOR_ARCHITECTURE% == EM64T (
  set ZXSDK_PLATFORM=%ZXSDK%\windows-x86
) else (
  echo WARNING: Unsupported processor architecture "%PROCESSOR_ARCHITECTURE%"
  set ZXSDK_PLATFORM=%ZXSDK%\unknown
)
set _path=%_path%;%ZXSDK_PLATFORM%\bin
set _path=%_path%;%ZXSDK_PLATFORM%\lib
set SDCCHOME=%ZXSDK_PLATFORM%\opt\sdcc
set _path=%_path%:%SDCCHOME%\bin
set SDCCINCLUDE=%SDCCHOME%\include
set SDCCLIB=%SDCCHOME%\lib
set Z88DK=%ZXSDK%\src\z88dk
set _path=%_path%;%Z88DK%\bin
set ZCCCFG=%Z88DK%\lib\config
set PATH=%_path%;%PATH%
set _path=
