--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------
-- Video scan converter
--
--	Horizonal Timing
-- _____________              ______________________              _____________________
-- VIDEO (last) |____________|         VIDEO        |____________|         VIDEO (next)
-- -hD----------|-hA-|hB|-hC-|----------hD----------|-hA-|hB|-hC-|----------hD---------
-- __________________|  |________________________________|  |__________________________
-- HSYNC             |__|              HSYNC             |__|              HSYNC

-- Vertical Timing
-- _____________              ______________________              _____________________
-- VIDEO (last)||____________||||||||||VIDEO|||||||||____________||||||||||VIDEO (next)
-- -vD----------|-vA-|vB|-vC-|----------vD----------|-vA-|vB|-vC-|----------vD---------
-- __________________|  |________________________________|  |__________________________
-- VSYNC             |__|              VSYNC             |__|              VSYNC

-- Scan converter input and output timings compared to standard VGA
--  esolution   - Frame   | Pixel      | Front     | HSYNC      | Back       | Active      | HSYNC    | Front    | VSYNC    | Back     | Active    | VSYNC
--              - Rate    | Clock      | Porch hA  | Pulse hB   | Porch hC   | Video hD    | Polarity | Porch vA | Pulse vB | Porch vC | Video vD  | Polarity
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--  In  256x224 - 59.18Hz |  6.000 MHz | 38 pixels |  32 pixels |  58 pixels |  256 pixels | negative | 16 lines | 8 lines  | 16 lines | 224 lines | negative
--  Out 640x480 - 59.18Hz | 24.000 MHz |  2 pixels |  92 pixels |  34 pixels |  640 pixels | negative | 17 lines | 2 lines  | 29 lines | 480 lines | negative
--  VGA 640x480 - 59.94Hz | 25.175 MHz | 16 pixels |  96 pixels |  48 pixels |  640 pixels | negative | 10 lines | 2 lines  | 33 lines | 480 lines | negative

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

--pragma translate_off
	use ieee.std_logic_textio.all;
	use std.textio.all;
--pragma translate_on

library UNISIM;
	use UNISIM.Vcomponents.all;

entity VGA_SCANCONV is
	generic (
		cstart		: integer range 0 to 1023 := 144;	-- composite sync start
		clength		: integer range 0 to 1023 := 640;	-- composite sync length

		hA				: integer range 0 to 1023 :=  16;	-- h front porch
		hB				: integer range 0 to 1023 :=  96;	-- h sync
		hC				: integer range 0 to 1023 :=  48;	-- h back porch
		hD				: integer range 0 to 1023 := 640;	-- visible video

		vA				: integer range 0 to 1023 :=  16;	-- v front porch
		vB				: integer range 0 to 1023 :=   2;	-- v sync
		vC				: integer range 0 to 1023 :=  33;	-- v back porch
		vD				: integer range 0 to 1023 := 480;	-- visible video

		hpad			: integer range 0 to 1023 :=   0;	-- H black border
		vpad			: integer range 0 to 1023 :=   0		-- V black border
	);
	port (
		I_VIDEO				: in  std_logic_vector(15 downto 0);
		I_HSYNC				: in  std_logic;
		I_VSYNC				: in  std_logic;
		--
		O_VIDEO				: out std_logic_vector(15 downto 0);
		O_HSYNC				: out std_logic;
		O_VSYNC				: out std_logic;
		O_CMPBLK_N			: out std_logic;
		--
		CLK					: in  std_logic;
		CLK_x2				: in  std_logic
	);
end;

architecture RTL of VGA_SCANCONV is
-- type ram_t is array (0 to 1023) of std_logic_vector(15 downto 0);
-- signal ram : ram_t := (others => (others => '0'));
-- attribute ram_style: string;
-- attribute ram_style of ram : signal is "distributed";
--
	-- input timing
	--
	signal ivsync_last_x2	: std_logic := '1';
	signal ihsync_last_x2	: std_logic := '1';
	signal ihsync_last		: std_logic := '1';
	signal hpos_i				: std_logic_vector( 9 downto 0) := (others => '0');

	--
	-- output timing
	--
	signal hpos_o			: std_logic_vector(9 downto 0) := (others => '0');

	signal O_VIDEOb				: std_logic_vector(15 downto 0);
        signal O_CMPBLK_Nb			: std_logic;
        signal to_blank                         : std_logic;
	signal vcnt				: integer range 0 to 1023 := 0;
	signal hcnt				: integer range 0 to 1023 := 0;
	signal hcnti			: integer range 0 to 1023 := 0;

	signal CLK_x2_n		: std_logic := '1';

