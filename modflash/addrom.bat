@echo off
set /a i=0
for /f "eol=# tokens=1,2,3 delims=;" %%a in (roms.txt) do call :AddROM %%a %%b %%c
exit /b

:AddROM
set /a i1=i+(%~z3)/16384-1
echo Adding ROM in slots %i%-%i1%: %2 (%3)...
GenRom %1 %2 %3 %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
AddItem ROM %i% %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
del %~n3.tap
set /a i=i1+1
exit /b

:Error
echo ERROR: Exit status %ERRORLEVEL%. Stopped.
exit %ERRORLEVEL% /b
