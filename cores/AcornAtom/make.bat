if not exist projnav.tmp mkdir projnav.tmp
call xst      -intstyle ise -ifn working/Atomic_top_zxuno.xst -ofn working/Atomic_top_zxuno.syr
call :generar v2
call :generar v3
rem  call :generar v4
rem  call :generar Ap
goto :eof

:generar
call ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc src/Atomic_zxuno_%1.ucf -p xc6slx9-tqg144-2 -bm src/Atomic_zxuno.bmm Atomic_top_zxuno.ngc Atomic_top_zxuno.ngd
call map      -intstyle ise -w -ol high -mt 2 -p xc6slx9-tqg144-2 -logic_opt off -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -ir off -pr off -lc off -power off -o Atomic_top_zxuno_map.ncd Atomic_top_zxuno.ngd Atomic_top_zxuno.pcf
call par      -intstyle ise -w -ol high -mt 4 Atomic_top_zxuno_map.ncd Atomic_top_zxuno.ncd Atomic_top_zxuno.pcf
call trce     -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml Atomic_top_zxuno.twx Atomic_top_zxuno.ncd -o Atomic_top_zxuno.twr Atomic_top_zxuno.pcf
call bitgen   -intstyle ise -w -g Compress -g DebugBitstream:No -g Binary:no -g CRC:Enable -g Reset_on_err:No -g ConfigRate:2 -g ProgPin:PullUp -g TckPin:PullUp -g TdiPin:PullUp -g TdoPin:PullUp -g TmsPin:PullUp -g UnusedPin:PullUp -g UserID:0xFFFFFFFF -g ExtMasterCclk_en:No -g SPI_buswidth:1 -g TIMER_CFG:0xFFFF -g multipin_wakeup:No -g StartUpClk:CClk -g DONE_cycle:4 -g GTS_cycle:5 -g GWE_cycle:6 -g LCK_cycle:NoWait -g Security:None -g DonePipe:No -g DriveDone:No -g en_sw_gsr:No -g drive_awake:No -g sw_clk:Startupclk -g sw_gwe_cycle:5 -g sw_gts_cycle:4 Atomic_top_zxuno.ncd
copy /y Atomic_top_zxuno.bit AcornAtom.%1.bit
:eof