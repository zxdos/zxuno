#!/bin/bash

rm -f *.rom

echo Assembling
ca65 -l sddos.lst -osddos.o -DAVR sdromraw.asm

echo Linking
ld65 sddos.o -o sddos.rom -C sddos.lkr 

echo Cleaning
rm -f *.o
