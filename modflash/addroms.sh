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

OnExit() {
	rm -f addroms.tmp
}

trap OnExit EXIT

awk -F \; '/^[^#]+/{print "AddROM " $1 " " $2 " " gensub(/\\/, "/", "g", $3)}' roms.txt >addroms.tmp
. ./addroms.tmp
