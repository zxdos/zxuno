@call ..\sdk\setvars.bat
set output=\Google Drive\Proyecto ZX-Uno\cores_%2\
echo  define version %1 > version.asm
call  make.bat
Bit2Bin ..\cores\Spectrum\tld_zxuno.%2.bit tmp.bin
fpad 400000 00 FLASH.ZX1
fpoke FLASH.ZX1 00000 file:header.bin               ^
                04000 file:rom_binaries\esxdos.rom  ^
                07000 40xFF                         ^
                07044 g020302020202                 ^
                08000 file:firmware.rom             ^
                58000 file:tmp.bin
fcut tmp.bin 0 53f00 "%output%sd_binaries\SPECTRUM.%3"
GenRom sm12a Machine tmp.bin "%output%core_taps\SPECTRUM.TAP"
rem CgLeches "%output%core_taps\SPECTRUM.TAP" "%output%core_wavs\SPECTRUM.WAV" 3
call :CreateMachine set1 CORE2 "Sam Coupe"        ..\zxuno\stable\binaries\SamCoupe\COREX.ZX1 %3
call :CreateMachine set1 CORE3 "Jupiter ACE"      ..\zxuno\stable\binaries\JupiterAce\COREX.ZX1 %3
call :CreateMachine set1 CORE4 "Master System"    ..\zxuno\stable\binaries\SMS\COREX.ZX1 %3
call :CreateMachine set1 CORE5 "BBC Micro"        ..\zxuno\stable\binaries\BBCMicro\COREX.ZX1 %3
call :CreateMachine set1 CORE6 "Atari 800 XL"     ..\zxuno\stable\binaries\Atari800XL\COREX.ZX1 %3
call :CreateMachine set1 CORE7 "VIC-20"           ..\zxuno\stable\binaries\VIC20\COREX.ZX1 %3
call :CreateMachine set1 CORE8 "Apple 2 (VGA)"    ..\zxuno\stable\binaries\AppleII\COREX.ZX1 %3
call :CreateMachine set1 CORE9 "NES (VGA)"        ..\zxuno\stable\binaries\NES\COREX.ZX1 %3
copy /y rom_binaries\esxdos.rom "%output%sd_binaries\ESXDOS.%3"
copy /y firmware.rom "%output%sd_binaries\FIRMWARE.%3"
GenRom sm12 BIOS firmware.rom "%output%core_taps\FIRMWARE.TAP"
rem CgLeches "%output%core_taps\FIRMWARE.TAP" "%output%core_wavs\FIRMWARE.WAV" 3
GenRom 0    ESXDOS rom_binaries\esxdos.rom "%output%core_taps\ESXDOS.TAP"
call :CreateRom 0  "ZX Spectrum 48K"               48               xdnlh17
call :CreateRom 1  "ZX +2A 4.1"                    plus3en41        xt
call :CreateRom 5  "SE Basic IV 4.0 Anya"          se               xdh1
call :CreateRom 7  "ZX Spectrum 48K Cargando Leches" leches         xdlh
AddItem ROM     8   "%output%..\rom_taps\rooted.tap"
call :CreateRom 9  "Inves Spectrum+"               inves            xlh17
call :CreateRom 10 "ZX Spectrum +2"                plus2en          xth1
call :CreateRom 12 "Pentagon 128"                  pentagon         xpch1
call :CreateRom 14 "Jet Pac (1983)"                JetPac           xlh17
call :CreateRom 15 "Pssst (1983)"                  Pssst            xlh17
call :CreateRom 16 "Cookie (1983)"                 Cookie           xlh17
call :CreateRom 17 "Tranz Am (1983)"               TranzAm          xlh17
call :CreateRom 18 "Master Chess (1983)"           MasterChess      xlh17
call :CreateRom 19 "Backgammon (1983)"             Backgammon       xlh17
call :CreateRom 20 "Hungry Horace (1983)"          HungryHorace     xlh17
call :CreateRom 21 "Horace & the Spiders (1983)"   HoraceSpiders    xlh17
call :CreateRom 22 "Planetoids (1983)"             Planetoids       xlh17
call :CreateRom 23 "Space Raiders (1983)"          SpaceRaiders     xlh17
call :CreateRom 24 "Deathchase (1983)"             Deathchase       xlh17
call :CreateRom 25 "Manic Miner (1983)"            ManicMiner       xlh17
call :CreateRom 26 "Misco Jones (2013)"            MiscoJones       xlh17
call :CreateRom 27 "Jet Set Willy (1984)"          JetSetWilly      xlh17
call :CreateRom 28 "Lala Prologue (2010)"          LalaPrologue     xlh17
fcut FLASH.ZX1 006000 001041 tmp.bin
fcut FLASH.ZX1 00c000 04c000 tmp1.bin
fcut FLASH.ZX1 34c000 0b4000 tmp2.bin
copy /by tmp.bin+tmp1.bin+tmp2.bin "%output%sd_binaries\ROMS.%3"
rem cambiar el 400000 siguiente línea por 100000 si 25Q80
fcut FLASH.ZX1 0 400000 tmp.bin
del tmp1.bin tmp2.bin
copy /y tmp.bin "%output%sd_binaries\set1\FLASH.%3"
goto :eof

:CreateMachine
copy /y ..\%4 "%output%sd_binaries\%1\%2.%5"
GenRom 0 %3 "%output%sd_binaries\%1\%2.%5" "%output%core_taps\%1\%2.tap"
AddItem %2 "%output%core_taps\%1\%2.tap"
rem CgLeches "%output%core_taps\%2.TAP" "%output%core_wavs\%2.WAV" 3
goto :eof

:CreateRom
GenRom %4 %2 rom_binaries\%3.rom "%output%..\rom_taps\%3.tap"
AddItem ROM %1 "%output%..\rom_taps\%3.tap"
rem CgLeches "%output%..\rom_taps\%3.TAP" rom_wavs\%3.WAV 3
:eof
