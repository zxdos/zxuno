----------------------------------------------------------------------------------
--  FreezerLogic.vhd - Freezer logic
--
--  Copyright (C) 2011-2012 Matthias Reichl <hias@horus.com>
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU Lesser General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;

entity FreezerLogic is
Port (		clk: in std_logic;
		clk_enable: in std_logic;
		a: in std_logic_vector(15 downto 0);
		d_in: in std_logic_vector(7 downto 0);
		rw: in std_logic;
		reset_n: in std_logic;
		activate_n: in std_logic;
		dualpokey_n: in std_logic;

		--output: out mem_output
		disable_atari: out boolean;
		access_type: out std_logic_vector(1 downto 0);
		access_address: out std_logic_vector(16 downto 0);
		d_out: out std_logic_vector(7 downto 0);
		request: in std_logic;
		request_complete: out std_logic;
		state_out: out std_logic_vector
	);
		
end FreezerLogic;

architecture RTL of FreezerLogic is

constant access_type_none:	std_logic_vector(1 downto 0) := "00";
constant access_type_data:	std_logic_vector(1 downto 0) := "01";
constant access_type_ram:	std_logic_vector(1 downto 0) := "10";
constant access_type_rom:	std_logic_vector(1 downto 0) := "11";

signal ram_bank: std_logic_vector(16 downto 12);
signal rom_bank: std_logic_vector(15 downto 13);

constant freezer_def_rom_bank:  std_logic_vector(15 downto 13)  := "100";
constant freezer_def_ram_bank:  std_logic_vector(16 downto 12)  := "11111";

subtype state_type is std_logic_vector(2 downto 0);
constant state_disabled: 	state_type := "000";
constant state_half_enabled: 	state_type := "001";
constant state_startup: 	state_type := "010";
constant state_enabled: 	state_type := "100";
constant state_temporary_disabled: state_type := "101";

signal state: state_type := state_disabled;

signal vector_access: boolean;
signal vector_a2: std_logic;
signal use_status_as_ram_address: boolean;

type mem_output is
record
	adr: std_logic_vector(16 downto 0);
	ram_access: boolean;
	rom_access: boolean;
	disable_atari: boolean;
	dout: std_logic_vector(7 downto 0);
	dout_enable: boolean;
	shadow_enable: boolean;
end record;

signal output: mem_output;

signal bram_adr: std_logic_vector(6 downto 0);
signal bram_data_out: std_logic_vector(7 downto 0);
signal bram_we: std_logic;
signal bram_request: std_logic;
signal bram_request_complete: std_logic;

begin

vector_access <= (a(15 downto 3) = "1111111111111") and (rw='1');

state_out <= state;

state_machine: process(clk)
begin
	if (rising_edge(clk)) then
		if (reset_n = '0') then
			state <= state_disabled;
		else
			if (clk_enable = '1') then
				case state is
				when state_disabled =>
					if vector_access and (activate_n = '0') and (a(0) = '0') then
						state <= state_half_enabled;
						vector_a2 <= a(2);
					end if;
				when state_half_enabled =>
					if vector_access and (activate_n = '0') and (a(0) = '1') then
						state <= state_startup;
					else
						state <= state_disabled;
					end if;
				when state_startup =>
					if (a(15 downto 4) = x"D72") then
						state <= state_enabled;
					end if;
				when state_enabled =>
					if (a(15 downto 4) = x"D70") then
						if (rw = '1') then
							state <= state_disabled;
						else
							state <= state_temporary_disabled;
						end if;
					end if;
				when state_temporary_disabled =>
					if (a(15 downto 4) = x"D70") then
						if (rw = '1') then
							state <= state_disabled;
						else
							state <= state_enabled;
						end if;
					end if;
				when others =>
					state <= state_disabled;
				end case;
			end if;
		end if;
	end if;
end process state_machine;

set_status_ram_address: process(clk)
begin
	if (rising_edge(clk)) then
		if (clk_enable = '1') then
			if (state = state_disabled) then
				use_status_as_ram_address <= false;
			else
				if (a(15 downto 4) = x"D71") then
					use_status_as_ram_address <= (rw = '1');
				end if;
			end if;
		end if;
	end if;
end process set_status_ram_address;

banksel: process(clk)
begin
	if (rising_edge(clk)) then
		if (clk_enable = '1') then
			if (state = state_disabled) then
				ram_bank <= (others => '0');
				rom_bank <= freezer_def_rom_bank;
			else
				-- D740-D77F
				if (a(15 downto 6) = "1101011101") then
					rom_bank <= a(2 downto 0);
				end if;
				-- D780-D79F
				if (a(15 downto 5) = "11010111100") then
					ram_bank <= a(4 downto 0);
				end if;
			end if;
		end if;
	end if;
end process banksel;

