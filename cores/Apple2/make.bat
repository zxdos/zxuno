if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn build/APPLE2_TOP.xst -ofn build/APPLE2_TOP.syr
call :generar v2
call :generar v3
call :generar v4
call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc source/apple2_zxuno_%1.ucf -p xc6slx9-tqg144-2 build\APPLE2_TOP.ngc build\APPLE2_TOP.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o build\APPLE2_TOP_map.ncd build\APPLE2_TOP.ngd build\APPLE2_TOP.pcf
call par      -intstyle ise -w -ol high -mt 4 build\APPLE2_TOP_map.ncd build\APPLE2_TOP.ncd build\APPLE2_TOP.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml build\APPLE2_TOP.twx build\APPLE2_TOP.ncd -o build\APPLE2_TOP.twr build\APPLE2_TOP.pcf
call bitgen   -intstyle ise -f build\APPLE2_TOP.ut build\APPLE2_TOP.ncd
copy /y apple2_top.bit Apple2.%1.bit
:eof