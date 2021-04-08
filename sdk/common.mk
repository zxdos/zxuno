# Common declarations for Makefiles.
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
