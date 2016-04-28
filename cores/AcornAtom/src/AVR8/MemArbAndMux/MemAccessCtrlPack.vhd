-- *****************************************************************************************
-- 
-- Version 0.14
-- Modified 02.08.2005
-- Designed by Ruslan Lepetenok
-- *****************************************************************************************

library	IEEE;
use IEEE.std_logic_1164.all;

package MemAccessCtrlPack is

constant CNumOfBusMasters : positive := 3;	
constant CNumOfSlaves     : positive := 2;

constant CUseRAMSel		  : boolean := FALSE;

-- Masters

type MastOutBus_Type is record
 ramadr : std_logic_vector(15 downto 0); 
 dout   : std_logic_vector(7 downto 0);
 ramre  : std_logic;
 ramwe  : std_logic;
end record; 

type MastersOutBus_Type is array(CNumOfBusMasters-1 downto 0) of MastOutBus_Type;

-- Slave
type SlvOutBus_Type is record
 dout    : std_logic_vector(7 downto 0);
 out_en  : std_logic;
end record; 

type SlavesOutBus_Type is array(CNumOfSlaves-1 downto 0) of SlvOutBus_Type;

-- Memory address decoder
constant CMemMappedIOBaseAdr : std_logic_vector(3 downto 0) := x"D";
constant CDRAMBaseAdr        : std_logic_vector(1 downto 0) := "00";


end MemAccessCtrlPack;