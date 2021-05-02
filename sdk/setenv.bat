@echo off
rem SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
rem
rem SPDX-License-Identifier: GPL-3.0-or-later

if not x%ZXSDK% == x exit /b
set ZXSDK=%~dp0
set ZXSDK=%ZXSDK:~0,-1%
set Z88DK=%ZXSDK%\src\z88dk
set ZCCCFG=%Z88DK%\lib\config
set PATH=%ZXSDK%\bin;%Z88DK%\bin;%ZXSDK%\lib;%PATH%
