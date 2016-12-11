SET machine=hex_to_sseg_test
SET speed=2
SET ruta_ucf=ch03
SET ruta_bat=..\..\
rem call %ruta_bat%genxst.bat
rem call %ruta_bat%generar.bat v4

SET machine=sm_add_test
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v4
