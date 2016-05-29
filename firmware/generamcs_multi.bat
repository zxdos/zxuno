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
GenRom 0 sm1ta Machine tmp.bin core_taps\SPECTRUM.TAP
rem CgLeches core_taps\SPECTRUM.TAP core_wavs\SPECTRUM.WAV 4
call :CreateMachine CORE2 "Sam Coupe"        SamCoupe\tld_sam.%2.bit 0 %3
call :CreateMachine CORE3 "Jupiter ACE"      JupiterAce\jupiter_ace.%2.bit JupiterAce\jupiter_ace.v2_v3.bit %3
call :CreateMachine CORE4 "Master System"    ..\..\zxuno\cores\sms_v2_spartan6\test4\sms_final_v4.bit 0 %3
call :CreateMachine CORE5 "Oric Atmos"       ..\..\zxuno\cores\oric_spartan6\test1\build\oric_v4.bit \zxuno\cores\oric_spartan6\test1\build\oric.bit %3
call :CreateMachine CORE6 "BBC Micro"        ..\..\zxuno\cores\BBCMicro\test3\working\bbc_micro_%2.bit 0 %3
call :CreateMachine CORE7 "Apple 2 (VGA)"    ..\..\zxuno\cores\Apple2_spartan6\test2\build\apple2_top_%2.bit 0 %3
call :CreateMachine CORE8 "Acorn Atom (VGA)" ..\..\zxuno\cores\acorn_atom_spartan6\test2\working\atomic_top_zxuno_%2.bit 0 %3
call :CreateMachine CORE9 "NES (VGA)"        NES\xilinx\nes_zxuno.%2.bit 0 %3
copy /y rom_binaries\esxdos.rom sd_binaries\ESXDOS.%3
copy /y firmware.rom sd_binaries\FIRMWARE.%3
GenRom 0 sm1t BIOS firmware.rom core_taps\FIRMWARE.TAP
GenRom 0 0    ESXDOS rom_binaries\esxdos.rom core_taps\ESXDOS.TAP
call :CreateRom 0  "ZX Spectrum 48K Cargando Leches" leches         dn   lh
call :CreateRom 1  "ZX +2A 4.1"                    plus3en41        t    0
call :CreateRom 5  "SE Basic IV 4.0 Anya"          se               d    h1
call :CreateRom 7  "ZX Spectrum 48K"               48               dn   lh17
AddItem ROM     8   rom_taps\rooted.tap
call :CreateRom 9  "Inves Spectrum+"               inves            0    lh17
call :CreateRom 10 "Zx Spectrum +2"                plus2en          t    h1
call :CreateRom 12 "Pentagon 128"                  pentagon         pc   h1
call :CreateRom 14 "Jet Pac (1983)"                JetPac           0    lh17
call :CreateRom 15 "Pssst (1983)"                  Pssst            0    lh17
call :CreateRom 16 "Cookie (1983)"                 Cookie           0    lh17
call :CreateRom 17 "Tranz Am (1983)"               TranzAm          0    lh17
call :CreateRom 18 "Master Chess (1983)"           MasterChess      0    lh17
call :CreateRom 19 "Backgammon (1983)"             Backgammon       0    lh17
call :CreateRom 20 "Hungry Horace (1983)"          HungryHorace     0    lh17
call :CreateRom 21 "Horace & the Spiders (1983)"   HoraceSpiders    0    lh17
call :CreateRom 22 "Planetoids (1983)"             Planetoids       0    lh17
call :CreateRom 23 "Space Raiders (1983)"          SpaceRaiders     0    lh17
call :CreateRom 24 "Deathchase (1983)"             Deathchase       0    lh17
call :CreateRom 25 "Manic Miner (1983)"            ManicMiner       0    lh17
call :CreateRom 26 "Misco Jones (2013)"            MiscoJones       0    lh17
call :CreateRom 27 "Jet Set Willy (1984)"          JetSetWilly      0    lh17
call :CreateRom 28 "Lala Prologue (2010)"          LalaPrologue     0    lh17
fcut FLASH.ZX1 006000 001041 tmp.bin
fcut FLASH.ZX1 00c000 04c000 tmp1.bin
fcut FLASH.ZX1 34c000 0b4000 tmp2.bin
copy /by tmp.bin+tmp1.bin+tmp2.bin sd_binaries\ROMS.%3
del tmp.bin tmp1.bin tmp2.bin
move /y FLASH.ZX1 sd_binaries\FLASH.%3
goto :eof

:CreateMachine
IF EXIST ..\cores\%3 (
  Bit2Bin ..\cores\%3 sd_binaries\%1.%5
) ELSE ( 
  Bit2Bin ..\cores\%4 sd_binaries\%1.%5
)
GenRom 0 0 %2 sd_binaries\%1.%5 core_taps\%1.TAP
AddItem %1 core_taps\%1.tap
rem CgLeches core_taps\%1.TAP core_wavs\%1.WAV 4
goto :eof

:CreateRom
GenRom %4 %5 %2 rom_binaries\%3.rom rom_taps\%3.tap
AddItem ROM %1 rom_taps\%3.tap
rem CgLeches rom_taps\%3.tap rom_wavs\%3.wav 4
:eof
