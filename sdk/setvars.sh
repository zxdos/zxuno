#!/bin/bash -e
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

if [[ "x$ZXUNOSDK" == x ]]; then
	ZXUNOSDK=$(dirname $(realpath "$BASH_SOURCE"))
	PATH=$ZXUNOSDK/bin:$PATH
	export ZXUNOSDK
fi
