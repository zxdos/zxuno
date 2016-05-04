if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn APPLE2_TOP.xst -ofn APPLE2_TOP.syr
call :generar v2
call :generar v3
call :generar v4
call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc ..\source\apple2_zxuno_%1.ucf -p xc6slx9-tqg144-2 APPLE2_TOP.ngc APPLE2_TOP.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o APPLE2_TOP_map.ncd APPLE2_TOP.ngd APPLE2_TOP.pcf
call par      -intstyle ise -w -ol high -mt 4 APPLE2_TOP_map.ncd APPLE2_TOP.ncd APPLE2_TOP.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml APPLE2_TOP.twx APPLE2_TOP.ncd -o APPLE2_TOP.twr APPLE2_TOP.pcf
call bitgen   -intstyle ise -f APPLE2_TOP.ut APPLE2_TOP.ncd
copy /y apple2_top.bit Apple2.%1.bit
:eof