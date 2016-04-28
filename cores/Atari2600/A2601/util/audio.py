# Converts audio outputs from A2601 test bench to wave files. 
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

import wave

fi = open('..\\audio\\audio.txt', 'r')
fo = wave.open('..\\audio\\audio.wav', 'w')

fo.setnchannels(1)
fo.setsampwidth(1)
fo.setframerate(44100)

eof = 0

while not eof:		
	s = fi.readline()
	eof = (s == '')
	if (not eof):		
		fo.writeframes(chr(int(s)))		

fo.close()
fi.close()

		
	


