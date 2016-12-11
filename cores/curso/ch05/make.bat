SET speed=2
SET ruta_ucf=ch05
SET ruta_bat=..\..\
call :genbitstream debounce_test
goto :eof

:genbitstream
SET machine=%1
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v4 ZX1
copy /y COREn.ZX1 %ruta_ucf%_%machine%.ZX1
goto :eof
