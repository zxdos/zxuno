#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

if [[ "x$ZXSDK" == x ]]; then
	ZXSDK=$(dirname $(realpath "$BASH_SOURCE"))
	Z88DK=$ZXSDK/src/z88dk
	ZCCCFG=$Z88DK/lib/config
	PATH=$ZXSDK/bin:$Z88DK/bin:$PATH
	# Fix paths under Cygwin for z88dk on Windows
	if [[ x$OS == xWindows_NT && x$OSTYPE == xcygwin ]]; then
		ZCCCFG=`cygpath -m $ZCCCFG`
	fi
	export ZXSDK
	export ZCCCFG
fi
