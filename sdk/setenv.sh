#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

if [[ "x$ZXSDK" == x ]]; then
	ZXSDK=$(dirname $(realpath "$BASH_SOURCE"))
	Z88DK=$ZXSDK/src/z88dk
	ZCCCFG=$Z88DK/lib/config
	PATH=$ZXSDK/bin:$Z88DK/bin:$PATH
	if [[ x$OS == xWindows_NT ]]; then
		PATH=$ZXSDK/lib:$PATH
		# Fix paths under Cygwin for z88dk on Windows
		if [[ x$OSTYPE == xcygwin ]]; then
			ZCCCFG=`cygpath -m $ZCCCFG`
		fi
	else
		export LD_LIBRARY_PATH=$ZXSDK/lib
	fi
	export ZXSDK
	export ZCCCFG
fi
