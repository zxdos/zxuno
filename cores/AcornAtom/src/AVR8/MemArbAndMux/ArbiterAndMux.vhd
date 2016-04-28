--************************************************************************************************
--  Arrbiter and Address/Data multiplexer for AVR core
--  Version 0.2 
--  Designed by Ruslan Lepetenok 
--  Modified 27.07.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.MemAccessCtrlPack.all;

entity ArbiterAndMux is port(
	                    --Clock and reset
						ireset      : in  std_logic;
	                    cp2         : in  std_logic;
					    -- Bus masters
                        busmin		: in  MastersOutBus_Type;
						busmwait	: out std_logic_vector(CNumOfBusMasters-1 downto 0);
						-- Memory Address,Data and Control
						ramadr     : out  std_logic_vector(15 downto 0);
						ramdout    : out  std_logic_vector(7 downto 0);
                        ramre      : out  std_logic;
                        ramwe      : out  std_logic;	
						cpuwait    : in   std_logic
						);
end ArbiterAndMux;

architecture RTL of ArbiterAndMux is

signal sel_mast      : std_logic_vector(CNumOfBusMasters-1 downto 0);
signal sel_mast_rg   : std_logic_vector(sel_mast'range);
constant c_zero_vect : std_logic_vector(CNumOfBusMasters-1 downto 0) := (others => '0');

begin

StoreBusMNum:process(ireset,cp2)
begin  
 if (ireset='0') then                -- Reset 
  sel_mast_rg <= (others => '0');
 elsif (cp2='1' and cp2'event) 	then -- Clock
  if(cpuwait='1') then               -- Store selected bus master number
   sel_mast_rg <= sel_mast;
  end if; 
 end if;	 
end process;	


-- Fixed priority arbitration
ArbitrationComb:process(busmin)	   -- Combinatorial
begin
sel_mast <= (others => '0');	
 for i in 0 to CNumOfBusMasters-1 loop
  if(busmin(i).ramre='1' or busmin(i).ramwe='1') then
   sel_mast(i) <= '1';	  
   exit;
  end if; 
 end loop;	 
end process;	


MuxComb:process(busmin,sel_mast,sel_mast_rg,cpuwait)	   -- Combinatorial
begin
 ramadr  <= (others => '0');
 ramdout <= (others => '0');
 ramre   <= '0';
 ramwe   <= '0';

 for i in 0 to CNumOfBusMasters-1 loop
  if(cpuwait='1') then
   if(sel_mast_rg(i)='1') then 
	 ramadr  <= busmin(i).ramadr;
     ramdout <= busmin(i).dout;
     ramre   <= busmin(i).ramre;
     ramwe   <= busmin(i).ramwe;
	end if; 
   else                     --  	 cpuwait='0' 
    if(sel_mast(i)='1') then 
	 ramadr  <= busmin(i).ramadr;
     ramdout <= busmin(i).dout;
     ramre   <= busmin(i).ramre;
     ramwe   <= busmin(i).ramwe;
	end if; 	 
  end if;	  
 end loop;	 
end process;	

	
WaitGenComb:process(cpuwait,busmin,sel_mast)	   -- Combinatorial
begin
 busmwait <= (others => '0');
  if((busmin(busmwait'low).ramre='1' or busmin(busmwait'low).ramwe='1') and cpuwait='1') then 
   busmwait(busmwait'low) <= '1'; 	
  end if;	  
 for i in 1 to CNumOfBusMasters-1 loop
  if((busmin(i).ramre='1' or busmin(i).ramwe='1')and(sel_mast(i-1 downto 0)/=c_zero_vect(i-1 downto 0) or cpuwait='1')) then
   busmwait(i) <= '1';
  end if; 
 end loop;	 
end process;	

-- For the purpose of test only
--ramdout(sel_mast'range) <= sel_mast;	
-- For the purpose of test only

end RTL;