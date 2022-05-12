@echo off
pasmo --bin bootloader_copy_bram_to_sram.asm bootloader_copy_bram_to_sram.bin
bin2hex bootloader_copy_bram_to_sram.bin
