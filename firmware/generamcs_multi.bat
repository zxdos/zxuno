echo  define version %1 > version.asm
call  make.bat
Bit2Bin ..\cores\Spectrum\tld_zxuno.%2.bit tmp.bin
fpad 400000 00 FLASH.ZX1
fpoke FLASH.ZX1 00000 file:header.bin               ^
                04000 file:rom_binaries\esxdos.rom  ^
                07000 40xFF                         ^
                07044 g0203020202                   ^
                08000 file:firmware.rom             ^
                58000 file:tmp.bin
fcut tmp.bin 0 53f00 sd_binaries\SPECTRUM.%3
GenRom sm12a Machine tmp.bin core_taps\SPECTRUM.TAP
rem CgLeches core_taps\SPECTRUM.TAP core_wavs\SPECTRUM.WAV 3
call :CreateMachine set1 CORE2 "Sam Coupe"        %2 SamCoupe\tld_sam.%2.bit 0 %3
call :CreateMachine set1 CORE3 "Jupiter ACE"      %2 JupiterAce\jupiter_ace.%2.bit JupiterAce\jupiter_ace.v2_v3.bit %3
call :CreateMachine set1 CORE4 "Master System"    %2 MasterSystem\sms.%2.bit 0 %3
call :CreateMachine set1 CORE5 "BBC Micro"        %2 BBCMicro\working\bbc_micro.%2.bit BBCMicro\working\bbc_micro.v2_v3.bit %3
call :CreateMachine set1 CORE6 "Acorn Electron"   %2 AcornElectron\working\ElectronFpga.%2.bit AcornElectron\working\ElectronFpga.v2_v3.bit %3
call :CreateMachine set1 CORE7 "Oric Atmos"       %2 Oric\build\oric.%2.bit Oric\build\oric.v2_v3.bit %3
call :CreateMachine set1 CORE8 "Test PAL/NTSC"    %2 test\test_pal_ntsc\tld_test_pal_ntsc.%2.bit test\test_pal_ntsc\tld_test_pal_ntsc.v2_v3.bit %3
call :CreateMachine set1 CORE9 "Test Color Bars"  %2 test\barras_de_color\tld_zxuno.%2.bit test\barras_de_color\tld_zxuno.v2_v3.bit %3
copy /y rom_binaries\esxdos.rom sd_binaries\ESXDOS.%3
copy /y firmware.rom "\Google Drive\Proyecto ZX-Uno\cores_%2\sd_binaries\FIRMWARE.%3"
GenRom sm12 BIOS firmware.rom "\Google Drive\Proyecto ZX-Uno\cores_%2\core_taps\FIRMWARE.TAP"
rem CgLeches core_taps\FIRMWARE.TAP core_wavs\FIRMWARE.WAV 3
GenRom 0    ESXDOS rom_binaries\esxdos.rom core_taps\ESXDOS.TAP
call :CreateRom 0  "ZX Spectrum 48K"               48               dnlh17
call :CreateRom 1  "ZX +2A 4.1"                    plus3en41        t
call :CreateRom 5  "SE Basic IV 4.0 Anya"          se               dh1
call :CreateRom 7  "ZX Spectrum 48K Cargando Leches" leches         dlh
AddItem ROM     8   rom_taps\rooted.tap
call :CreateRom 9  "Inves Spectrum+"               inves            lh17
call :CreateRom 10 "Zx Spectrum +2"                plus2en          th1
call :CreateRom 12 "Pentagon 128"                  pentagon         pch1
call :CreateRom 14 "Jet Pac (1983)"                JetPac           lh17
call :CreateRom 15 "Pssst (1983)"                  Pssst            lh17
call :CreateRom 16 "Cookie (1983)"                 Cookie           lh17
call :CreateRom 17 "Tranz Am (1983)"               TranzAm          lh17
call :CreateRom 18 "Master Chess (1983)"           MasterChess      lh17
call :CreateRom 19 "Backgammon (1983)"             Backgammon       lh17
call :CreateRom 20 "Hungry Horace (1983)"          HungryHorace     lh17
call :CreateRom 21 "Horace & the Spiders (1983)"   HoraceSpiders    lh17
call :CreateRom 22 "Planetoids (1983)"             Planetoids       lh17
call :CreateRom 23 "Space Raiders (1983)"          SpaceRaiders     lh17
call :CreateRom 24 "Deathchase (1983)"             Deathchase       lh17
call :CreateRom 25 "Manic Miner (1983)"            ManicMiner       lh17
call :CreateRom 26 "Misco Jones (2013)"            MiscoJones       lh17
call :CreateRom 27 "Jet Set Willy (1984)"          JetSetWilly      lh17
call :CreateRom 28 "Lala Prologue (2010)"          LalaPrologue     lh17
fcut FLASH.ZX1 006000 001041 tmp.bin
fcut FLASH.ZX1 00c000 04c000 tmp1.bin
fcut FLASH.ZX1 34c000 0b4000 tmp2.bin
copy /by tmp.bin+tmp1.bin+tmp2.bin sd_binaries\ROMS.%3
rem cambiar el 400000 siguiente línea por 100000 si 25Q80
fcut FLASH.ZX1 0 400000 tmp.bin
srec_cat  tmp.bin -binary             ^
          -o "\Google Drive\Proyecto ZX-Uno\cores_%2\flash_set1.%2.mcs" -Intel ^
          -line-length=44             ^
          -line-termination=nl
