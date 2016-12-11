SET speed=2
SET ruta_ucf=ch04
SET ruta_bat=..\..\
rem call :genbitstream disp_mux_test
call :genbitstream hex_mux_test
rem call :genbitstream shifter_test
rem call :genbitstream fp_adder_test
goto :eof

:genbitstream
SET machine=%1
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v4 ZX1
copy /y COREn.ZX1 %machine%.ZX1
goto :eof
