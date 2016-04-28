-- *****************************************************************************************
-- AVR synthesis control package
-- Version 1.32 (Special version for the JTAG OCD)
-- Modified 14.07.2005
-- Designed by Ruslan Lepetenok
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package SynthCtrlPack is							

-- Please note: Do not change these settings, this is not quite ready yet. Jack Gassett
-- Control the size of Program and Data memory.
constant CDATAMEMSIZE	: integer := 11;			--2^(x+1)=Data SRAM Memory Size   	(10=2048) (Default 11=4096) (12=8192)
constant CPROGMEMSIZE	: integer := 12;		--(2^(x+1))*2)=Program Memory Size	(10=4096) (11=8192) (Default 12=16384)
-- Calculate at Wolfram Alpha (http://www.wolframalpha.com/input/?i=%282^%28x%2B1%29%29*2%29%2Cx%3D12)

-- Reset generator
constant CSecondClockUsed     : boolean := FALSE;

constant CImplClockSw         : boolean := FALSE;

-- Only for ASICs
constant CSynchLatchUsed      : boolean := FALSE;	

-- Register file
constant CResetRegFile        : boolean := TRUE;

-- External multiplexer size
constant CExtMuxInSize        : positive := 16;

end SynthCtrlPack;