access_freezer: process(a, rw, state, vector_access, ram_bank, rom_bank, vector_a2, use_status_as_ram_address, dualpokey_n)
begin
	output.adr <= (others => '0');
	output.ram_access <= false;
	output.rom_access <= false;
	output.disable_atari <= false;
	output.dout <= (others => '1');
	output.dout_enable <= false;
	output.shadow_enable <= false;

	case state is
	when state_disabled | state_half_enabled =>
		-- shadow writes to D0xx, D2xx, D4xx
		if (rw = '0') then
			case a(15 downto 8) is
			when x"D0" | x"D2" | x"D3" | x"D4" =>
				output.shadow_enable <= true;
				output.adr(16 downto 8) <= freezer_def_ram_bank & a(11 downto 8);
				-- GTIA/D000 needs 32 bytes, others 16 bytes
				-- in dualpokey mode also shadow D2xx with 32 bytes
				if (a(10 downto 8) = "000") or (dualpokey_n = '0' and a(10 downto 8) = "010") then
					output.adr(4 downto 0) <= a(4 downto 0);
				else
					output.adr(3 downto 0) <= a(3 downto 0);
				end if;
			when others => null;
			end case;
		end if;
		if (state = state_half_enabled) and (vector_access) and (a(0) = '1') then
			-- re-route interrupt vectors to NOP slide page
			output.dout <= x"21";
			output.dout_enable <= true;
			output.disable_atari <= true;
		end if;
	when state_startup | state_enabled =>
		if (state = state_startup) and (vector_access) and (a(0) = '1') then
			-- re-route interrupt vectors to RTI slide page
			output.dout <= x"20";
			output.dout_enable <= true;
			output.disable_atari <= true;
		end if;
		-- 0000-1FFF: RAM (0000-0FFF fixed, 1000-1FFF switchable)
		if (a(15 downto 13) = "000") then
			output.ram_access <= true;
			output.disable_atari <= true;
			if (a(12) = '0') then
				output.adr(16 downto 12) <= freezer_def_ram_bank;
			else
				output.adr(16 downto 12) <= ram_bank;
			end if;
			output.adr(11 downto 0) <= a(11 downto 0);
			if (use_status_as_ram_address) then
				output.adr(4) <= vector_a2;
				output.adr(5) <= not dualpokey_n;
			end if;
		end if;
		-- 2000-3FFF: switched ROM bank
		if (a(15 downto 13) = "001") then
			if (rw = '1') then
				output.rom_access <= true;
			end if;
			output.disable_atari <= true;
			output.adr <= "0" & rom_bank & a(12 downto 0);
		end if;
		-- D7xx freezer control, disable Atari memory
		if (a(15 downto 8) = x"D7") then
			output.disable_atari <= true;
		end if;
	when state_temporary_disabled =>
		-- D7xx freezer control, disable Atari memory
		if (a(15 downto 8) = x"D7") then
			output.disable_atari <= true;
		end if;
	when others => null;
	end case;
end process access_freezer;

memory_glue: process(output, rw, bram_data_out, request, bram_request_complete)
begin
	disable_atari <= output.disable_atari;
	access_type <= access_type_none;
	access_address <= output.adr;
	request_complete <= '0';
	d_out <= (others => '1');
	bram_adr <= (others => '0');
	bram_we <= '0';
	bram_request <= '0';

	if (output.shadow_enable) then
		bram_adr <= output.adr(9)&(output.adr(8) or output.adr(10))&output.adr(4 downto 0);
		bram_we <= '1';
	elsif (output.dout_enable) then
		access_type <= access_type_data;
		d_out <= output.dout;
		request_complete <= request;
	elsif (output.rom_access) then
		access_type <= access_type_rom;
	elsif (output.ram_access) then
		access_type <= access_type_ram;

		-- map shadow ram access to blockram
		if (output.adr(16 downto 12) = freezer_def_ram_bank) and (output.adr(7 downto 5) = "000") then
			case output.adr(11 downto 8) is
			when x"0" | x"2" | x"3" | x"4" =>
				access_type <= access_type_data;
				bram_adr <= output.adr(9)&(output.adr(8) or output.adr(10))&output.adr(4 downto 0);
				bram_we <= request and not rw;
				bram_request <= request;
				request_complete <= bram_request_complete;
				d_out <= bram_data_out;
			when others => null;
			end case;
		end if;
	end if;
end process memory_glue;

process(clk, reset_n)
begin
	if rising_edge(clk) then
		if (reset_n = '0') then
			bram_request_complete <= '0';
		else
			bram_request_complete <= bram_request;
		end if;
	end if;
end process;

freezer_bram: entity work.generic_ram_infer
	generic map
        (
		ADDRESS_WIDTH => 7,
		SPACE => 128,
		DATA_WIDTH =>8
	)
	PORT MAP(clock => clk,
		address => bram_adr,
		data => d_in,
		we => bram_we,
		q => bram_data_out
	);

end RTL;

