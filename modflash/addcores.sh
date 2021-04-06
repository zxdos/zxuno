#!/bin/bash -e
GENROM=./GenRom
ADDITEM=./AddItem
i=2

Error() {
	echo "ERROR: Exit status $1. Stopped." >&2
	exit $1
}

AddCore() {
	local f=${3%.*}.tap
	echo "Adding core $i: \"$2\" ($3)..."
	$GENROM $1 "$2" $3 $f || Error $?
	$ADDITEM CORE$i $f || Error $?
	rm -f $f
	let i+=1
}

OnExit() {
        rm -f addcores.tmp
}

trap OnExit EXIT

awk -F \; '/^[^#]+/{print "AddCore " $1 " " $2 " " gensub(/\\/, "/", "g", $3)}' cores.txt >addcores.tmp
. ./addcores.tmp