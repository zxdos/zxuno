--
-- Z80 compatible microprocessor core, asynchronous top level
--
-- Version : 0247a (+k01)
--
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
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
--  http://www.opencores.org/cvsweb.shtml/t80/
--
-- Limitations :
--
-- File history :
--
--  0208 : First complete release
--
--  0211 : Fixed interrupt cycle
--
--  0235 : Updated for T80 interface change
--
--  0238 : Updated for T80 interface change
--
--  0240 : Updated for T80 interface change
--
--  0242 : Updated for T80 interface change
--
--  0247 : Fixed bus req/ack cycle
--
--  0247a: 7th of September, 2003 by Kazuhiro Tsujikawa (tujikawa@hat.hi-ho.ne.jp)
--         Fixed IORQ_n, RD_n, WR_n bus timing
--
-------------------------------------------------------------------------------
--  +k01 : 2010.10.25  by KdL
--         Added RstKeyLock and swioRESET_n
--
--  2016.08 by Fabio Belavenuto: Refactoring signal names
--
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.T80_Pack.all;

entity T80a is
	generic(
		mode_g		: integer				:= 0		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	);
	port(
		reset_n_i	: in    std_logic;
		clock_i		: in    std_logic;
		clock_en_i	: in    std_logic;
		address_o	: out   std_logic_vector(15 downto 0);
		data_i		: in    std_logic_vector(7 downto 0);
		data_o		: out   std_logic_vector(7 downto 0);
		wait_n_i		: in    std_logic;
		int_n_i		: in    std_logic;
		nmi_n_i		: in    std_logic;
		m1_n_o		: out   std_logic;
		mreq_n_o		: out   std_logic;
		iorq_n_o		: out   std_logic;
		rd_n_o		: out   std_logic;
		wr_n_o		: out   std_logic;
		refresh_n_o	: out   std_logic;
		halt_n_o		: out   std_logic;
		busrq_n_i	: in    std_logic;
		busak_n_o	: out   std_logic
	);
end T80a;

architecture rtl of T80a is

    signal reset_s				: std_logic;
    signal int_cycle_n_s		: std_logic;
    signal iorq_s					: std_logic;
    signal noread_s				: std_logic;
    signal write_s				: std_logic;
    signal mreq_s					: std_logic;
    signal mreq_inhibit_s		: std_logic;
    signal ireq_inhibit_n_s	: std_logic;											-- 0247a
    signal req_inhibit_s		: std_logic;
    signal rd_s					: std_logic;
    signal mreq_n_s				: std_logic;
    signal iorq_n_s				: std_logic;
    signal rd_n_s					: std_logic;
    signal wr_n_s					: std_logic;
    signal wr_n_j_s				: std_logic;											-- 0247a
    signal rfsh_n_s				: std_logic;
    signal busak_n_s				: std_logic;
    signal address_s				: std_logic_vector(15 downto 0);
    signal data_out_s			: std_logic_vector(7 downto 0);
    signal data_r					: std_logic_vector (7 downto 0);					-- Input synchroniser
    signal wait_s					: std_logic;
    signal m_cycle_s				: std_logic_vector(2 downto 0);
    signal t_state_s				: std_logic_vector(2 downto 0);

