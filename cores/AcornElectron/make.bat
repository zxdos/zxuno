if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn working/ElectronFpga.xst -ofn working/ElectronFpga.syr
call :generar v2_v3
call :generar v4
call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc src/AcornElectron_zxuno_%1.ucf -p xc6slx9-tqg144-2 ElectronFpga.ngc ElectronFpga.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o ElectronFpga_map.ncd ElectronFpga.ngd ElectronFpga.pcf
call par      -intstyle ise -w -ol high -mt 4 ElectronFpga_map.ncd ElectronFpga.ncd ElectronFpga.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml ElectronFpga.twx ElectronFpga.ncd -o ElectronFpga.twr ElectronFpga.pcf
call bitgen   -intstyle ise -f working\ElectronFpga.ut ElectronFpga.ncd
copy /y electronfpga.bit AcornElectron.%1.bit
:eof