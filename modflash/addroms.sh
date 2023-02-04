#!/bin/bash -e
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov
# SPDX-FileNotice: Based on code by Antonio Villena <_@antoniovillena.es>
# SPDX-License-Identifier: GPL-3.0-or-later

source ../sdk/setenv.sh

i=0

AddROM() {
	local n=`stat --printf "%s" $3`
	local i1=$((i+n/16384-1))
	local f=${3%.*}.tap
	echo "Adding ROM in slots $i-$i1: \"$2\" ($3)..."
	GenRom $1 "$2" $3 $f
	AddItem ROM $i $f
	rm -f $f
	let i=i1+1
}

OnError() {
	local err=$?
	echo "ERROR: Exit status $err. Stopped." >&2
	exit $err
}

OnExit() {
	rm -f addroms.tmp
}

trap OnError ERR
trap OnExit EXIT

awk -F \; '/^[^#]+/{print "AddROM " $1 " " $2 " " gensub(/\\/, "/", "g", $3)}' roms.txt >addroms.tmp
. ./addroms.tmp