begin

	mreq_n_s		<= not mreq_s	or (req_inhibit_s and mreq_inhibit_s);
	rd_n_s		<= not rd_s		or req_inhibit_s;
	wr_n_j_s		<= wr_n_s;																	-- 0247a (why ???)

	busak_n_o	<= busak_n_s;
	mreq_n_o		<= mreq_n_s								when busak_n_s = '1' else 'Z';
	iorq_n_o		<= iorq_n_s or ireq_inhibit_n_s	when busak_n_s = '1' else 'Z';	-- 0247a
	rd_n_o		<= rd_n_s								when busak_n_s = '1' else 'Z';
	wr_n_o		<= wr_n_j_s								when busak_n_s = '1' else 'Z';	-- 0247a
	refresh_n_o	<= rfsh_n_s								when busak_n_s = '1' else 'Z';
	address_o	<= address_s							when busak_n_s = '1' else (others => 'Z');
	data_o		<= data_out_s;

	process (reset_n_i, clock_i)
	begin
		if reset_n_i = '0' then
			reset_s <= '0';
		elsif rising_edge(clock_i) then
			reset_s <= '1';
		end if;
	end process;

	u0 : T80
		generic map(
			Mode		=> mode_g,
			IOWait	=> 1
		)
		port map(
			CEN			=> clock_en_i,
			M1_n			=> m1_n_o,
			IORQ			=> iorq_s,
			NoRead		=> noread_s,
			Write			=> write_s,
			RFSH_n		=> rfsh_n_s,
			HALT_n		=> halt_n_o,
			WAIT_n		=> wait_s,
			INT_n			=> int_n_i,
			NMI_n			=> nmi_n_i,
			RESET_n		=> reset_s,
			BUSRQ_n		=> busrq_n_i,
			BUSAK_n		=> busak_n_s,
			CLK_n			=> clock_i,
			A				=> address_s,
			DInst			=> data_i,
			DI 			=> data_r,
			DO				=> data_out_s,
			MC				=> m_cycle_s,
			TS				=> t_state_s,
			IntCycle_n	=> int_cycle_n_s
		);

	process (clock_i, clock_en_i)
	begin
		if falling_edge(clock_i) and clock_en_i = '1' then
			wait_s <= wait_n_i;
			if t_state_s = "011" and busak_n_s = '1' then
				data_r <= data_i;
			end if;
		end if;
	end process;

	process (clock_i)		-- 0247a
	begin
		if rising_edge(clock_i) then
			ireq_inhibit_n_s <= not iorq_s;
		end if;
	end process;

	process (reset_s, clock_i, clock_en_i)	-- 0247a
	begin
		if reset_s = '0' then
			wr_n_s <= '1';
		elsif falling_edge(clock_i) and clock_en_i = '1' then
			if iorq_s = '0' then
				if t_state_s = "010" then
					wr_n_s <= not write_s;
				elsif t_state_s = "011" then
					wr_n_s <= '1';
				end if;
			else
				if t_state_s = "001" and iorq_n_s = '0' then
					wr_n_s <= not write_s;
				elsif t_state_s = "011" then
					wr_n_s <= '1';
				end if;
			end if;
		end if;
	end process;

	process (reset_s, clock_i, clock_en_i)		-- 0247a
	begin
		if reset_s = '0' then
			req_inhibit_s <= '0';
		elsif rising_edge(clock_i) and clock_en_i = '1' then
			if m_cycle_s = "001" and t_state_s = "010" and wait_s = '1' then
				req_inhibit_s <= '1';
			else
				req_inhibit_s <= '0';
			end if;
		end if;
	end process;

	process (reset_s, clock_i, clock_en_i)
	begin
		if reset_s = '0' then
			mreq_inhibit_s <= '0';
		elsif falling_edge(clock_i) and clock_en_i = '1' then
			if m_cycle_s = "001" and t_state_s = "010" then
				mreq_inhibit_s <= '1';
			else
				mreq_inhibit_s <= '0';
			end if;
		end if;
	end process;

	process(reset_s, clock_i, clock_en_i)	-- 0247a
	begin
		if reset_s = '0' then
			rd_s		<= '0';
			iorq_n_s	<= '1';
			mreq_s	<= '0';
		elsif falling_edge(clock_i) and clock_en_i = '1' then
			if m_cycle_s = "001" then
				if t_state_s = "001" then
					rd_s		<= int_cycle_n_s;
					mreq_s	<= int_cycle_n_s;
					iorq_n_s	<= int_cycle_n_s;
				end if;
				if t_state_s = "011" then
					rd_s		<= '0';
					iorq_n_s	<= '1';
					mreq_s	<= '1';
				end if;
				if t_state_s = "100" then
					mreq_s	<= '0';
				end if;
			else
				if t_state_s = "001" and noread_s = '0' then
					iorq_n_s <= not iorq_s;
					mreq_s <= not iorq_s;
					if iorq_s = '0' then
						rd_s <= not write_s;
					elsif iorq_n_s = '0' then
						rd_s <= not write_s;
					end if;
				end if;
				if t_state_s = "011" then
					rd_s		<= '0';
					iorq_n_s	<= '1';
					mreq_s	<= '0';
				end if;
			end if;
		end if;
	end process;

end;
