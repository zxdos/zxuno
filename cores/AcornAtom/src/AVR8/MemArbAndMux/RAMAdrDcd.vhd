--************************************************************************************************
--  Address decoder
--  Version 0.11A 
--  Designed by Ruslan Lepetenok 
--  Modified 31.07.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use WORK.MemAccessCtrlPack.all;

entity RAMAdrDcd is port(
                         ramadr    : in std_logic_vector(15 downto 0);
		                 ramre     : in std_logic;
		                 ramwe     : in std_logic;
		                 -- Memory mapped I/O i/f
		                 stb_IO	   : out std_logic;
		                 stb_IOmod : out std_logic_vector(CNumOfSlaves-1 downto 0);		
	                     -- Data memory i/f
		                 ram_we    : out std_logic;
		                 ram_ce    : out std_logic;
						 ram_sel   : out std_logic
		                );
end RAMAdrDcd;

architecture RTL of RAMAdrDcd is
signal ram_sel_int           : std_logic;
begin 

stb_IO	<= '1' when (ramadr(ramadr'high downto ramadr'high-CMemMappedIOBaseAdr'high) = CMemMappedIOBaseAdr) else '0';

--MMIOAdrDcd:process(ramadr)
--begin
-- stb_IOmod <= (others => '0');	
-- for i in 0 to CNumOfSlaves-1 loop
--  if(ramadr(7 downto 4)=i) then
--   stb_IOmod(i) <= '1';
--  end if;	  
-- end loop;	 
--end process;	

-- For the purpose of test only
--stb_IOmod(0) <= '1' when ramadr(15 downto 4)=x"017" else '0';
--stb_IOmod(1) <= '1' when ramadr(15 downto 4)=x"018" else '0';

stb_IOmod(0) <= '1' when ramadr(7 downto 4)=x"0" else '0';
stb_IOmod(1) <= '1' when ramadr(7 downto 4)=x"1" else '0';
-- For the purpose of test only

-- RAM i/f	
ram_sel_int <= '1'when (ramadr(ramadr'high downto ramadr'high-CDRAMBaseAdr'high) = CDRAMBaseAdr) else '0';	
ram_sel <= ram_sel_int;	
ram_we  <= ram_sel_int and ramwe;	
ram_ce  <= ram_sel_int and (ramwe or ramre);

end RTL;

