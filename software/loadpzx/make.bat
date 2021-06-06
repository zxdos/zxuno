@echo off
del loadpzx.bin
del loadpzx.ihx
del LOADPZX

sdcc -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node 10000 ^
--nostdlib --nostdinc --no-std-crt0 --code-loc 8192 --data-loc 12288 loadpzx.c

makebin -p loadpzx.ihx loadpzx.bin
dd if=loadpzx.bin of=LOADPZX bs=1 skip=8192


