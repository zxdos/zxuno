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

ENTITY gtia_priority IS
PORT 
( 
	CLK : in std_logic;
	colour_enable : in std_logic;

	PRIOR : in std_logic_vector(7 downto 0);
	P0 : in std_logic;
	P1 : in std_logic;
	P2	: in std_logic;
	P3 : in std_logic;
	PF0 : in std_logic;
	PF1 : in std_logic;
	PF2 : in std_logic;
	PF3 : in std_logic;
	BK : in std_logic;
	
	P0_OUT : out std_logic;
	P1_OUT : out std_logic;
	P2_OUT : out std_logic;
	P3_OUT : out std_logic;
	PF0_OUT : out std_logic;
	PF1_OUT : out std_logic;
	PF2_OUT : out std_logic;
	PF3_OUT : out std_logic;
	BK_OUT : out std_logic
);
END gtia_priority;

ARCHITECTURE vhdl OF gtia_priority IS
	signal P01 : std_logic;
	signal P23 : std_logic;
	
	signal PF01 : std_logic;
	signal PF23 : std_logic;
	
	signal PRI01 : std_logic;
	signal PRI12 : std_logic;
	signal PRI23 : std_logic;
	signal PRI03 : std_logic;
	
	signal PRI0 : std_logic;
	signal PRI1 : std_logic;
	signal PRI2 : std_logic;
	signal PRI3 : std_logic;
	signal MULTI : std_logic;
	
	signal SP0 : std_logic;
	signal SP1 : std_logic;
	signal SP2 : std_logic;
	signal SP3 : std_logic;	
	signal SF0 : std_logic;
	signal SF1 : std_logic;
	signal SF2 : std_logic;
	signal SF3 : std_logic;	
	signal SB : std_logic;
	
	signal SP0_next : std_logic;
	signal SP1_next : std_logic;
	signal SP2_next : std_logic;
	signal SP3_next : std_logic;	
	signal SF0_next : std_logic;
	signal SF1_next : std_logic;
	signal SF2_next : std_logic;
	signal SF3_next : std_logic;	
	signal SB_next : std_logic;

	signal SP0_reg : std_logic;
	signal SP1_reg : std_logic;
	signal SP2_reg : std_logic;
	signal SP3_reg : std_logic;	
	signal SF0_reg : std_logic;
	signal SF1_reg : std_logic;
	signal SF2_reg : std_logic;
	signal SF3_reg : std_logic;	
	signal SB_reg : std_logic;
begin
	-- Use actual GTIA logic...
	P01 <= P0 or P1;
	P23 <= P2 or P3;

	PF01 <= PF0 or PF1;
	PF23 <= PF2 or PF3;
	
	PRI0 <= prior(0);
	PRI1 <= prior(1);
	PRI2 <= prior(2);
	PRI3 <= prior(3);
	MULTI <= prior(5);
	
	PRI01 <= PRI0  or  PRI1;
	PRI12 <= PRI1  or  PRI2;
	PRI23 <= PRI2  or  PRI3;
	PRI03 <= PRI0  or  PRI3;
	
	SP0 <= P0  and   not (PF01 and PRI23)  and   not (PRI2 and PF23);
	SP1 <= P1  and   not (PF01 and PRI23)  and   not (PRI2 and PF23)  and  ( not P0  or  MULTI);
	SP2 <= P2  and   not P01  and   not (PF23 and PRI12)  and   not (PF01 and  not PRI0);
	SP3 <= P3  and   not P01  and   not (PF23 and PRI12)  and   not (PF01 and  not PRI0)  and  ( not P2  or  MULTI);
	SF0 <= PF0  and   not (P23 and PRI0)  and   not (P01 and PRI01)  and   not SF3;
	SF1 <= PF1  and   not (P23 and PRI0)  and   not (P01 and PRI01)  and   not SF3;
	SF2 <= PF2  and   not (P23 and PRI03)  and   not (P01 and  not PRI2)  and   not SF3;
	SF3 <= PF3  and   not (P23 and PRI03)  and   not (P01 and  not PRI2);
	SB <=  not P01  and   not P23  and   not PF01  and   not PF23;
	
	-- register
	process(clk)
	begin
		if (clk'event and clk='1') then
		SP0_reg <= SP0_next;
		SP1_reg <= SP1_next;
		SP2_reg <= SP2_next;
		SP3_reg <= SP3_next;
		
		SF0_reg <= SF0_next;
		SF1_reg <= SF1_next;
		SF2_reg <= SF2_next;
		SF3_reg <= SF3_next;
		
		SB_reg <= SB_next;
		end if;
	end process;
	
	-- need to register this to get same position as GTIA modes - i.e. two colour clocks after AN data received
	process(colour_enable,SP0_reg,SP1_reg,SP2_reg,SP3_reg,SF0_reg,SF1_reg,SF2_reg,SF3_reg,SB_reg,SP0,SP1,SP2,SP3,SF0,SF1,SF2,SF3,SB)
	begin
		SP0_next <= SP0_reg;
		SP1_next <= SP1_reg;
		SP2_next <= SP2_reg;
		SP3_next <= SP3_reg;
		
		SF0_next <= SF0_reg;
		SF1_next <= SF1_reg;
		SF2_next <= SF2_reg;
		SF3_next <= SF3_reg;
		
		SB_next <= SB_reg;
		
		if (colour_enable = '1') then	
			SP0_next <= SP0;
			SP1_next <= SP1;
			SP2_next <= SP2;
			SP3_next <= SP3;
			
			SF0_next <= SF0;
			SF1_next <= SF1;
			SF2_next <= SF2;
			SF3_next <= SF3;
			
			SB_next <= SB;	
		end if;
	end process;
		
	-- output
	P0_OUT <= SP0_reg;
	P1_OUT <= SP1_reg;
	P2_OUT <= SP2_reg;
	P3_OUT <= SP3_reg;
	PF0_OUT <= SF0_reg;
	PF1_OUT <= SF1_reg;
	PF2_OUT <= SF2_reg;
	PF3_OUT <= SF3_reg;
	BK_OUT <= SB_reg;
end vhdl;