SET speed=2
SET ruta_ucf=ch04
SET ruta_bat=..\..\
call :genbitstream disp_mux_test
call :genbitstream hex_mux_test
call :genbitstream stop_watch_test
call :genbitstream fifo_test
goto :eof

:genbitstream
SET machine=%1
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v4 ZX1
copy /y COREn.ZX1 %ruta_ucf%_%machine%.ZX1
goto :eof
