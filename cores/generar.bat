call %ruta_bat%mypath
%mypath%ngdbuild.exe -intstyle ise -dd _ngo -sd ipcore_dir -nt timestamp -uc %ruta_ucf%_zxuno_%1.ucf -p xc6slx9-tqg144-%speed% %machine%.ngc %machine%.ngd
%mypath%map.exe      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-%speed% -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o %machine%_map.ncd %machine%.ngd %machine%.pcf
%mypath%par.exe      -intstyle ise -w -ol high -mt 4 %machine%_map.ncd %machine%.ncd %machine%.pcf
%mypath%trce.exe     -intstyle ise -v 3 -s %speed% -n 3 -fastpaths -xml %machine%.twx %machine%.ncd -o %machine%.twr %machine%.pcf
%mypath%bitgen.exe   -intstyle ise -f %machine%.ut %machine%.ncd
%ruta_bat%bit2bin.exe %machine%.bit COREn.%2
copy /y %machine%.bit %machine%.%1.bit
