# Common declarations for Makefiles.
#
# Supported environments:
#   * GNU/Linux
#   * Windows NT (using MinGW/MSYS/Cygwin/WSL)

ZXUNOSDK	:= $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
