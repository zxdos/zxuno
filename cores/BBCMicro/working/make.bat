SET machine=bbc_micro
if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn %machine%.xst -ofn %machine%.syr
call :generar v2
call :generar v3
call :generar v4
call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc ..\src\%machine%_zxuno_%1.ucf -p xc6slx9-tqg144-2 %machine%.ngc %machine%.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o %machine%_map.ncd %machine%.ngd %machine%.pcf
call par      -intstyle ise -w -ol high -mt 4 %machine%_map.ncd %machine%.ncd %machine%.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml %machine%.twx %machine%.ncd -o %machine%.twr %machine%.pcf
call bitgen   -intstyle ise -f %machine%.ut %machine%.ncd
copy /y %machine%.bit %machine%.%1.bit
:eof