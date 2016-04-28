--
-- Copyright (C) 2013 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rgb2vga is
	port (
		-- 32MHz pixel clock from BBC Micro
		clock : in  std_logic;
        
		-- 16MHz clock enable BBC Micro
        clken : in  std_logic;

		-- 25MHz VGA clock
        clk25 : in  std_logic;
        
		-- Input 15.625kHz RGB signals
		rgbi_in   : in  std_logic_vector(3 downto 0);
		hSync_in  : in  std_logic;
		vSync_in  : in  std_logic;
		
		-- Output 31.250kHz VGA signals
		rgbi_out  : out std_logic_vector(3 downto 0);
		hSync_out : out std_logic;
		vSync_out : out std_logic
	);
end entity;

architecture rtl of rgb2vga is
	-- Config parameters
	constant SAMPLE_OFFSET : integer := 240;
	constant SAMPLE_WIDTH  : integer := 656;

--    -- original values
--  constant width25       : integer := 10;
--	constant HORIZ_RT      : integer := 96;
--	constant HORIZ_BP      : integer := 30;
--	constant HORIZ_DISP    : integer := 656;
--	constant HORIZ_FP      : integer := 18;

--    -- Values for 1170x584 (total 1480x624) with 46.2MHz clock
--  constant width25       : integer := 11;  
--	constant HORIZ_RT      : integer := 176;
--	constant HORIZ_BP      : integer := 404;
--	constant HORIZ_DISP    : integer := 656;
--	constant HORIZ_FP      : integer := 244;

    -- Values for 720x576p (total 864x625) with 27MHz clock
    -- worked quite well on Belina and on LG
    -- ModeLine "720x576" 27.00 720 732 796 864 576 581 586 625 -HSync -VSync
    constant width25       : integer := 10;
	constant HORIZ_RT      : integer := 64;
	constant HORIZ_BP      : integer := 68 + 32;
	constant HORIZ_DISP    : integer := 656;
	constant HORIZ_FP      : integer := 12 + 32;

--    -- Values for 800x600 (total 1056x625) with 33.032MHz clock
--  constant width25       : integer := 11;
--	constant HORIZ_RT      : integer := 96;
--	constant HORIZ_BP      : integer := 152;
--	constant HORIZ_DISP    : integer := 656;
--	constant HORIZ_FP      : integer := 152;
    
--    -- Values for 800x600 (total 1024x625) with 32.000MHz clock
--  constant width25       : integer := 11;    
--	constant HORIZ_RT      : integer := 128;
--	constant HORIZ_BP      : integer := 160;
--	constant HORIZ_DISP    : integer := 656;
--	constant HORIZ_FP      : integer := 80;

--    -- Values for 800x600 (total 960x625) with 30.000MHz clock
--    -- Modeline "800x600@50" 30 800 814 884 960 600 601 606 625 +hsync +vsync
--  constant width25       : integer := 10;    
--	constant HORIZ_RT      : integer := 70;
--	constant HORIZ_BP      : integer := 76 + 72;
--	constant HORIZ_DISP    : integer := 656;
--	constant HORIZ_FP      : integer := 14 + 72;
    
	-- VSYNC state-machine
	type VType is (
		S_WAIT_VSYNC,
		S_EXTRA1,
		S_EXTRA2,
		S_NOEXTRA,
		S_ASSERT_VSYNC
	);
	
	-- Registers in the 16MHz clock domain:
	signal state           : VType := S_WAIT_VSYNC;
	signal state_next      : VType;
	signal hSync_s16       : std_logic;
	signal vSync_s16       : std_logic;
	signal hSyncStart      : std_logic;
	signal vSyncStart      : std_logic;
	signal hCount16        : unsigned(9 downto 0) := (others => '0');
	signal hCount16_next   : unsigned(9 downto 0);
	signal lineToggle      : std_logic := '1';
	signal lineToggle_next : std_logic;

	-- Registers in the 25MHz clock domain:
	signal hSync_s25a      : std_logic;
	signal hSync_s25b      : std_logic;
	signal hCount25        : unsigned(width25 - 1 downto 0) := to_unsigned(HORIZ_DISP + HORIZ_FP, width25);
	signal hCount25_next   : unsigned(width25 - 1 downto 0);

	-- Signals on the write side of the RAMs:
	signal writeEn0        : std_logic;
	signal writeEn1        : std_logic;

	-- Signals on the read side of the RAMs:
	signal ram0Data        : std_logic_vector(3 downto 0);
	signal ram1Data        : std_logic_vector(3 downto 0);

