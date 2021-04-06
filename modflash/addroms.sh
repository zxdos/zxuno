#!/bin/bash -e
GENROM=./GenRom
ADDITEM=./AddItem
i=0

Error() {
	echo "ERROR: Exit status $1. Stopped." >&2
	exit $1
}
AddROM() {
	local n=`stat --printf "%s" $3`
	local i1=$((i+n/16384-1))
	local f=${3%.*}.tap
	echo "Adding ROM in slots $i-$i1: \"$2\" ($3)..."
	$GENROM $1 "$2" $3 $f || Error $?
	$ADDITEM ROM $i $f || Error $?
	rm -f $f
	let i=i1+1
}

AddROM xdnlh17  "ZX Spectrum 48K"      roms/48.rom
AddROM xtdnh1   "ZX Spectrum 128K EN"  roms/128en.rom
AddROM xt       "ZX Spectrum +2A EN"   roms/plus3en41.rom
AddROM xdlh     "48K Cargando Leches"  roms/leches.rom
AddROM xdnlh17  "Inves Spectrum+"      roms/inves.rom
AddROM xdnlh17  "Microdigital TK95"    roms/tk95.rom
AddROM xdnlh17  "Looking Glass 1.07"   roms/lg18v07.rom
AddROM xdnmlh17 "Timex Computer 2048"  roms/tc2048.rom
AddROM xmh1     "Timex Computer 2068"  roms/tc2068.rom
AddROM xpch1    "Pentagon 128"         roms/pentagon.rom
AddROM xdlh17   "Pokemon"              roms/pokemon48.rom
AddROM xdnlh17  "Gosh Wonderful v1.33" roms/gw03v33.rom
AddROM xdh1     "SE Basic IV 4.0 Anya" roms/se.rom
AddROM xtdnh1   "Derby+"               roms/derbyp.rom
AddROM xt       "DivMMC +3e ES 1.43"   roms/plus3es143.rom
AddROM xt       "Next +3e 1.53"        roms/next.rom
AddROM xth1ru   "BBC Micro"            roms/BBCBasic.rom
AddROM xth1ru   "Jupiter Ace"          roms/jupace.rom
AddROM xth1ru   "ZX81"                 roms/zx81.rom
AddROM xlh17ru  "Manic Miner (1983)"   roms/ManicMiner.rom
AddROM xlh17ru  "Jet Set Willy (1984)" roms/JetSetWilly.rom
AddROM xlh17ru  "Jet Pac (1983)"       roms/JetPac.rom
AddROM xlh17ru  "Cookie (1983)"        roms/Cookie.rom
AddROM xlh17ru  "Tranz Am (1983)"      roms/TranzAm.rom
AddROM xlh17ru  "Planetoids (1983)"    roms/Planetoids.rom
AddROM xlh17ru  "Space Raiders (1983)" roms/SpaceRaiders.rom
AddROM xlh17ru  "Misco Jones (2013)"   roms/MiscoJones.rom
