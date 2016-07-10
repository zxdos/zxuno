SET machine=sms
SET speed=3
SET ruta_ucf=src\sms
SET ruta_bat=..\
rem call %ruta_bat%genxst.bat
rem call %ruta_bat%generar.bat v2 src\sms_bd.bmm all.mem
rem call %ruta_bat%generar.bat v3 src\sms_bd.bmm all.mem
call %ruta_bat%generar.bat v4 src\sms_bd.bmm all.mem
rem call %ruta_bat%generar.bat Ap src\sms_bd.bmm all.mem
