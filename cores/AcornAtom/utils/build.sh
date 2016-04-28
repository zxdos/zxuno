#!/bin/bash

rm -f *.rom

echo Assembling
ca65 -l serial.lst -oserial.o serial.asm

echo Linking
ld65 serial.o -o SERIAL -C serial.lkr 

echo Cleaning
rm -f *.o
