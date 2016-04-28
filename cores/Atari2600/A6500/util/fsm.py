# Processes VHDL file output of StateCAD to create a nicer source
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

import string

f = open('fsm.vhd') 
src = string.join(f.readlines())
f.close()

src = src.lower()

src = src.replace('if ( reset=\'1\' ) then', 'if (rst = \'1\') then')
src = src.replace('elsif clk=\'1\' and clk\'event then', 'elsif (clk = \'1\' and clk\'event and en = \'1\') then')
src = src.replace('process (clk, reset, ', 'process (clk, rst, en, ')

p_f = src.find('port')
p_s = src.find('(', p_f)
p_e = src.find(';', p_s) + 1

in_s = p_s + 1
in_e = src.find(':', in_s)

st_s = src.find('signal', in_e) + 7;
st_e = src.find(':', st_s)

beg = src.find('begin', st_e) + 5;

input_list = src[in_s:in_e].split(',')
for i in range(len(input_list)):
	input_list[i] = input_list[i].strip()

input_list.remove('clk')
input_list.remove('reset')

signal_list = src[st_s:st_e].split(',')
state_list = []
for i in range(len(signal_list)):
	state = signal_list[i].strip()
	if not state.startswith('next_'):
		state_list.append(state)

s = src.find('library')

dst = '-- A6500 - 6502 CPU and variants\n\n'
dst += src[s:p_f] + 'port(clk: in std_logic;\n'
dst += '\t     rst: in std_logic;\n'
dst += '\t     en: in std_logic;\n'

for i in range(len(input_list)):
	dst += '\n\t     ' + input_list[i] + ': in std_logic;'

dst += '\n'

for i in range(len(state_list) - 1):
	dst += '\n\t     ' + state_list[i] + '_s: out std_logic;'
	
dst += '\n\t     ' + state_list[i] + '_s: out std_logic\n\t    );'
dst += src[p_e:beg]

for i in state_list:
	dst += '\n\t' + i + '_s <= ' + i + ';'

dst += '\n' + src[beg:]

dst = dst.expandtabs(3)

f = open('FSM.vhd', 'w')
f.write(dst)
f.close()






