#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-FileNotice: Based on code by Antonio Villena <_@antoniovillena.es>
#
# SPDX-License-Identifier: GPL-3.0-or-later

i=2

Error() {
	echo "ERROR: Exit status $1. Stopped." >&2
	exit $1
}

AddCore() {
	local f=${3%.*}.tap
	echo "Adding core $i: \"$2\" ($3)..."
	GenRom $1 "$2" $3 $f || Error $?
	AddItem CORE$i $f || Error $?
	rm -f $f
	let i+=1
}

OnExit() {
        rm -f addcores.tmp
}

trap OnExit EXIT

awk -F \; '/^[^#]+/{print "AddCore " $1 " " $2 " " gensub(/\\/, "/", "g", $3)}' cores.txt >addcores.tmp
. ./addcores.tmp
