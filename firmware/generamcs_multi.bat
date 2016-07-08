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
GenRom sm1ta Machine tmp.bin core_taps\SPECTRUM.TAP
rem CgLeches core_taps\SPECTRUM.TAP core_wavs\SPECTRUM.WAV 3
call :CreateMachine CORE2 "Sam Coupe"        SamCoupe\tld_sam.%2.bit 0 %3
call :CreateMachine CORE3 "Jupiter ACE"      JupiterAce\jupiter_ace.%2.bit JupiterAce\jupiter_ace.v2_v3.bit %3
call :CreateMachine CORE4 "Master System"    MasterSystem\sms.%2.bit 0 %3
call :CreateMachine CORE5 "Oric Atmos"       Oric\build\oric.%2.bit Oric\build\oric.v2_v3.bit %3
call :CreateMachine CORE6 "BBC Micro"        BBCMicro\working\bbc_micro.%2.bit BBCMicro\working\bbc_micro.v2_v3.bit %3
call :CreateMachine CORE7 "Apple 2 (VGA)"    Apple2\build\apple2_top.%2.bit 0 %3
call :CreateMachine CORE8 "Acorn Atom (VGA)" AcornAtom\working\Atomic_top_zxuno.%2.bit 0 %3
call :CreateMachine CORE9 "NES (VGA)"        NES\xilinx\NES_ZXUNO.%2.bit 0 %3
copy /y rom_binaries\esxdos.rom sd_binaries\ESXDOS.%3
copy /y firmware.rom sd_binaries\FIRMWARE.%3
GenRom sm1t BIOS firmware.rom core_taps\FIRMWARE.TAP
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
srec_cat  tmp.bin -binary       ^
          -o prom.%2.mcs -Intel ^
          -line-length=44       ^
          -line-termination=nl
del tmp1.bin tmp2.bin
move /y tmp.bin sd_binaries\FLASH.%3
goto :eof

:CreateMachine
IF EXIST ..\cores\%3 (
  Bit2Bin ..\cores\%3 sd_binaries\%1.%5
) ELSE ( 
  Bit2Bin ..\cores\%4 sd_binaries\%1.%5
)
GenRom 0 %2 sd_binaries\%1.%5 core_taps\%1.TAP
AddItem %1 core_taps\%1.tap
rem CgLeches core_taps\%1.TAP core_wavs\%1.WAV 3
goto :eof

:CreateRom
GenRom %4 %2 rom_binaries\%3.rom rom_taps\%3.tap
AddItem ROM %1 rom_taps\%3.tap
rem CgLeches rom_taps\%3.tap rom_wavs\%3.wav 3
:eof
