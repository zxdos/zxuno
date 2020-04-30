vlib work
IF ERRORLEVEL 1 GOTO error
vcom ..\..\ram\dpram.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vga.vhd
IF ERRORLEVEL 1 GOTO error

vcom tb_vga.vht
IF ERRORLEVEL 1 GOTO error
vsim -t ns tb -do all.do
IF ERRORLEVEL 1 GOTO error

goto ok

:error
echo Error!
pause

:ok
