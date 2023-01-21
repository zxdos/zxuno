#!/bin/bash -e
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov
# SPDX-FileNotice: Based on code by Antonio Villena <_@antoniovillena.es>
# SPDX-License-Identifier: GPL-3.0-or-later

source ../sdk/setenv.sh

i=2

AddCore() {
	local f=${3%.*}.tap
	echo "Adding core $i: \"$2\" ($3)..."
	GenRom $1 "$2" $3 $f
	AddItem CORE$i $f
	rm -f $f
	let i+=1
}

OnError() {
	local err=$?
	echo "ERROR: Exit status $err. Stopped." >&2
	exit $err
}

OnExit() {
        rm -f addcores.tmp
}

trap OnError ERR
trap OnExit EXIT

awk -F \; '/^[^#]+/{print "AddCore " $1 " " $2 " " gensub(/\\/, "/", "g", $3)}' cores.txt >addcores.tmp
. ./addcores.tmp
