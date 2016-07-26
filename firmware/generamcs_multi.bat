set output=\Google Drive\Proyecto ZX-Uno\cores_%2\
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
fcut tmp.bin 0 53f00 "%output%sd_binaries\SPECTRUM.%3"
GenRom sm12a Machine tmp.bin "%output%core_taps\SPECTRUM.TAP"
rem CgLeches "%output%core_taps\SPECTRUM.TAP" "%output%core_wavs\SPECTRUM.WAV" 3
call :CreateMachine set1 CORE2 "Sam Coupe"        SamCoupe\tld_sam.%2.bit 0 %3
call :CreateMachine set1 CORE3 "Jupiter ACE"      JupiterAce\jupiter_ace.%2.bit JupiterAce\jupiter_ace.v2_v3.bit %3
call :CreateMachine set1 CORE4 "Master System"    MasterSystem\sms.%2.bit 0 %3
call :CreateMachine set1 CORE5 "BBC Micro"        BBCMicro\working\bbc_micro.%2.bit BBCMicro\working\bbc_micro.v2_v3.bit %3
call :CreateMachine set1 CORE6 "Acorn Electron"   AcornElectron\working\ElectronFpga.%2.bit AcornElectron\working\ElectronFpga.v2_v3.bit %3
call :CreateMachine set1 CORE7 "Oric Atmos"       Oric\build\oric.%2.bit Oric\build\oric.v2_v3.bit %3
call :CreateMachine set1 CORE8 "Test PAL/NTSC"    test\test_pal_ntsc\tld_test_pal_ntsc.%2.bit test\test_pal_ntsc\tld_test_pal_ntsc.v2_v3.bit %3
call :CreateMachine set1 CORE9 "Test Color Bars"  test\barras_de_color\tld_zxuno.%2.bit test\barras_de_color\tld_zxuno.v2_v3.bit %3
copy /y rom_binaries\esxdos.rom "%output%sd_binaries\ESXDOS.%3"
copy /y firmware.rom "%output%sd_binaries\FIRMWARE.%3"
GenRom sm12 BIOS firmware.rom "%output%core_taps\FIRMWARE.TAP"
rem CgLeches "%output%core_taps\FIRMWARE.TAP" "%output%core_wavs\FIRMWARE.WAV" 3
GenRom 0    ESXDOS rom_binaries\esxdos.rom "%output%core_taps\ESXDOS.TAP"
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
copy /by tmp.bin+tmp1.bin+tmp2.bin "%output%sd_binaries\ROMS.%3"
rem cambiar el 400000 siguiente línea por 100000 si 25Q80
fcut FLASH.ZX1 0 400000 tmp.bin
del tmp1.bin tmp2.bin
copy /y tmp.bin "%output%sd_binaries\set1\FLASH.%3"
call :CreateMachine set2 CORE2 "Sam Coupe"        SamCoupe\tld_sam.%2.bit 0 %3
call :CreateMachine set2 CORE3 "Jupiter ACE"      JupiterAce\jupiter_ace.%2.bit JupiterAce\jupiter_ace.v2_v3.bit %3
call :CreateMachine set2 CORE4 "Master System"    MasterSystem\sms.%2.bit 0 %3
call :CreateMachine set2 CORE5 "NES (VGA)"        NES\xilinx\NES_ZXUNO.%2.bit 0 %3
call :CreateMachine set2 CORE6 "Atari 2600 (VGA)" Atari2600\zxuno\zxuno_a2601.%2.bit 0 %3
call :CreateMachine set2 CORE7 "Acorn Atom (VGA)" AcornAtom\working\Atomic_top_zxuno.%2.bit 0 %3
call :CreateMachine set2 CORE8 "Apple 2 (VGA)"    Apple2\build\apple2_top.%2.bit 0 %3
call :CreateMachine set2 CORE9 "VIC-20 (VGA)"     VIC20\ise\VIC20.%2.bit VIC20\ise\VIC20.v2_v3.bit %3
fpoke FLASH.ZX1 07044 g020302020200000002
rem cambiar el 400000 siguiente línea por 100000 si 25Q80
fcut FLASH.ZX1 0 400000 tmp.bin
copy /y tmp.bin "%output%sd_binaries\set2\FLASH.%3"
goto :eof

:CreateMachine
IF EXIST ..\cores\%4 (
  Bit2Bin ..\cores\%4 "%output%sd_binaries\%1\%2.%6"
) ELSE ( 
  Bit2Bin ..\cores\%5 "%output%sd_binaries\%1\%2.%6"
)
GenRom 0 %3 "%output%sd_binaries\%1\%2.%6" "%output%core_taps\%1\%2.TAP"
AddItem %2 "%output%core_taps\%1\%2.tap"
rem CgLeches "%output%core_taps\%2.TAP" "%output%core_wavs\%2.WAV" 3
goto :eof

:CreateRom
GenRom %4 %2 rom_binaries\%3.rom rom_taps\%3.tap
AddItem ROM %1 rom_taps\%3.tap
rem CgLeches rom_taps\%3.TAP rom_wavs\%3.WAV 3
:eof
