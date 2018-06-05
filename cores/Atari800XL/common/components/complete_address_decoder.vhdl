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
	
ENTITY complete_address_decoder IS
generic (width : natural := 1);
PORT 
( 
	addr_in : in std_logic_vector(width-1 downto 0);	
	
	addr_decoded : out std_logic_vector((2**width)-1 downto 0)
);
END complete_address_decoder;

--ARCHITECTURE vhdl OF complete_address_decoder IS
--BEGIN
--	comp_gen:
--	for i in 0 to ((2**width)-1) generate
--		addr_decoded(i) <= '1' when i=to_integer(unsigned(addr_in)) else '0';
--	end generate;
--end vhdl;

architecture tree of complete_address_decoder is
	constant STAGE : natural:=width;
	type std_logic_2d is array (natural range <>,natural range <>) of std_logic;
	signal p: std_logic_2d(stage downto 0,2**stage-1 downto 0);
	signal a: std_logic_vector(width-1 downto 0) ;
begin
	a<=addr_in;
	process(a,p)
	begin
		p(stage,0) <= '1';
		
		for s in stage downto 1 loop
			for r in 0 to (2**(stage-s)-1) loop
				p(s-1,2*r) <= (not a(s-1)) and p(s,r);
				p(s-1,2*r+1) <= a(s-1) and p(s,r);
			end loop;
		end loop;
		
		for i in  0 to (2**stage-1) loop
			addr_decoded(i) <= p(0,i);
		end loop;
	end process;
end tree;