-- BBC Micro for Altera DE1
--
-- Copyright (c) 2011 Mike Stirling
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- BBC keyboard implementation with interface to PS/2
--
-- (C) 2011 Mike Stirling
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
port (
	CLOCK		:	in	std_logic;
	nRESET		:	in	std_logic;
	CLKEN_1MHZ	:	in	std_logic;
	
	-- PS/2 interface
	PS2_CLK		:	in	std_logic;
	PS2_DATA	:	in	std_logic;
	
	-- If 1 then column is incremented automatically at
	-- 1 MHz rate
	AUTOSCAN	:	in	std_logic;
	
	COLUMN		:	in	std_logic_vector(3 downto 0);
	ROW			:	in	std_logic_vector(2 downto 0);
	
	-- 1 when currently selected key is down (AUTOSCAN disabled)
	KEYPRESS	:	out	std_logic;
	-- 1 when any key is down (except row 0)
	INT			:	out	std_logic;
	-- BREAK key output - 1 when pressed
	BREAK_OUT	:	out	std_logic;
	
	-- DIP switch inputs
	DIP_SWITCH	:	in	std_logic_vector(7 downto 0);
	scanSW	:	out	std_logic_vector(2 downto 0) --q
	);
end entity;

architecture rtl of keyboard is

-- PS/2 interface
component ps2_intf is
generic (filter_length : positive := 8);
port(
	CLK			:	in	std_logic;
	nRESET		:	in	std_logic;
	
	-- PS/2 interface (could be bi-dir)
	PS2_CLK		:	in	std_logic;
	PS2_DATA	:	in	std_logic;
	
	-- Byte-wide data interface - only valid for one clock
	-- so must be latched externally if required
	DATA		:	out	std_logic_vector(7 downto 0);
	VALID		:	out	std_logic;
	ERROR		:	out	std_logic
	);
end component;

-- Interface to PS/2 block
signal keyb_data	:	std_logic_vector(7 downto 0);
signal keyb_valid	:	std_logic;
signal keyb_error	:	std_logic;

-- Internal signals
type key_matrix is array(0 to 15) of std_logic_vector(7 downto 0);
signal keys			:	key_matrix;
signal col			:	unsigned(3 downto 0);
signal release		:	std_logic;
signal extended		:	std_logic;

signal VIDEO: std_logic := '0';
signal SCANL: std_logic := '0';
signal CTRL	: std_logic;
signal ALT	: std_logic;

