if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn tld_zxuno.xst -ofn tld_zxuno.syr
call :generar v2
call :generar v3
call :generar v4
call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc pines_zxuno_%1.ucf -p xc6slx9-tqg144-2 tld_zxuno.ngc tld_zxuno.ngd
call map      -intstyle ise -w -ol high -xe n -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o tld_zxuno_map.ncd tld_zxuno.ngd tld_zxuno.pcf
call par      -intstyle ise -w -ol high -xe n -mt 4 tld_zxuno_map.ncd tld_zxuno.ncd tld_zxuno.pcf
call trce     -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml tld_zxuno.twx tld_zxuno.ncd -o tld_zxuno.twr tld_zxuno.pcf -ucf pines_zxuno_%1.ucf
call bitgen   -intstyle ise -w -g Binary:no -g Compress -g CRC:Enable -g Reset_on_err:No -g ConfigRate:2 -g ProgPin:PullUp -g TckPin:PullUp -g TdiPin:PullUp -g TdoPin:PullUp -g TmsPin:PullUp -g UnusedPin:PullDown -g UserID:0xFFFFFFFF -g ExtMasterCclk_en:Yes -g ExtMasterCclk_divide:50 -g SPI_buswidth:1 -g TIMER_CFG:0xFFFF -g multipin_wakeup:No -g StartUpClk:CClk -g DONE_cycle:4 -g GTS_cycle:5 -g GWE_cycle:6 -g LCK_cycle:NoWait -g Security:None -g DonePipe:No -g DriveDone:No -g en_sw_gsr:No -g drive_awake:No -g sw_clk:Startupclk -g sw_gwe_cycle:5 -g sw_gts_cycle:4 tld_zxuno.ncd
copy /y tld_zxuno.bit zxuno.%1.bit
:eof