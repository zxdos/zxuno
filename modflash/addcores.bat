@echo off
rem SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
rem
rem SPDX-FileNotice: Based on code by Antonio Villena <_@antoniovillena.es>
rem
rem SPDX-License-Identifier: GPL-3.0-or-later

call ..\sdk\setvars.bat

set /a i=2
for /f "eol=# tokens=1,2,3 delims=;" %%a in (cores.txt) do call :AddCore %%a %%b %%c
exit /b

:AddCore
echo Adding core %i%: %2 (%3)...
GenRom %1 %2 %3 %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
AddItem CORE%i% %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
del %~n3.tap
set /a i+=1
exit /b

:Error
echo ERROR: Exit status %ERRORLEVEL%. Stopped.
exit /b %ERRORLEVEL%
