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

ENTITY antic_dma_clock IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_n : IN STD_LOGIC;
	enable_dma : IN STD_LOGIC;
	
	playfield_start : in std_logic;
	playfield_end : in std_logic;
	vblank : in std_logic;
	
	slow_dma : in std_logic;
	medium_dma : in std_logic;
	fast_dma : in std_logic;
	
	dma_clock_out_0 : out std_logic;
	dma_clock_out_1 : out std_logic;
	dma_clock_out_2 : out std_logic;
	dma_clock_out_3 : out std_logic
);
END antic_dma_clock;

ARCHITECTURE vhdl OF antic_dma_clock IS
	signal dma_shiftreg_next : std_logic_vector(7 downto 0);
	signal dma_shiftreg_reg : std_logic_vector(7 downto 0);
	
	signal tick : std_logic;
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			dma_shiftreg_reg <= (others=>'0');
		elsif (clk'event and clk='1') then			
			dma_shiftreg_reg <= dma_shiftreg_next;
		end if;
	end process;

	-- next state
	tick <=(dma_shiftreg_reg(0) and slow_dma) or (dma_shiftreg_reg(4) and medium_dma) or (dma_shiftreg_reg(6) and fast_dma);
	process(enable_dma, dma_shiftreg_reg, playfield_start, playfield_end, vblank, slow_dma, medium_dma, fast_dma, tick)
	begin
		dma_shiftreg_next <= dma_shiftreg_reg;

		if (enable_dma = '1') then			
			dma_shiftreg_next <= 
				not((playfield_start nor tick)
				or playfield_end or vblank)				
				&dma_shiftreg_reg(7 downto 1);
		end if;
		
		if (playfield_start = '1') then
			dma_shiftreg_next(7) <= not((playfield_start nor tick) or playfield_end or vblank);
		end if;
	end process;
	
	-- output
	dma_clock_out_0 <= dma_shiftreg_reg(6) and enable_dma;
	dma_clock_out_1 <= dma_shiftreg_reg(5) and enable_dma;
	dma_clock_out_2 <= dma_shiftreg_reg(4) and enable_dma;
	dma_clock_out_3 <= dma_shiftreg_reg(3) and enable_dma;
	
END vhdl;
