SET machine=VIC20
SET speed=3
SET ruta_ucf=..\source\vic20
SET ruta_bat=..\..\
call %ruta_bat%genxst.bat
call %ruta_bat%generar.bat v2_v3
call %ruta_bat%generar.bat v4
call %ruta_bat%generar.bat Ap
