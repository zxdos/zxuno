@echo off

rem romgen bios4-1.bin cart_rom 12 a r e > Bios4k-1.vhd
rem romgen bios1-2.bin cart_rom 10 a r e > Bios1k-2.vhd
rem romgen bios1-3.bin cart_rom 10 a r e > Bios1k-3.vhd
rem romgen bios2-4.bin cart_rom 11 a r e > Bios2k-4.vhd

romgen coleco.rom biosx 13 a r e > Biosx.vhd

pause

echo done