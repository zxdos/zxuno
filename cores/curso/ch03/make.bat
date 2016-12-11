SET speed=2
SET ruta_ucf=ch03
SET ruta_bat=..\..\
call :genbitstream hex_to_sseg_test
call :genbitstream sm_add_test
call :genbitstream shifter_test
call :genbitstream fp_adder_test
goto :eof

:genbitstream
SET machine=%1
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v4 ZX1
copy /y COREn.ZX1 %ruta_bat%.ZX1
goto :eof