begin

	-- Two RAM blocks, each straddling the 16MHz and 25MHz clock domains, for storing pixel lines;
	-- whilst we're reading from one at 25MHz, we're writing to the other at 16MHz. Their roles
	-- swap every incoming 64us scanline.
	--
	ram0: entity work.rgb2vga_dpram
		port map(
			-- Write port
			wrclock   => clock,
			wraddress => std_logic_vector(hCount16),
			wren      => writeEn0,
			data      => rgbi_in,

			-- Read port
			rdclock   => clk25,
			rdaddress => std_logic_vector(hCount25(9 downto 0)),
			q         => ram0data
		);
	ram1: entity work.rgb2vga_dpram
		port map(
			-- Write port
			wrclock   => clock,
			wraddress => std_logic_vector(hCount16),
			wren      => writeEn1,
			data      => rgbi_in,

			-- Read port
			rdclock   => clk25,
			rdaddress => std_logic_vector(hCount25(9 downto 0)),
			q         => ram1data
		);

	-- 16MHz clock domain ---------------------------------------------------------------------------
	process(clock)
	begin
		if rising_edge(clock) then
            if clken = '1' then
                hSync_s16 <= hSync_in;
                vSync_s16 <= vSync_in;
                hCount16  <= hCount16_next;
                lineToggle <= lineToggle_next;
                state <= state_next;
            end if;
		end if;
	end process;

	-- Pulses representing the start of incoming HSYNC & VSYNC
	hSyncStart <=
		'1' when hSync_s16 = '0' and hSync_in = '1'
		else '0';
	vSyncStart <=
		'1' when vSync_s16 = '0' and vSync_in = '1'
		else '0';

	-- Create horizontal count, aligned to incoming HSYNC
	hCount16_next <=
		to_unsigned(2**10 - SAMPLE_OFFSET + 1, 10) when hSyncStart = '1'
		else hCount16 + 1;

	-- Toggle every incoming HSYNC
	lineToggle_next <=
		not(lineToggle) when hSyncStart = '1'
		else lineToggle;

	-- Generate interleaved write signals for dual-port RAMs
	writeEn0 <=
		'1' when hCount16 < SAMPLE_WIDTH and lineToggle = '0' and clken = '1'
		else '0';
	writeEn1 <=
		'1' when hCount16 < SAMPLE_WIDTH and lineToggle = '1' and clken = '1'
		else '0';

	-- Interleave output of dual-port RAMs
	rgbi_out <=
		ram0Data when lineToggle = '1'
		else ram1Data;
		
	-- State machine to generate VGA VSYNC
	process(state, vSyncStart, hSyncStart, hCount16(9))
	begin
		state_next <= state;
		case state is
			-- Wait for VSYNC start
			when S_WAIT_VSYNC =>
				vSync_out <= '1';
				if ( vSyncStart = '1' ) then
					if ( hCount16(9) = '0' ) then
						state_next <= S_EXTRA1;
					else
						state_next <= S_NOEXTRA;
					end if;
				end if;

			-- Insert an extra 64us scanline
			when S_EXTRA1 =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_EXTRA2;  -- 0.5 lines after VSYNC
				end if;
			when S_EXTRA2 =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_ASSERT_VSYNC;  -- 1.5 lines after VSYNC
				end if;

			-- Don't insert an extra 64us scanline
			when S_NOEXTRA =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_ASSERT_VSYNC;  -- 0.5 lines after VSYNC
				end if;

			-- Assert VGA VSYNC for 64us
			when S_ASSERT_VSYNC =>
				vSync_out <= '0';
				if ( hSyncStart = '1' ) then
					state_next <= S_WAIT_VSYNC;
				end if;
		end case;
	end process;

	-- 25MHz clock domain ---------------------------------------------------------------------------
	process(clk25)
	begin
		if ( rising_edge(clk25) ) then
			hCount25  <= hCount25_next;
			hSync_s25a <= hSync_in;
			hSync_s25b <= hSync_s25a;
		end if;
	end process;

	-- Generate 25MHz hCount
	hCount25_next <=
		to_unsigned(2**width25 - HORIZ_RT - HORIZ_BP, width25) when
			(hSync_s25a = '1' and hSync_s25b = '0') or
			(hCount25 = HORIZ_DISP + HORIZ_FP - 1)
		else hCount25 + 1;

	-- Generate VGA HSYNC
	hSync_out <=
		'0' when hCount25 >= to_unsigned(2**width25 - HORIZ_RT - HORIZ_BP, width25) and hCount25 < to_unsigned(2**width25 - HORIZ_BP, width25)
		else '1';

end architecture;
