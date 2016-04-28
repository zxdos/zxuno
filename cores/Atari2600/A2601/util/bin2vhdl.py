# Converts binary rom files to VHDL files
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
import os.path


fin = open(sys.argv[1], 'rb')
fout = open(sys.argv[2], 'w')

data = fin.read()

if (len(data) <= 4096):
	adrsize = 11;
else:
	adrsize = 12;

fout.write("library ieee;\n");
fout.write("use ieee.std_logic_1164.all;\n");
fout.write("use ieee.numeric_std.all;\n");
fout.write("\n");
fout.write("entity cart_rom is\n");
fout.write("   port(clk: in std_logic;\n");
fout.write("        d: out std_logic_vector(7 downto 0);\n");
fout.write("        a: in std_logic_vector(" + str(adrsize) + " downto 0));\n");
fout.write("end cart_rom;\n");
fout.write("\n") 
fout.write("architecture arch of cart_rom is\n");
fout.write("   type rom_type is array (0 to " + str(len(data) - 1) + ") of std_logic_vector(7 downto 0);\n");
fout.write("   signal rom: rom_type := (\n");

for i in range(len(data) - 1):
	h = hex(ord(data[i]));
	if (len(h) == 3):
		fout.write("      X\"0" + h[2] + "\",\n");
	if (len(h) == 4):
		fout.write("      X\"" + h[2:4] + "\",\n");

h = hex(ord(data[len(data) - 1]));
if (len(h) == 3):
	fout.write("      X\"0" + h[2] + "\");\n");
if (len(h) == 4):
	fout.write("      X\"" + h[2:4] + "\");\n");

fout.write("\n");
fout.write("   signal ra: std_logic_vector(" + str(adrsize) + " downto 0);\n");
fout.write("\n");
fout.write("begin\n");
fout.write("   process(clk)\n");
fout.write("   begin\n");
fout.write("      if (clk = '0' and clk'event) then\n");
fout.write("         ra <= a;\n");
fout.write("      end if;\n");
fout.write("   end process;\n");
fout.write("\n");
fout.write("   d <= rom(to_integer(unsigned(ra)));\n");
fout.write("end arch;\n");

fin.close()
fout.close()

