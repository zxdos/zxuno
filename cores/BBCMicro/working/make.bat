SET machine=bbc_micro
SET ruta_ucf=..\src\bbc_micro
SET ruta_bat=..\..\
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v2_v3
call %ruta_bat%generar.bat v4
call %ruta_bat%generar.bat Ap