begin

	ps2 : ps2_intf port map (
		CLOCK, nRESET,
		PS2_CLK, PS2_DATA,
		keyb_data, keyb_valid, keyb_error
		);

	-- Column counts automatically when AUTOSCAN is enabled, otherwise
	-- value is loaded from external input
	process(CLOCK,nRESET)
	begin
		if nRESET = '0' then
			col <= (others => '0');
		elsif rising_edge(CLOCK) then
			if AUTOSCAN = '0' then
				-- If autoscan disabled then transfer current COLUMN to counter
				-- immediately (don't wait for next 1 MHz cycle)
				col <= unsigned(COLUMN);
			elsif CLKEN_1MHZ = '1' then
				-- Otherwise increment the counter once per 1 MHz tick
				col <= col + 1;
			end if;
		end if;
	end process;

	-- Generate interrupt if any key in currently scanned column is pressed
	-- (apart from in row 0).  Output selected key status if autoscan disabled.
	process(keys,col,ROW,AUTOSCAN)
	variable k : std_logic_vector(7 downto 0);
	begin
		-- Shortcut to current key column
		k := keys(to_integer(col));
		
		-- Interrupt if any key pressed in rows 1 to 7.
		INT <= k(7) or k(6) or k(5) or k(4) or k(3) or k(2) or k(1);
		
		-- Determine which key is pressed
		-- Inhibit output during auto-scan
		if AUTOSCAN = '0' then
			KEYPRESS <= k(to_integer(unsigned(ROW)));
		else
			KEYPRESS <= '0';
		end if;
	end process;
	
	-- Decode PS/2 data
	process(CLOCK,nRESET)
	begin
		if nRESET = '0' then
			release <= '0';
			extended <= '0';
			
			BREAK_OUT <= '0';
			
			keys(0) <= (others => '0');
			keys(1) <= (others => '0');
			keys(2) <= (others => '0');
			keys(3) <= (others => '0');
			keys(4) <= (others => '0');
			keys(5) <= (others => '0');
			keys(6) <= (others => '0');
			keys(7) <= (others => '0');
			keys(8) <= (others => '0');
			keys(9) <= (others => '0');
			-- These non-existent rows are used in the BBC master
			keys(10) <= (others => '0');
			keys(11) <= (others => '0');
			keys(12) <= (others => '0');
			keys(13) <= (others => '0');
			keys(14) <= (others => '0');
			keys(15) <= (others => '0');
		elsif rising_edge(CLOCK) then
			-- Copy DIP switches through to row 0
			keys(2)(0) <= DIP_SWITCH(7);
			keys(3)(0) <= DIP_SWITCH(6);
			keys(4)(0) <= DIP_SWITCH(5);
			keys(5)(0) <= DIP_SWITCH(4);
			keys(6)(0) <= DIP_SWITCH(3);
			keys(7)(0) <= DIP_SWITCH(2);
			keys(8)(0) <= DIP_SWITCH(1);
			keys(9)(0) <= DIP_SWITCH(0);
			
			if keyb_valid = '1' then
				-- Decode keyboard input
				if keyb_data = X"e0" then
					-- Extended key code follows
					extended <= '1';
				elsif keyb_data = X"f0" then
					-- Release code follows
					release <= '1';
				else
					-- Cancel extended/release flags for next time
					release <= '0';
					extended <= '0';
					
					-- Decode scan codes
					case keyb_data is
					when X"12" => keys(0)(0) <= not release; -- Left SHIFT
					when X"59" => keys(0)(0) <= not release; -- Right SHIFT
					when X"15" => keys(0)(1) <= not release; -- Q
					when X"09" => keys(0)(2) <= not release; -- F10 (F0)
					when X"16" => keys(0)(3) <= not release; -- 1
					when X"58" => keys(0)(4) <= not release; -- CAPS LOCK
					when X"11" => keys(0)(5) <= not release; -- LEFT ALT (SHIFT LOCK)
									  ALT <= not release; 
					when X"0D" => keys(0)(6) <= not release; -- TAB
					when X"76" => keys(0)(7) <= not release; -- ESCAPE
					when X"14" => keys(1)(0) <= not release; -- LEFT/RIGHT CTRL (CTRL)
									  CTRL <= not release; 
					when X"26" => keys(1)(1) <= not release; -- 3
					when X"1D" => keys(1)(2) <= not release; -- W
					when X"1E" => keys(1)(3) <= not release; -- 2
					when X"1C" => keys(1)(4) <= not release; -- A
					when X"1B" => keys(1)(5) <= not release; -- S
					when X"1A" => keys(1)(6) <= not release; -- Z
					when X"05" => keys(1)(7) <= not release; -- F1
					when X"25" => keys(2)(1) <= not release; -- 4
					when X"24" => keys(2)(2) <= not release; -- E
					when X"23" => keys(2)(3) <= not release; -- D
					when X"22" => keys(2)(4) <= not release; -- X
					when X"21" => keys(2)(5) <= not release; -- C
					when X"29" => keys(2)(6) <= not release; -- SPACE
					when X"06" => keys(2)(7) <= not release; -- F2
					when X"2E" => keys(3)(1) <= not release; -- 5
					when X"2C" => keys(3)(2) <= not release; -- T
					when X"2D" => keys(3)(3) <= not release; -- R
					when X"2B" => keys(3)(4) <= not release; -- F
					when X"34" => keys(3)(5) <= not release; -- G
					when X"2A" => keys(3)(6) <= not release; -- V
					when X"04" => keys(3)(7) <= not release; -- F3
					when X"0C" => keys(4)(1) <= not release; -- F4
					when X"3D" => keys(4)(2) <= not release; -- 7
					when X"36" => keys(4)(3) <= not release; -- 6
					when X"35" => keys(4)(4) <= not release; -- Y
					when X"33" => keys(4)(5) <= not release; -- H
					when X"32" => keys(4)(6) <= not release; -- B
					when X"03" => keys(4)(7) <= not release; -- F5
					when X"3E" => keys(5)(1) <= not release; -- 8
					when X"43" => keys(5)(2) <= not release; -- I
					when X"3C" => keys(5)(3) <= not release; -- U
					when X"3B" => keys(5)(4) <= not release; -- J
					when X"31" => keys(5)(5) <= not release; -- N
					when X"3A" => keys(5)(6) <= not release; -- M
					when X"0B" => keys(5)(7) <= not release; -- F6
					when X"83" => keys(6)(1) <= not release; -- F7
					when X"46" => keys(6)(2) <= not release; -- 9
					when X"44" => keys(6)(3) <= not release; -- O
					when X"42" => keys(6)(4) <= not release; -- K
					when X"4B" => keys(6)(5) <= not release; -- L
					when X"41" => keys(6)(6) <= not release; -- ,
					when X"0A" => keys(6)(7) <= not release; -- F8
					when X"4E" => keys(7)(1) <= not release; -- -
					when X"45" => keys(7)(2) <= not release; -- 0
					when X"4D" => keys(7)(3) <= not release; -- P
					when X"0E" => keys(7)(4) <= not release; -- ` (@)
					when X"4C" => keys(7)(5) <= not release; -- ;
					when X"49" => keys(7)(6) <= not release; -- .
					when X"01" => keys(7)(7) <= not release; -- F9
					when X"55" => keys(8)(1) <= not release; -- = (^)
					when X"5D" => keys(8)(2) <= not release; -- # (_)
					when X"54" => keys(8)(3) <= not release; -- [
					when X"52" => keys(8)(4) <= not release; -- '
					when X"5B" => keys(8)(5) <= not release; -- ]
					when X"4A" => keys(8)(6) <= not release; -- /
					when X"61" => keys(8)(7) <= not release; -- \
					when X"6B" => keys(9)(1) <= not release; -- LEFT
					when X"72" => keys(9)(2) <= not release; -- DOWN
					when X"75" => keys(9)(3) <= not release; -- UP
					when X"5A" => keys(9)(4) <= not release; -- RETURN
--					when X"66" => keys(9)(5) <= not release; -- BACKSPACE (DELETE)
					when X"69" => keys(9)(6) <= not release; -- END (COPY)
					when X"74" => keys(9)(7) <= not release; -- RIGHT
					
					-- F12 is used for the BREAK key, which in the real BBC asserts
					-- reset.  Here we pass this out to the top level which may
					-- optionally OR it in to the system reset
					when X"07" => BREAK_OUT <= not release; -- F12 (BREAK)

					when X"7E" => 									 -- scrolLock RGB/VGA
							if (VIDEO = '0' and release = '0') then
								scanSW(0) <= '1';
								VIDEO <= '1';
							elsif (VIDEO = '1' and release = '0') then
								scanSW(0) <= '0';
								VIDEO <= '0';
							end if;	

					when X"7B" => 									 -- scanlines ("-" numpad)
							if (SCANL = '0' and release = '0') then
								scanSW(1) <= '1';
								SCANL <= '1';
							elsif (SCANL = '1' and release = '0') then
								scanSW(1) <= '0';
								SCANL <= '0';
							end if;		

					--Master reset
					when X"66" =>  
							if (CTRL = '1' and ALT = '1') then
								scanSW(2) <= not release; 
							else
								keys(9)(5) <= not release; --normal BACKSPACE
							end if;			
										
					when others => null;
					end case;
					
				end if;
			end if;
		end if;
	end process;

end architecture;


