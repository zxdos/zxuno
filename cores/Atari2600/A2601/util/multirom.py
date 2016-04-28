# Using the given game table, generates:
# 	1. Merged rom binary file
# 	2. Corresponding VHDL source for ROM property table (CartTable)

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

def bin(n, s):
	b = ""
	for i in range(s):
		b = str(n & 1) + b
		n = n >> 1;
	return b;

# CartTable entry format: index(7 bits) | bss(3 bits) | sc
indexbits = 7
bssbits = 3
scbits = 1
entrybits = indexbits + bssbits + scbits;

multirom = ""
index = 0
table = []

# parse the game table
fin = open(sys.argv[1])
for line in fin.readlines():
	tokens = line.split('|')
	tokens = [x.strip() for x in tokens];
	
	romfile = tokens[0]
	bss = tokens[1]
	
	if (romfile == ""):
		continue
	
	#load rom
	fr = open(romfile, 'rb')
	rom = fr.read()	
		
	#enumerate bss and determine size
	if (bss == 'bank00'):
		bssn = 0
		size = 4096			
		align = 1
	elif (bss == 'bankf8'):
		bssn = 1
		size = 8192
		align = 2
	elif (bss == 'bankf6'):
		bssn = 2
		size = 16384
		align = 4
	elif (bss == 'bankfe'):
		bssn = 3
		size = 8192
		align = 2
	elif (bss == 'banke0'):
		bssn = 4
		size = 8192
		align = 2
	elif (bss == 'bank3f'):
		bssn = 5
		size = 8192
		align = 2
	else:
		print romfile, ": unrecognized bss ", bss
		quit()
		
	#check size 
	if (size != len(rom)):
		print romfile, ": expected size", size, ", got", len(rom)
		quit()
		
	#check for superchip
	if ('sc' in tokens):
		sc = 1
	else:
		sc = 0
		
	#check for alignment
	if (index % align != 0):
		print romfile, ": alignment error:", (index % align) * 4096, "bytes"
		quit()
		
	#add rom data 
	multirom += rom
	
	#form table entry and append it	
	
	entry = bin((index << (bssbits + scbits)) + (bssn << scbits) + sc, entrybits);	
	table.append(entry)		
	
	index += (size / 4096);
		
	#check size of index
	if (index > 127):
		print romfile, ": flash rom size exceeded"
		quit()
	
entryCount = len(table);

#pad the table to 128 entries
while (len(table) < 128):
	table.append(bin(0, entrybits))
		
#output binary file
fmr = open(sys.argv[2], 'wb')
fmr.write(multirom)
fmr.close() 

#output table file
fout = open(sys.argv[3], 'w')

fout.write("library ieee;\n");
fout.write("use ieee.std_logic_1164.all;\n");
fout.write("use ieee.numeric_std.all;\n");
fout.write("\n");
fout.write("entity CartTable is\n");
fout.write("   port(clk: in std_logic;\n");
fout.write("        d: out std_logic_vector(" + str(entrybits - 1) + " downto 0);\n");
fout.write("        c: out std_logic_vector(6 downto 0);\n");
fout.write("        a: in std_logic_vector(6 downto 0));\n");
fout.write("end CartTable;\n");
fout.write("\n") 
fout.write("architecture arch of CartTable is\n");
fout.write("   type rom_type is array (0 to 127) of std_logic_vector(" + str(entrybits - 1) + " downto 0);\n");
fout.write("   signal rom: rom_type := (\n");

for i in range(127):
	fout.write("      \"" + table[i] + "\",\n");	
	
fout.write("      \"" + table[127] + "\");\n");

fout.write("\n");
fout.write("   signal ra: std_logic_vector(6 downto 0);\n");
fout.write("\n");
fout.write("begin\n");
fout.write("   process(clk)\n");
fout.write("   begin\n");
fout.write("      if (clk = '1' and clk'event) then\n");
fout.write("         ra <= a;\n");
fout.write("      end if;\n");
fout.write("   end process;\n");
fout.write("\n");
fout.write("   d <= rom(to_integer(unsigned(ra)));\n");
fout.write("   c <= \"" + bin(entryCount - 1, 7) + "\";\n");
fout.write("end arch;\n");

fout.close()

	
	
	
	
	
	
	
	
	
		
		

