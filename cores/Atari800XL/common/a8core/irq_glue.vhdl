---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY irq_glue IS
PORT 
( 
	pokey_irq : in std_logic;
	pia_irqa : in std_logic;
	pia_irqb : in std_logic;
	
	combined_irq : out std_logic
);
end irq_glue;

architecture vhdl of irq_glue is
begin
	combined_irq <= pokey_irq and pia_irqa and pia_irqb;
end vhdl;