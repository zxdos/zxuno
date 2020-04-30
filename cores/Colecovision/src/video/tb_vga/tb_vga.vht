-------------------------------------------------------------------------------
--
-- MSX1 FPGA project
--
-- Copyright (c) 2016, Fabio Belavenuto (belavenuto@gmail.com)
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb is
end tb;

architecture testbench of tb is

	-- test target
	component vga
	port (
		I_CLK		: in std_logic;
		I_CLK_VGA	: in std_logic;
		I_COLOR		: in std_logic_vector(3 downto 0);
		I_HCNT		: in std_logic_vector(8 downto 0);
		I_VCNT		: in std_logic_vector(7 downto 0);
		O_HSYNC		: out std_logic;
		O_VSYNC		: out std_logic;
		O_COLOR		: out std_logic_vector(3 downto 0);
		O_HCNT		: out std_logic_vector(9 downto 0);
		O_VCNT		: out std_logic_vector(9 downto 0);
		O_H		: out std_logic_vector(9 downto 0);
		O_BLANK		: out std_logic
	);
	end component;

	signal tb_end				: std_logic;
	signal clock_s				: std_logic;
	signal clock_vga_s			: std_logic;
	signal rgb_col_s			: std_logic_vector( 3 downto 0)		:= "0000";
	signal cnt_hor_s			: std_logic_vector( 8 downto 0)		:= (others => '0');
	signal cnt_ver_s			: std_logic_vector( 7 downto 0)		:= (others => '0');
	signal vga_col_s			: std_logic_vector( 3 downto 0);
	signal vga_hsync_s			: std_logic;
	signal vga_vsync_s			: std_logic;
	signal blank_s				: std_logic;

begin

	--  instance
	u_target: vga
	port map (
		I_CLK		=> clock_s,
		I_CLK_VGA	=> clock_vga_s,
		I_COLOR		=> rgb_col_s,
		I_HCNT		=> cnt_hor_s,
		I_VCNT		=> cnt_ver_s,
		O_HSYNC		=> vga_hsync_s,
		O_VSYNC		=> vga_vsync_s,
		O_COLOR		=> vga_col_s,
		O_HCNT		=> open,
		O_VCNT		=> open,
		O_H			=> open,
		O_BLANK		=> blank_s
	);

	-- ----------------------------------------------------- --
	--  clock generator                                      --
	-- ----------------------------------------------------- --
	process
	begin
		if tb_end = '1' then
			wait;
		end if;
		clock_s <= '0';
		wait for 23.809 ns;
		clock_s <= '1';
		wait for 23.809 ns;
	end process;

	process
	begin
		if tb_end = '1' then
			wait;
		end if;
		clock_vga_s <= '0';
		wait for 19.841 ns;
		clock_vga_s <= '1';
		wait for 19.841 ns;
	end process;

	-- ----------------------------------------------------- --
	--  test bench                                           --
	-- ----------------------------------------------------- --
	process (clock_s)
	begin
		if rising_edge(clock_s) then
			rgb_col_s <= rgb_col_s + "1";
		end if;	
	end process;

	process (clock_s)
	begin
		if rising_edge(clock_s) then
			if cnt_hor_s = 280 then
				cnt_hor_s <= (others => '0');
				if cnt_ver_s = 212 then
					cnt_ver_s <= (others => '0');
				else
					cnt_ver_s <= cnt_ver_s + 1;
				end if;
			else
				cnt_hor_s <= cnt_hor_s + "1";
			end if;
		end if;	
	end process;

	process
	begin
		-- init

		wait until( rising_edge(clock_s) );

		wait for 200 ms;

		-- wait
		tb_end <= '1';
		wait;
	end process;

end testbench;
