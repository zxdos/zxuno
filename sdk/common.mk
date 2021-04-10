# Common declarations for Makefiles.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

ifndef ZXUNOSDK

ZXUNOSDK	:= $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
PATH		:= $(ZXUNOSDK)/bin:$(PATH)

export ZXUNOSDK
export PATH

endif
