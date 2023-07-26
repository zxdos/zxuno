@echo off
setlocal

FOR %%A IN (%1) DO set size=%%~zA

fpad 120000 0 padzero.int
copy /b %1+padzero.int intfile.int

echo %size%
fcut intfile.int 0 120000 %203.ZX3
if %size% GTR 1179648 fcut intfile.int 120000 120000 %204.ZX3
if %size% GTR 2359296 fcut intfile.int 240000 120000 %205.ZX3
if %size% GTR 3538944 fcut intfile.int 360000 120000 %206.ZX3
if %size% GTR 4718592 fcut intfile.int 360000 120000 %207.ZX3
