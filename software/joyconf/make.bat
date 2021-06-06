@echo off
rem sdcc -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node 30000 ^
rem --nostdlib --nostdinc --no-std-crt0 --out-fmt-s19 ^
rem --code-loc 32768 --data-loc 0 --stack-loc 65535 joyconf.c
rem s19tozx -i joyconf.s37 -o joyconf.tap
rem cgleches joyconf.tap joyconf.wav

sdcc -mz80 --reserve-regs-iy --opt-code-size --max-allocs-per-node 10000 ^
--nostdlib --nostdinc --no-std-crt0 --code-loc 8192 joyconf.c

makebin -p joyconf.ihx joyconf.bin
dd if=joyconf.bin of=JOYCONF bs=1 skip=8192 status=noxfer


