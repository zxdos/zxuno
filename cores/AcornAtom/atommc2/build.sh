#!/bin/bash

rm -f *.rom

echo Assembling
ca65 -l atomm2.a000.lst -o a000.o -DAVR atommc2.asm
ca65 -l atomm2.e000.lst -o e000.o -DAVR -D EOOO atommc2.asm

echo Linking
ld65 a000.o -o atommc2-2.9-a000.rom -C atommc2-a000.lkr 
ld65 e000.o -o atommc2-2.9-e000.rom -C atommc2-e000.lkr 

echo Cleaning
rm -f *.o
