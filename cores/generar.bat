call %ruta_bat%ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc %ruta_ucf%_zxuno_%1.ucf -p xc6slx9-tqg144-2 %machine%.ngc %machine%.ngd
call %ruta_bat%map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o %machine%_map.ncd %machine%.ngd %machine%.pcf
call %ruta_bat%par      -intstyle ise -w -ol high -mt 4 %machine%_map.ncd %machine%.ncd %machine%.pcf
call %ruta_bat%trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml %machine%.twx %machine%.ncd -o %machine%.twr %machine%.pcf
call %ruta_bat%bitgen   -intstyle ise -f %machine%.ut %machine%.ncd
copy /y %machine%.bit %machine%.%1.bit
