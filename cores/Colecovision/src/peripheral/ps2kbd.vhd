-- PS/2 serial port, input only
--
-- Version : 0242
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
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
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--	http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--	0242 : First release
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ps2kbd is
	port(
		Rst_n		: in std_logic;
		Clk			: in std_logic;
		Tick1us		: in std_logic;
		PS2_Clk		: in std_logic;
		PS2_Data	: in std_logic;
		Press		: out std_logic;
		Release		: out std_logic;
		Reset		: out std_logic;
		ScanCode	: out std_logic_vector(7 downto 0));
end ps2kbd;

architecture rtl of ps2kbd is

	signal	PS2_Sample		: std_logic;
	signal	PS2_Data_s		: std_logic;

	signal	RX_Bit_Cnt		: unsigned(3 downto 0);
	signal	RX_Byte			: unsigned(2 downto 0);
	signal	RX_ShiftReg		: std_logic_vector(7 downto 0);
	signal	RX_Release		: std_logic;
	signal	RX_Received		: std_logic;

begin

	ScanCode <= RX_ShiftReg;

	process (Clk, Rst_n)
		variable PS2_Data_r		: std_logic_vector(1 downto 0);
		variable PS2_Clk_r		: std_logic_vector(1 downto 0);
		variable PS2_Clk_State	: std_logic;
	begin
		if Rst_n = '0' then
			PS2_Sample <= '0';
			PS2_Data_s <= '0';
			PS2_Data_r := "11";
			PS2_Clk_r := "11";
			PS2_Clk_State := '1';
		elsif Clk'event and Clk = '1' then
			if Tick1us = '1' then
				PS2_Sample <= '0';

				-- Deglitch
				if PS2_Data_r = "00" then
					PS2_Data_s <= '0';
				end if;
				if PS2_Data_r = "11" then
					PS2_Data_s <= '1';
				end if;
				if PS2_Clk_r = "00" then
					if PS2_Clk_State = '1' then
						PS2_Sample <= '1';
					end if;
					PS2_Clk_State := '0';
				end if;
				if PS2_Clk_r = "11" then
					PS2_Clk_State := '1';
				end if;

				-- Double synchronise
				PS2_Data_r(1) := PS2_Data_r(0);
				PS2_Clk_r(1) := PS2_Clk_r(0);
				PS2_Data_r(0) := PS2_Data;
				PS2_Clk_r(0) := PS2_Clk;
			end if;
		end if;
	end process;

	process (Clk, Rst_n)
		variable Cnt : integer;
	begin
		if Rst_n = '0' then
			RX_Bit_Cnt <= (others => '0');
			RX_ShiftReg <= (others => '0');
			RX_Received <= '0';
			Cnt := 0;
		elsif Clk'event and Clk = '1' then
			RX_Received <= '0';
			if Tick1us = '1' then

				if PS2_Sample = '1' then
					if RX_Bit_Cnt = "0000" then
						if PS2_Data_s = '0' then -- Start bit
							RX_Bit_Cnt <= RX_Bit_Cnt + 1;
						end if;
					elsif RX_Bit_Cnt = "1001" then -- Parity bit
						RX_Bit_Cnt <= RX_Bit_Cnt + 1;
						-- Ignoring parity
					elsif RX_Bit_Cnt = "1010" then -- Stop bit
						if PS2_Data_s = '1' then
							RX_Received <= '1';
						end if;
						RX_Bit_Cnt <= "0000";
					else
						RX_Bit_Cnt <= RX_Bit_Cnt + 1;
						RX_ShiftReg(6 downto 0) <= RX_ShiftReg(7 downto 1);
						RX_ShiftReg(7) <= PS2_Data_s;
					end if;
				end if;

				-- TimeOut
				if PS2_Sample = '1' then
					Cnt := 0;
				elsif Cnt = 127 then
					RX_Bit_Cnt <= "0000";
					Cnt := 0;
				else
					Cnt := Cnt + 1;
				end if;
			end if;
		end if;
	end process;

	process (Clk, Rst_n)
	begin
		if Rst_n = '0' then
			Press <= '0';
			Release <= '0';
			Reset <= '0';
			RX_Byte <= (others => '0');
			RX_Release <= '0';
		elsif Clk'event and Clk = '1' then
			Press <= '0';
			Release <= '0';
			Reset <= '0';
			if RX_Received = '1' then
				RX_Byte <= RX_Byte + 1;
				if RX_ShiftReg = x"F0" then
					RX_Release <= '1';
				elsif RX_ShiftReg = x"E0" then
				else
					RX_Release <= '0';
					-- Normal key press
					if RX_Release = '0' then
						Press <= '1';
					end if;
					-- Normal key release
					if RX_Release = '1' then
						Release <= '1';
					end if;
				end if;
				if RX_ShiftReg = x"aa" then
					Reset <= '1';
				end if;
			end if;
		end if;
	end process;

end;
