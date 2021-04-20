@echo off
rem SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
rem
rem SPDX-License-Identifier: GPL-3.0-or-later

if not x%ZXUNOSDK% == x exit /b
set ZXUNOSDK=%~dp0
set ZXUNOSDK=%ZXUNOSDK:~0,-1%
set Z88DK=%ZXUNOSDK%\src\z88dk
set ZCCCFG=%Z88DK%\lib\config
set PATH=%ZXUNOSDK%\bin;%Z88DK%\bin;%PATH%
