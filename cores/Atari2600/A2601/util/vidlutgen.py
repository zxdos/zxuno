# Generates lookup tables for A2601 NTSC encoding
# Copyright 2006, 2010 Retromaster
#
#  This file is part of A2601.
#
#  A2601 is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License,
#  or any later version.
#
#  A2601 is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with A2601.  If not, see <http://www.gnu.org/licenses/>.

import sys

fout = open(sys.argv[1], 'w')

from math import sin;
from math import radians;

# dac_range_min = 0
# sync_level_ire = 0

dac_low = 5.0;
dac_high = 255.0;
dac_range_volts = 1.5;
dac_range_max = 255.0;
sync_to_white_volts = 1.0;
blank_level_ire = 40.0;
black_level_ire = 47.5;
#white_level_ire = 140.0;
white_level_ire = 80.0;
lum_steps = 8;
col_steps = 15;
#col_wave_steps = 4;
#col_wave_steps = 8;
col_wave_steps = 16;
col_saturation_ire = 10.0;
col_phase_start = 180;
col_step_delay = -27.06;

volts_dac_step = dac_range_max / dac_range_volts;
ire_volts = sync_to_white_volts / white_level_ire;
lum_step_ire = (white_level_ire - black_level_ire) / (lum_steps - 1);

fout.write("library ieee;\n");
fout.write("use ieee.std_logic_1164.all;\n");
fout.write("use ieee.numeric_std.all;\n");
fout.write("\n");
fout.write("package TIA_NTSCLookups is\n");
fout.write("\n");

fout.write("   constant sync_level: unsigned(7 downto 0) := ");
h = hex(int(dac_low));
if (len(h) == 3):
    fout.write("X\"0" + h[2] + "\";\n");
if (len(h) == 4):
    fout.write("X\"" + h[2:4] + "\";\n");

fout.write("   constant blank_level: unsigned(7 downto 0) := ");
h = hex(int(round((blank_level_ire * ire_volts * volts_dac_step) + dac_low, 0)));
if (len(h) == 3):
    fout.write("X\"0" + h[2] + "\";\n");
if (len(h) == 4):
    fout.write("X\"" + h[2:4] + "\";\n");

fout.write("\n");
fout.write("   type lum_lut_type is array (0 to " + str(lum_steps - 1) + ") of unsigned(7 downto 0);\n");
fout.write("   constant lum_lut: lum_lut_type := (\n");                     

for i in range(0, lum_steps):
    lum_ire = i * lum_step_ire + black_level_ire;
    lum_val = int(round((lum_ire * ire_volts * volts_dac_step) + dac_low, 0));
    h = hex(lum_val);
    if (len(h) == 3):
        fout.write("      X\"0" + h[2] + "\"");
    if (len(h) == 4):
        fout.write("      X\"" + h[2:4] + "\"");
    if (i != lum_steps - 1):
        fout.write(",\n");
    else:
        fout.write(");\n");

fout.write("\n");
fout.write("   type col_lut_type is array (0 to " + str(col_steps * col_wave_steps - 1 + col_wave_steps) + ") of unsigned(7 downto 0);\n");
fout.write("   constant col_lut: col_lut_type := (\n");                     

for i in range(0, col_wave_steps):
    fout.write("      X\"00\",\n");

for i in range(0, col_steps):
    col_phase = col_phase_start + col_step_delay * i;
    for j in range(0, col_wave_steps):
        col_wave = col_phase + (360.0 / col_wave_steps * j);
        col_wave_ire = col_saturation_ire * sin(radians(col_wave));
        col_wave_val = int(round(col_wave_ire * ire_volts * volts_dac_step, 0))
        if (col_wave_val < 0):
            col_wave_val += 256;
        h = hex(col_wave_val);
        if (len(h) == 3):
            fout.write("      X\"0" + h[2] + "\"");
        if (len(h) == 4):
            fout.write("      X\"" + h[2:4] + "\"");
        if (i == (col_steps - 1) and j == (col_wave_steps - 1)):
            fout.write(");\n");
        else:
            fout.write(",\n");

fout.write("\n");
fout.write("end TIA_NTSCLookups;\n");
fout.write("\n");
fout.write("package body TIA_NTSCLookups is\n");
fout.write("\n");
fout.write("end TIA_NTSCLookups;\n");


        





