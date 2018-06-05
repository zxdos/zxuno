--  Cart bank switching and memory access core
--
--  Copyright (C) 2011-2014 Matthias Reichl <hias@horus.com>
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Lesser GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;

entity CartLogic is
    Port (	clk: in std_logic;
		clk_enable: in std_logic;
		cart_mode: in std_logic_vector(5 downto 0);
		a: in std_logic_vector (12 downto 0);
		cctl_n: std_logic;
		d_in: in std_logic_vector(7 downto 0);
		rw: in std_logic;
		s4_n: in std_logic;
		s5_n: in std_logic;
		s4_n_out: out std_logic;
		s5_n_out: out std_logic;
		rd4: out std_logic;
		rd5: out std_logic;
		cart_address: out std_logic_vector(20 downto 0);
		cart_address_enable: out boolean;
		cctl_dout: out std_logic_vector(7 downto 0);
		cctl_dout_enable: out boolean
	);
		
end CartLogic;

architecture vhdl of CartLogic is

-- general cart configuration
signal cfg_bank: std_logic_vector(20 downto 13) := (others => '0');
signal cfg_enable: std_logic := '1';

subtype cart_mode_type is std_logic_vector(5 downto 0);
-- 8k modes
constant cart_mode_off:		cart_mode_type := "000000";
constant cart_mode_8k:		cart_mode_type := "000001";
constant cart_mode_atarimax1:	cart_mode_type := "000010";
constant cart_mode_atarimax8:	cart_mode_type := "000011";
constant cart_mode_oss:		cart_mode_type := "000100";

constant cart_mode_sdx64:	cart_mode_type := "001000";
constant cart_mode_diamond64:	cart_mode_type := "001001";
constant cart_mode_express64:	cart_mode_type := "001010";

constant cart_mode_atrax_128:	cart_mode_type := "001100";
constant cart_mode_williams_64:	cart_mode_type := "001101";

-- 16k modes
--constant cart_mode_flexi:	cart_mode_type := "100000";
constant cart_mode_16k:		cart_mode_type := "100001";
constant cart_mode_megamax16:	cart_mode_type := "100010";
constant cart_mode_blizzard_16:	cart_mode_type := "100011";
constant cart_mode_sic:		cart_mode_type := "100100";

constant cart_mode_mega_16:	cart_mode_type := "101000";
constant cart_mode_mega_32:	cart_mode_type := "101001";
constant cart_mode_mega_64:	cart_mode_type := "101010";
constant cart_mode_mega_128:	cart_mode_type := "101011";
constant cart_mode_mega_256:	cart_mode_type := "101100";
constant cart_mode_mega_512:	cart_mode_type := "101101";
constant cart_mode_mega_1024:	cart_mode_type := "101110";
constant cart_mode_mega_2048:	cart_mode_type := "101111";

constant cart_mode_xegs_32:	cart_mode_type := "110000";
constant cart_mode_xegs_64:	cart_mode_type := "110001";
constant cart_mode_xegs_128:	cart_mode_type := "110010";
constant cart_mode_xegs_256:	cart_mode_type := "110011";
constant cart_mode_xegs_512:	cart_mode_type := "110100";
constant cart_mode_xegs_1024:	cart_mode_type := "110101";

constant cart_mode_sxegs_32:	cart_mode_type := "111000";
constant cart_mode_sxegs_64:	cart_mode_type := "111001";
constant cart_mode_sxegs_128:	cart_mode_type := "111010";
constant cart_mode_sxegs_256:	cart_mode_type := "111011";
constant cart_mode_sxegs_512:	cart_mode_type := "111100";
constant cart_mode_sxegs_1024:	cart_mode_type := "111101";

signal cart_mode_prev: cart_mode_type := cart_mode_off;

-- OSS cart emulation
signal oss_bank: std_logic_vector(1 downto 0) := "00";

-- sic cart 8xxx/axxx enable
signal sic_8xxx_enable: std_logic := '0';
signal sic_axxx_enable: std_logic := '1';

signal access_8xxx: boolean;
signal access_axxx: boolean;

signal reset_n: std_logic := '1';

begin

access_8xxx <= ( s4_n = '0');
access_axxx <= ( s5_n = '0');

-- pass through s4/s5 if cart mode is off
set_passthrough: process(s4_n, s5_n, cart_mode)
begin
	if (cart_mode = cart_mode_off) then
		s4_n_out <= s4_n;
		s5_n_out <= s5_n;
	else
		s4_n_out <= '1';
		s5_n_out <= '1';
	end if;
end process set_passthrough;

-- remember previous cartridge mode
set_cart_mode_prev: process(clk)
begin
	if rising_edge(clk) then
		cart_mode_prev <= cart_mode;
	end if;
end process set_cart_mode_prev;

-- generate reset if cartridge mode has changed
generate_reset: process(cart_mode, cart_mode_prev)
begin
	if (cart_mode = cart_mode_prev) then
		reset_n <= '1';
	else
		reset_n <= '0';
	end if;
end process generate_reset;

-- read back config registers
config_io: process(a, rw, cctl_n,
	cfg_bank,
	cart_mode,
	sic_8xxx_enable, sic_axxx_enable)
