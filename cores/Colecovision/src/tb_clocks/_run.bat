vlib work
IF ERRORLEVEL 1 GOTO error
vcom ..\clocks.vhd
IF ERRORLEVEL 1 GOTO error
vcom tb_clocks.vht
IF ERRORLEVEL 1 GOTO error
vsim -t ns tb -do all.do
IF ERRORLEVEL 1 GOTO error

goto ok

:error
echo Error!
pause

:ok
