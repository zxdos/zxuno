--************************************************************************************************
--  
--  Version 0.1 
--  Designed by Ruslan Lepetenok 
--  Modified 24.07.2005
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use WORK.MemAccessCtrlPack.all;

entity MemRdMux is port(
	                    slv_outs  : in SlavesOutBus_Type;
						ram_sel   : in  std_logic;                    -- Data RAM selection(optional input)
	                    ram_dout  : in  std_logic_vector(7 downto 0); -- Data memory output
						dout      : out std_logic_vector(7 downto 0)  -- Data output
						);
end MemRdMux;

architecture RTL of MemRdMux is
constant c_zero_vect : std_logic_vector(CNumOfSlaves-1 downto 0) := (others => '0');

signal slv_data_out  : std_logic_vector(dout'range);
--CUseRAMSel

begin

SlvSelOutMux:process(slv_outs)          -- Combinatorial
begin
 slv_data_out <= (others => '0');
 for i in 0 to CNumOfSlaves-1 loop
   if(slv_outs(i).out_en='1') then	 
	slv_data_out <= slv_outs(i).dout; 
   exit;	  
  end if;	  
 end loop;
end process;	

RamSelIsNotUsed:if not CUseRAMSel generate
OutMux:process(slv_outs,slv_data_out,ram_dout)          -- Combinatorial
 begin
  dout <= ram_dout;
   for i in 0 to CNumOfSlaves-1 loop
    if(slv_outs(i).out_en='1') then	 
	 dout <= slv_data_out; 
     exit;	  
    end if;	  
 end loop;
end process;	
end generate;

RamSelIsUsed:if CUseRAMSel generate
 dout <= ram_dout when (ram_sel='1') else  slv_data_out;	
end generate;	

end RTL;


