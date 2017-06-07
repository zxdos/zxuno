call %ruta_bat%mypath
if not exist projnav.tmp mkdir projnav.tmp
%mypath%xst.exe -intstyle ise -ifn %machine%.xst -ofn %machine%.syr