begin
	cctl_dout_enable <= false;
	cctl_dout <= x"ff";

	if (cctl_n = '0') then
		-- sic register readback at $D500-$D51F
		if (rw = '1') and (cart_mode = cart_mode_sic) and (a(7 downto 5) = "000") then
			cctl_dout_enable <= true;
			-- bit 7 = 0 means flash is write protected
			cctl_dout <= "0" & (not sic_axxx_enable) & sic_8xxx_enable & cfg_bank(18 downto 14);
		end if;
	end if;
end process config_io;

set_config: process(clk)
begin
	if rising_edge(clk) then
		if (reset_n = '0') then
			cfg_bank <= (others => '0');
			cfg_enable <= '1';
			oss_bank <= "01";
			sic_8xxx_enable <= '0';
			sic_axxx_enable <= '1';

			-- cart specific initialization
			case cart_mode is
			when cart_mode_atarimax8 =>
				cfg_bank <= x"7F"; -- startup in last bank
			when others => null;
			end case;
		else
			if (clk_enable = '1') and (cctl_n = '0') then
				if (rw = '0') then
					-- modes using data lines to switch banks
					
					-- (s)xegs bank select
					if (cart_mode(5 downto 4) = cart_mode_xegs_32(5 downto 4)) then
						-- sxegs disable via bit 7
						if (cart_mode(3) = '1') then
							cfg_enable <= not d_in(7);
						end if;
						case cart_mode is
						when cart_mode_xegs_32 | cart_mode_sxegs_32 =>
							cfg_bank(14 downto 13) <= d_in(1 downto 0);
						when cart_mode_xegs_64 | cart_mode_sxegs_64 =>
							cfg_bank(15 downto 13) <= d_in(2 downto 0);
						when cart_mode_xegs_128 | cart_mode_sxegs_128 =>
							cfg_bank(16 downto 13) <= d_in(3 downto 0);
						when cart_mode_xegs_256 | cart_mode_sxegs_256 =>
							cfg_bank(17 downto 13) <= d_in(4 downto 0);
						when cart_mode_xegs_512 | cart_mode_sxegs_512 =>
							cfg_bank(18 downto 13) <= d_in(5 downto 0);
						when cart_mode_xegs_1024 | cart_mode_sxegs_1024 =>
							cfg_bank(19 downto 13) <= d_in(6 downto 0);
						when others =>
							null;
						end case;
					end if;
					-- megacart bank select
					if (cart_mode(5 downto 3) = cart_mode_mega_32(5 downto 3)) then
						-- disable via bit 7
						cfg_enable <= not d_in(7);
						case cart_mode is
						when cart_mode_mega_32 =>
							cfg_bank(14 downto 14) <= d_in(0 downto 0);
						when cart_mode_mega_64 =>
							cfg_bank(15 downto 14) <= d_in(1 downto 0);
						when cart_mode_mega_128 =>
							cfg_bank(16 downto 14) <= d_in(2 downto 0);
						when cart_mode_mega_256 =>
							cfg_bank(17 downto 14) <= d_in(3 downto 0);
						when cart_mode_mega_512 =>
							cfg_bank(18 downto 14) <= d_in(4 downto 0);
						when cart_mode_mega_1024 =>
							cfg_bank(19 downto 14) <= d_in(5 downto 0);
						when cart_mode_mega_2048 =>
							cfg_bank(20 downto 14) <= d_in(6 downto 0);
						when others =>
							null;
						end case;
					end if;
					-- atrax 128
					if (cart_mode = cart_mode_atrax_128) then
						cfg_enable <= not d_in(7);
						cfg_bank(16 downto 13)<= d_in(3 downto 0);
					end if;
					-- blizzard
					if (cart_mode = cart_mode_blizzard_16) then
						cfg_enable <= '0';
					end if;
					-- sic
					if (cart_mode = cart_mode_sic) and (a(7 downto 5) = "000") then
						sic_8xxx_enable <= d_in(5);
						sic_axxx_enable <= not d_in(6);
						cfg_bank(18 downto 14) <= d_in(4 downto 0);
					end if;
				end if; -- rw = 0
				
				-- cart config using addresses, ignore read/write
				case cart_mode is
				when cart_mode_oss =>
					oss_bank <= a(0) & NOT a(3);
				when cart_mode_atarimax1 =>
					-- D500-D50F: set bank, enable
					if (a(7 downto 4) = x"0") then
						cfg_bank(16 downto 13) <= a(3 downto 0);
						cfg_enable <= '1';
					end if;
					-- D510-D51F: disable
					if (a(7 downto 4) = x"1") then
						cfg_enable <= '0';
					end if;
				when cart_mode_atarimax8 =>
					-- D500-D57F: set bank, enable
					if (a(7) = '0') then
						cfg_bank(19 downto 13) <= a(6 downto 0);
						cfg_enable <= '1';
					else
					-- D580-D5FF: disable
						cfg_enable <= '0';
					end if;
				when cart_mode_megamax16 =>
					-- D500-D57F: set 16k bank, enable
					if (a(7) = '0') then
						cfg_bank(20 downto 14) <= a(6 downto 0);
						cfg_enable <= '1';
					else
						cfg_enable <= '0';
					end if;
				when cart_mode_williams_64 =>
					if (a(7 downto 4) = x"0") then
						cfg_enable <= not a(3);
						cfg_bank(15 downto 13) <= a(2 downto 0);
					end if;
				when cart_mode_sdx64 =>
					if (a(7 downto 4) = x"E") then
						cfg_enable <= not a(3);
						cfg_bank(15 downto 13) <= not a(2 downto 0);
					end if;
				when cart_mode_diamond64 =>
					if (a(7 downto 4) = x"D") then
						cfg_enable <= not a(3);
						cfg_bank(15 downto 13) <= not a(2 downto 0);
					end if;
				when cart_mode_express64 =>
					if (a(7 downto 4) = x"7") then
						cfg_enable <= not a(3);
						cfg_bank(15 downto 13) <= not a(2 downto 0);
					end if;
				when others => null;
				end case;
			end if;
		end if;
	end if;
