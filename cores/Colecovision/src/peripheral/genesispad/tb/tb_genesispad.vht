--
-- Copyright (c) 2016 - Fabio Belavenuto
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
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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
-- You are responsible for any legal issues arising from your use of this code.
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb is
end tb;

architecture testbench of tb is

	-- test target
	component genesispad
	generic (
		clocks_per_1us_g : integer		:= 2	-- number of clock_i periods during 1us
	);
	port (
		clock_i			: in  std_logic;
		reset_i			: in  std_logic;
		-- Gamepad interface
		pad_p1_i			: in  std_logic;
		pad_p2_i			: in  std_logic;
		pad_p3_i			: in  std_logic;
		pad_p4_i			: in  std_logic;
		pad_p6_i			: in  std_logic;
		pad_p7_o			: out std_logic;
		pad_p9_i			: in  std_logic;
		-- Buttons
		but_up_o			: out std_logic;
		but_down_o		: out std_logic;
		but_left_o		: out std_logic;
		but_right_o		: out std_logic;
		but_a_o			: out std_logic;
		but_b_o			: out std_logic;
		but_c_o			: out std_logic;
		but_x_o			: out std_logic;
		but_y_o			: out std_logic;
		but_z_o			: out std_logic;
		but_start_o		: out std_logic;
		but_mode_o		: out std_logic
	);
	end component;

	signal tb_end			: std_logic;
	signal clock_s			: std_logic;
	signal reset_s			: std_logic;
	signal pad_p1_s			: std_logic;
	signal pad_p2_s			: std_logic;
	signal pad_p3_s			: std_logic;
	signal pad_p4_s			: std_logic;
	signal pad_p6_s			: std_logic;
	signal pad_p7_s			: std_logic;
	signal pad_p9_s			: std_logic;
	signal but_up_s			: std_logic;
	signal but_down_s		: std_logic;
	signal but_left_s		: std_logic;
	signal but_right_s		: std_logic;
	signal but_a_s			: std_logic;
	signal but_b_s			: std_logic;
	signal but_c_s			: std_logic;
	signal but_x_s			: std_logic;
	signal but_y_s			: std_logic;
	signal but_z_s			: std_logic;
	signal but_start_s		: std_logic;
	signal but_mode_s		: std_logic;

begin

	--  instance
	u_target: genesispad
	generic map (
		clocks_per_1us_g	=> 14
	)
	port map(
		clock_i			=> clock_s,
		reset_i			=> reset_s,
		-- Gamepad interface
		pad_p1_i		=> pad_p1_s,
		pad_p2_i		=> pad_p2_s,
		pad_p3_i		=> pad_p3_s,
		pad_p4_i		=> pad_p4_s,
		pad_p6_i		=> pad_p6_s,
		pad_p7_o		=> pad_p7_s,
		pad_p9_i		=> pad_p9_s,
		-- Buttons
		but_up_o		=> but_up_s,
		but_down_o		=> but_down_s,
		but_left_o		=> but_left_s,
		but_right_o		=> but_right_s,
		but_a_o			=> but_a_s,
		but_b_o			=> but_b_s,
		but_c_o			=> but_c_s,
		but_x_o			=> but_x_s,
		but_y_o			=> but_y_s,
		but_z_o			=> but_z_s,
		but_start_o		=> but_start_s,
		but_mode_o		=> but_mode_s
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
		wait for 35.71 ns;
		clock_s <= '1';
		wait for 35.71 ns;
	end process;

	-- ----------------------------------------------------- --
	--  test bench                                           --
	-- ----------------------------------------------------- --
	process
	begin
		-- init
		pad_p1_s	<= '1';
		pad_p2_s	<= '1';
		pad_p3_s	<= '1';
		pad_p4_s	<= '0';
		pad_p6_s	<= '1';
		pad_p9_s	<= '1';

		-- reset
		reset_s	<= '1';
		wait until( rising_edge(clock_s) );
		wait until( rising_edge(clock_s) );
		wait until( rising_edge(clock_s) );
		reset_s	<= '0';
		wait until( rising_edge(clock_s) );
		wait until( rising_edge(clock_s) );

		wait for 30 ms;

		-- wait
		tb_end <= '1';
		wait;
	end process;

end testbench;
