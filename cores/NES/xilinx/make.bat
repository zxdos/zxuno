SET machine=NES_ZXUNO
SET ruta_ucf=..\src\nes
SET ruta_bat=..\..\
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v2
call %ruta_bat%generar.bat v3
call %ruta_bat%generar.bat v4
call %ruta_bat%generar.bat Ap
