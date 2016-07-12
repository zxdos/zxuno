SET machine=ElectronFpga
SET speed=2
SET ruta_ucf=..\src\AcornElectron
SET ruta_bat=..\..\
call %ruta_bat%genxst.bat
rem call %ruta_bat%generar.bat v2_v3
call %ruta_bat%generar.bat v4
rem call %ruta_bat%generar.bat Ap
