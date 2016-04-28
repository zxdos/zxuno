--**********************************************************************************************
-- Resynchronizer (for bit)
-- Version 0.1
-- Modified 10.01.2007
-- Designed by Ruslan Lepetenok
--**********************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

entity rsnc_bit is generic(
	                        add_stgs_num : integer := 0;
						    inv_f_stgs   : integer := 0
	                        ); 
	                   port(	                   
	                        clk : in  std_logic;
							di  : in  std_logic;
							do  : out std_logic
                            );
end rsnc_bit;

architecture rtl of rsnc_bit is

type rsnc_vect_type is array(add_stgs_num+1 downto 0) of std_logic;

signal rsnc_rg_current : rsnc_vect_type;
signal rsnc_rg_next    : rsnc_vect_type;

begin

inverted_first_stg:if (inv_f_stgs/=0) generate
seq_f_fe_prc:process(clk)
begin
 if(clk='0' and clk'event) then  -- Clock (falling edge)
  rsnc_rg_current(rsnc_rg_current'low) <= rsnc_rg_next(rsnc_rg_next'low);
 end if;	
end process;		
end generate;

norm_first_stg:if (inv_f_stgs=0) generate
seq_f_re_prc:process(clk)
begin
 if(clk='1' and clk'event) then  -- Clock (rising edge)
  rsnc_rg_current(rsnc_rg_current'low) <= rsnc_rg_next(rsnc_rg_next'low);
 end if;	
end process;		
end generate;

seq_re_prc:process(clk)
begin
 if(clk='1' and clk'event) then  -- Clock (rising edge)
  rsnc_rg_current(rsnc_rg_current'high downto rsnc_rg_current'low+1) <= rsnc_rg_next(rsnc_rg_current'high downto rsnc_rg_current'low+1);
 end if;	
end process;

comb_prc:process(di,rsnc_rg_current)	
begin
 rsnc_rg_next(0) <= di; 
 for i in 1 to rsnc_rg_next'high loop 
  rsnc_rg_next(i) <= rsnc_rg_current(i-1);
 end loop;
end process;

do <= rsnc_rg_current(rsnc_rg_current'high);

end rtl;
