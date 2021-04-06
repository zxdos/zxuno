@echo off
set /a i=0
call :AddROM xdnlh17  "ZX Spectrum 48K"      roms\48.rom
call :AddROM xtdnh1   "ZX Spectrum 128K EN"  roms\128en.rom
call :AddROM xt       "ZX Spectrum +2A EN"   roms\plus3en41.rom
call :AddROM xdlh     "48K Cargando Leches"  roms\leches.rom
call :AddROM xdnlh17  "Inves Spectrum+"      roms\inves.rom
call :AddROM xdnlh17  "Microdigital TK95"    roms\tk95.rom
call :AddROM xdnlh17  "Looking Glass 1.07"   roms\lg18v07.rom
call :AddROM xdnmlh17 "Timex Computer 2048"  roms\tc2048.rom
call :AddROM xmh1     "Timex Computer 2068"  roms\tc2068.rom
call :AddROM xpch1    "Pentagon 128"         roms\pentagon.rom
call :AddROM xdlh17   "Pokemon"              roms\pokemon48.rom
call :AddROM xdnlh17  "Gosh Wonderful v1.33" roms\gw03v33.rom
call :AddROM xdh1     "SE Basic IV 4.0 Anya" roms\se.rom
call :AddROM xtdnh1   "Derby+"               roms\derbyp.rom
call :AddROM xt       "DivMMC +3e ES 1.43"   roms\plus3es143.rom
call :AddROM xt       "Next +3e 1.53"        roms\next.rom
call :AddROM xth1ru   "BBC Micro"            roms\BBCBasic.rom
call :AddROM xth1ru   "Jupiter Ace"          roms\jupace.rom
call :AddROM xth1ru   "ZX81"                 roms\zx81.rom
call :AddROM xlh17ru  "Manic Miner (1983)"   roms\ManicMiner.rom
call :AddROM xlh17ru  "Jet Set Willy (1984)" roms\JetSetWilly.rom
call :AddROM xlh17ru  "Jet Pac (1983)"       roms\JetPac.rom
call :AddROM xlh17ru  "Cookie (1983)"        roms\Cookie.rom
call :AddROM xlh17ru  "Tranz Am (1983)"      roms\TranzAm.rom
call :AddROM xlh17ru  "Planetoids (1983)"    roms\Planetoids.rom
call :AddROM xlh17ru  "Space Raiders (1983)" roms\SpaceRaiders.rom
call :AddROM xlh17ru  "Misco Jones (2013)"   roms\MiscoJones.rom
exit /b

:AddROM
set /a i1=i+(%~z3)/16384-1
echo Adding ROM in slots %i%-%i1%: %2 (%3)...
GenRom %1 %2 %3 %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
AddItem ROM %i% %~n3.tap
if not %ERRORLEVEL% == 0 goto Error
del %~n3.tap
set /a i=i1+1
exit /b

:Error
echo ERROR: Exit status %ERRORLEVEL%. Stopped.
exit %ERRORLEVEL% /b
