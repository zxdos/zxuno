# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# From https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/cross_compiling/Mingw

# the name of the target operating system
SET(CMAKE_SYSTEM_NAME Windows)

SET(MINGW_VER i686-w64-mingw32)
# which compilers to use for C and C++
SET(CMAKE_C_COMPILER ${MINGW_VER}-gcc)
SET(CMAKE_CXX_COMPILER ${MINGW_VER}-g++)
SET(CMAKE_RC_COMPILER ${MINGW_VER}-windres)
# here is the target environment located
SET(CMAKE_FIND_ROOT_PATH /usr/${MINGW_VER} )

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
