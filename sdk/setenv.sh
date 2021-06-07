#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

if [[ "x$ZXSDK" == x ]]; then
	ZXSDK=$(dirname $(realpath "$BASH_SOURCE"))
	if [[ x$OS == xWindows_NT ]]; then
		ZXSDK_PLATFORM=$ZXSDK/windows-x86
	else
		ZXSDK_PLATFORM=$ZXSDK
	fi
	Z88DK=$ZXSDK/src/z88dk
	ZCCCFG=$Z88DK/lib/config
	PATH=$ZXSDK_PLATFORM/bin:$Z88DK/bin:$ZXSDK:$PATH
	if [[ x$OS == xWindows_NT ]]; then
		PATH=$ZXSDK_PLATFORM/lib:$PATH
		# Fix paths under Cygwin for z88dk on Windows
		if [[ x$OSTYPE == xcygwin ]]; then
			ZCCCFG=`cygpath -m $ZCCCFG`
		fi
	else
		export LD_LIBRARY_PATH=$ZXSDK_PLATFORM/lib
	fi
	export ZXSDK
	export ZXSDK_PLATFORM
	export ZCCCFG
fi
