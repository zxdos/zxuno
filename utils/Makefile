# Supported environments:
#   * GNU on Linux, FreeBSD etc.
#   * GNU on Windows NT (using MinGW/MSYS/Cygwin/WSL)
#
# Build:
#   make
# Clean:
#   make clean
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

include ../sdk/common.mk

BUILD_DIR	= build
AS		= sjasmplus
AFLAGS		= --nobanner

TARGETS=\
 BACK16M\
 BACKZX2\
 BACKZXD\
 BACKUP\
 CORCLEAN\
 COREBIOS\
 ROMSBACK\
 ROMSUPGR\
 UPGR16M\
 UPGRZX2\
 UPGRZXD\
 UPGRADE

.PHONY: all
all: $(foreach t,$(TARGETS),$(BUILD_DIR)/$(t))

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/BACK16M: back16m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/BACKZX2: back32m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	echo ' define zxdos 1' >back32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f back32m.def

$(BUILD_DIR)/BACKZXD: back32m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	echo ' define zxdos 0' >back32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f back32m.def

$(BUILD_DIR)/BACKUP: backup.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/CORCLEAN: corclean.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/COREBIOS: corebios.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/ROMSBACK: romsback.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/ROMSUPGR: romsupgr.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/UPGR16M: upgr16m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

$(BUILD_DIR)/UPGRZX2: upgr32m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	echo ' define zxdos 1' >upgr32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f upgr32m.def

$(BUILD_DIR)/UPGRZXD: upgr32m.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	echo ' define zxdos 0' >upgr32m.def
	$(AS) $(AFLAGS) --raw=$@ $<
	rm -f upgr32m.def

$(BUILD_DIR)/UPGRADE: upgrade.asm\
 zxuno.inc\
 | $(BUILD_DIR)
	$(AS) $(AFLAGS) --raw=$@ $<

.PHONY: clean
clean:
	rm -f back32m.def upgr32m.def
	rm -f $(foreach t,$(TARGETS),$(BUILD_DIR)/$(t))