del tmp1.bin tmp2.bin
copy /y tmp.bin "\Google Drive\Proyecto ZX-Uno\cores_%2\sd_binaries\set1\FLASH.%3"
call :CreateMachine set2 CORE2 "NES (VGA)"        %2 NES\xilinx\NES_ZXUNO.%2.bit 0 %3
call :CreateMachine set2 CORE3 "Atari 2600 (VGA)" %2 Atari2600\zxuno\zxuno_a2601.%2.bit 0 %3
call :CreateMachine set2 CORE4 "Acorn Atom (VGA)" %2 AcornAtom\working\Atomic_top_zxuno.%2.bit 0 %3
call :CreateMachine set2 CORE5 "Apple 2 (VGA)"    %2 Apple2\build\apple2_top.%2.bit 0 %3
call :CreateMachine set2 CORE6 "VIC-20 (VGA)"     %2 VIC20\ise\VIC20.%2.bit VIC20\ise\VIC20.v2_v3.bit %3
call :CreateMachine set2 CORE7 "Master System"    %2 MasterSystem\sms.%2.bit 0 %3
call :CreateMachine set2 CORE8 "Test Interlaced"  %2 test\test_pal_interlaced_progressive\tld_test_pal_intprog.%2.bit test\test_pal_interlaced_progressive\tld_test_pal_intprog.v2_v3.bit %3
call :CreateMachine set2 CORE9 "Test SRAM-Video"  %2 test\test_sram_y_video\tld_zxuno.%2.bit test\test_sram_y_video\tld_zxuno.v2_v3.bit %3
fpoke FLASH.ZX1 07044 g020302020200000002
rem cambiar el 400000 siguiente línea por 100000 si 25Q80
fcut FLASH.ZX1 0 400000 tmp.bin
srec_cat  tmp.bin -binary             ^
          -o "\Google Drive\Proyecto ZX-Uno\cores_%2\flash_set2.%2.mcs" -Intel ^
          -line-length=44             ^
          -line-termination=nl
copy /y tmp.bin "\Google Drive\Proyecto ZX-Uno\cores_%2\sd_binaries\set2\FLASH.%3"
goto :eof

:CreateMachine
IF EXIST ..\cores\%5 (
  Bit2Bin ..\cores\%5 "\Google Drive\Proyecto ZX-Uno\cores_%4\sd_binaries\%1\%2.%7"
) ELSE ( 
  Bit2Bin ..\cores\%6 "\Google Drive\Proyecto ZX-Uno\cores_%4\sd_binaries\%1\%2.%7"
)
GenRom 0 %3 "\Google Drive\Proyecto ZX-Uno\cores_%4\sd_binaries\%1\%2.%7" "\Google Drive\Proyecto ZX-Uno\cores_%4\core_taps\%1\%2.TAP"
AddItem %2 "\Google Drive\Proyecto ZX-Uno\cores_%4\core_taps\%1\%2.tap"
rem CgLeches core_taps\%1.TAP core_wavs\%1.WAV 3
goto :eof

:CreateRom
GenRom %4 %2 rom_binaries\%3.rom rom_taps\%3.tap
AddItem ROM %1 rom_taps\%3.tap
rem CgLeches rom_taps\%3.tap rom_wavs\%3.wav 3
:eof