end process set_config;

access_cart_data: process(a, rw, access_8xxx, access_axxx,
	cfg_bank, cfg_enable,
	cart_mode,
	oss_bank,
	sic_8xxx_enable, sic_axxx_enable)

variable bool_rd4: boolean;
variable bool_rd5: boolean;
begin
	cart_address <= cfg_bank & a(12 downto 0);

	bool_rd4 := false;
	bool_rd5 := (cfg_enable = '1');
	cart_address_enable <= (cfg_enable = '1') and access_axxx;

	if (cart_mode(5) = '1') then	-- default for 16k carts
		bool_rd4 := (cfg_enable = '1');
		cart_address_enable <= (cfg_enable = '1') and (access_8xxx or access_axxx);
	end if;

	case cart_mode is
	when cart_mode_8k |
	     cart_mode_atarimax1 | cart_mode_atarimax8 | 
	     cart_mode_atrax_128 | cart_mode_williams_64 |
	     cart_mode_sdx64 | cart_mode_diamond64 | cart_mode_express64 =>
		null;
	when cart_mode_16k | cart_mode_megamax16 | cart_mode_blizzard_16 =>
		if (access_8xxx) then
			cart_address(13) <= '0';
		else
			cart_address(13) <= '1';
		end if;
	when cart_mode_oss =>
		if (oss_bank = "00") then
			bool_rd5 := false;
			cart_address_enable <= false;
		else
			cart_address(13) <= oss_bank(1) and (not a(12));
			cart_address(12) <= oss_bank(0) and (not a(12));
		end if;
	when cart_mode_xegs_32 |cart_mode_sxegs_32 =>
		if (access_axxx) then
			cart_address(14 downto 13) <= (others => '1');
		end if;
	when cart_mode_xegs_64 | cart_mode_sxegs_64 =>
		if (access_axxx) then
			cart_address(15 downto 13) <= (others => '1');
		end if;
	when cart_mode_xegs_128 | cart_mode_sxegs_128 =>
		if (access_axxx) then
			cart_address(16 downto 13) <= (others => '1');
		end if;
	when cart_mode_xegs_256 | cart_mode_sxegs_256 =>
		if (access_axxx) then
			cart_address(17 downto 13) <= (others => '1');
		end if;
	when cart_mode_xegs_512 | cart_mode_sxegs_512 =>
		if (access_axxx) then
			cart_address(18 downto 13) <= (others => '1');
		end if;
	when cart_mode_xegs_1024 | cart_mode_sxegs_1024 =>
		if (access_axxx) then
			cart_address(19 downto 13) <= (others => '1');
		end if;
	when cart_mode_mega_16 | cart_mode_mega_32 | cart_mode_mega_64 | cart_mode_mega_128 |
	     cart_mode_mega_256 | cart_mode_mega_512 | cart_mode_mega_1024 | cart_mode_mega_2048 =>
		if (access_8xxx) then
			cart_address(13) <= '0';
		else
			cart_address(13) <= '1';
		end if;
	when cart_mode_sic =>
		bool_rd4 := (cfg_enable = '1') and (sic_8xxx_enable = '1');
		bool_rd5 := (cfg_enable = '1') and (sic_axxx_enable = '1');
		cart_address_enable <= (access_8xxx and (cfg_enable = '1') and (sic_8xxx_enable = '1'))
				or
			     (access_axxx and (cfg_enable = '1') and (sic_axxx_enable = '1'));
		if (access_8xxx) then
			cart_address(13) <= '0';
		else
			cart_address(13) <= '1';
		end if;
	when others =>
		bool_rd4 := false;
		bool_rd5 := false;
		cart_address_enable <= false;
	end case;

	if (bool_rd4) then
		rd4 <= '1';
	else
		rd4 <= '0';
	end if;

	if (bool_rd5) then
		rd5 <= '1';
	else
		rd5 <= '0';
	end if;

	-- disable writes
	if  (rw = '0') then
		cart_address_enable <= false;
	end if;

end process access_cart_data;

end vhdl;
