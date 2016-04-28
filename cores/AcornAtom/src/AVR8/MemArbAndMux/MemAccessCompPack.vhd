-- *****************************************************************************************
-- 
-- Version 0.1
-- Modified 24.07.2005
-- Designed by Ruslan Lepetenok
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;

use WORK.MemAccessCtrlPack.all;

package MemAccessCompPack is

	
component ArbiterAndMux is port(
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
end component;


component MemRdMux is port(
	                    slv_outs  : in SlavesOutBus_Type;
						ram_sel   : in  std_logic;                    -- Data RAM selection(optional input)
	                    ram_dout  : in  std_logic_vector(7 downto 0); -- Data memory output
						dout      : out std_logic_vector(7 downto 0)  -- Data output
						);
end component;


component RAMAdrDcd is port(
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
end component;


end MemAccessCompPack;


