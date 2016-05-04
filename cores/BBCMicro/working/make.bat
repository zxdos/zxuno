SET machine = "bbc_micro"
if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn %machine%.xst -ofn %machine%.syr
call :generar v2 %machine%
call :generar v3 %machine%
call :generar v4 %machine%
call :generar Ap %machine%
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc ..\src\%2_zxuno_%1.ucf -p xc6slx9-tqg144-2 %2.ngc %2.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o %2_map.ncd %2.ngd %2.pcf
call par      -intstyle ise -w -ol high -mt 4 %2_map.ncd %2.ncd %2.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml %2.twx %2.ncd -o %2.twr %2.pcf
call bitgen   -intstyle ise -f %2.ut %2.ncd
copy /y %2.bit %2.%1.bit
:eof