begin
  -- dual port line buffer, max line of 1024 pixels
  -- ram_write :process(CLK_x2)
  -- begin
  --   if rising_edge(CLK_x2) then
  --     ram(to_integer(unsigned((hpos_i)))) <= I_VIDEO;
  --   end if;
  -- end process;
  -- ram_read :process(CLK_x2)
  -- begin
  --   if falling_edge(CLK_x2) then
  --     O_VIDEO <= ram(to_integer(unsigned(hpos_o)));
  --   end if;
  -- end process;
  

	u_ram : RAMB16_S18_S18
		generic map (INIT_A => X"00000", INIT_B => X"00000", SIM_COLLISION_CHECK => "ALL")  -- "NONE", "WARNING", "GENERATE_X_ONLY", "ALL"
		port map (
			-- input
			DOA					=> open,
			DIA					=> I_VIDEO,
			DOPA					=> open,
			DIPA					=> "00",
			ADDRA					=> hpos_i,
			WEA					=> '1',
			ENA					=> CLK,
			SSRA					=> '0',
			CLKA					=> CLK_x2,

			-- output
			DOB					=> O_VIDEOb,
			DIB					=> x"0000",
			DOPB					=> open,
			DIPB					=> "00",
			ADDRB					=> hpos_o,
			WEB					=> '0',
			ENB					=> '1',
			SSRB					=> '0',
			CLKB					=> CLK_x2_n
		);

	CLK_x2_n <= not CLK_x2;

	-- horizontal counter for input video
	p_hcounter : process
	begin
		wait until rising_edge(CLK_x2);
		if CLK = '0' then
			ihsync_last <= I_HSYNC;

			-- trigger off rising hsync
			if I_HSYNC = '1' and ihsync_last = '0' then
				hcnti <= 0;
			else
				hcnti <= hcnti + 1;
			end if;
		end if;
	end process;

	-- increment write position during active video
	p_ram_in : process
	begin
		wait until rising_edge(CLK_x2);
		if CLK = '0' then
			if (hcnti < cstart) or (hcnti > (cstart + clength)) then
				hpos_i <= (others => '0');
			else
				hpos_i <= hpos_i + 1;
			end if;
		end if;
	end process;

	-- VGA H and V counters, synchronized to input frame V sync, then H sync
	p_out_ctrs : process
		variable trigger : boolean;
		variable triggerh : boolean;
	begin
		wait until rising_edge(CLK_x2);
		ivsync_last_x2 <= I_VSYNC;
		ihsync_last_x2 <= I_HSYNC;

		if (I_VSYNC = '0') and (ivsync_last_x2 = '1') then
                  trigger := true;
                end if;
		if trigger and (I_HSYNC = '1') and (ihsync_last_x2 = '0') then
                  triggerh := true;
                end if;
                
		if trigger and triggerh then
                  trigger := false;
                  triggerh:= false;
                  hcnt <= 0;
                  vcnt <= 0;
		else
			hcnt <= hcnt + 1;
			if hcnt = (hA+hB+hC+hD+hpad+hpad-1) then
                          hcnt <= 0;
                          if (vcnt <1023) then
                            vcnt <= vcnt + 1;
                          end if;
			end if;
		end if;
	end process;

	-- generate hsync
	p_gen_hsync : process
	begin
		wait until rising_edge(CLK_x2);
		-- H sync timing
		if (hcnt < hB) then
			O_HSYNC <= '0';
		else
			O_HSYNC <= '1';
		end if;
	end process;

	-- generate vsync
	p_gen_vsync : process
	begin
		wait until rising_edge(CLK_x2);
		-- V sync timing
		if (vcnt < vB)  then
			O_VSYNC <= '0';
		else
			O_VSYNC <= '1';
		end if;
	end process;

	-- generate active output video
	p_gen_active_vid : process
	begin
		wait until rising_edge(CLK_x2);
		-- visible video area doubled from the original game
		if ((hcnt >= (hB + hC + hpad)) and (hcnt <=(hB + hC + hD + hpad))) and ((vcnt >= 2*(vB + vC+vpad)) and (vcnt <= 2*(vB + vC + vD + vpad))) then
                  hpos_o <= hpos_o + 1;
		else
                  hpos_o <= (others => '0');
		end if;
	end process;

	-- generate blanking signal including additional borders to pad the input signal to standard VGA resolution
	p_gen_blank : process
	begin
		wait until rising_edge(CLK_X2);
		-- active video area 640x480 (VGA) after padding with blank borders
		if ((hcnt > (hB + hC +hpad)) and (hcnt <= (hB + hC + hD + hpad))) and ((vcnt >= 2*(vB + vC+vpad)) and (vcnt <= 2*(vB + vC + vD + vpad))) then
			O_CMPBLK_Nb <= '1';
                        to_blank <= '0';
		else
			O_CMPBLK_Nb <= '0';
                        to_blank <= '1';
		end if;
	end process;
        O_VIDEO <= O_VIDEOb when to_blank='0' else (others => '0');
        O_CMPBLK_N <= O_CMPBLK_Nb;
end architecture RTL;
