#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)

if [[ "x$ZXSDK" == x ]]; then
	export ZXSDK=$(dirname $(realpath "$BASH_SOURCE"))
	_path=$ZXSDK
	if [[ x$OS == xWindows_NT ]]; then
		case $PROCESSOR_ARCHITECTURE in
		X86|AMD64|EM64T)
			ZXSDK_PLATFORM=$ZXSDK/windows-x86
			;;
		*)
			echo "WARNING: Unsupported platform: \"$PROCESSOR_ARCHITECTURE\"" >&2
			ZXSDK_PLATFORM=$ZXSDK/unknown
			;;
		esac
	elif [[ x`uname -s` == xLinux ]]; then
		ZXSDK_PLATFORM=$ZXSDK/linux
	else
		echo "WARNING: Unsupported platform" >&2
		ZXSDK_PLATFORM=$ZXSDK/unknown
	fi
	export ZXSDK_PLATFORM
	_path=$_path:$ZXSDK_PLATFORM/bin
	if [[ x$OS == xWindows_NT ]]; then
		_path=$_path:$ZXSDK_PLATFORM/lib
	else
		export LD_LIBRARY_PATH=$ZXSDK_PLATFORM/lib
	fi
	export SDCCHOME=$ZXSDK_PLATFORM/opt/sdcc
	_path=$_path:$SDCCHOME/bin
	if [[ x$OS == xWindows_NT ]]; then
		SDCCINCLUDE=$SDCCHOME/include
	else
		SDCCINCLUDE=$SDCCHOME/share/sdcc/include
	fi
	export SDCCINCLUDE
	if [[ x$OS == xWindows_NT ]]; then
		SDCCLIB=$SDCCHOME/lib
	else
		SDCCLIB=$SDCCHOME/share/sdcc/lib
	fi
	export SDCCLIB
	Z88DK=$ZXSDK/src/z88dk
	_path=$_path:$Z88DK/bin
	ZCCCFG=$Z88DK/lib/config
	if [[ x$OS == xWindows_NT ]]; then
		# Fix paths under Cygwin for Z88DK on Windows
		if [[ x$OSTYPE == xcygwin ]]; then
			ZCCCFG=`cygpath -m $ZCCCFG`
		fi
	fi
	export ZCCCFG
	PATH=$_path:$PATH
	unset _path
fi
