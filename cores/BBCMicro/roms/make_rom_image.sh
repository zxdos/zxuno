#!/bin/bash

cat smartmmc.rom.20151002 basic2.rom os12.rom os12.rom |  xxd -c1 -b | cut -c10-17 > ../src/rom_image.mif

