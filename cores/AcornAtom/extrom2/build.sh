#!/bin/bash

ROM=extrom2

# Build the PIC version
ca65 -l${ROM}.lst  -o ${ROM}.o ${ROM}.asm 
ld65 ${ROM}.o -o ${ROM}.rom  -C atom.cfg 
cp ${ROM}.rom ../roms/atom_bbc_ext2.rom

# Build the AVR version
ca65 -DAVR -l${ROM}.lst  -o ${ROM}.o ${ROM}.asm 
ld65 ${ROM}.o -o ${ROM}.rom  -C atom.cfg 
cp ${ROM}.rom ../roms/atom_bbc_ext2_avr.rom

