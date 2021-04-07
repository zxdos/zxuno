@echo off
if not x%ZXUNOSDK% == x exit /b
set ZXUNOSDK=%~dp0
set ZXUNOSDK=%ZXUNOSDK:~0,-1%
set PATH=%ZXUNOSDK%;%PATH%
