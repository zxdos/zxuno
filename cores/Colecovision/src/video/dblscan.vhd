--
-- Adapted for FPGA Colecovision by A. Laeuger, 26-Feb-2006
--
-- Based on
--
-- A simulation model of Pacman hardware
-- VHDL conversion by MikeJ - October 2002
--
-- FPGA PACMAN video scan doubler
--
-- based on a design by Tatsuyuki Satoh
--
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
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email pacman@fpgaarcade.com
--
-- Revision list
--
-- version 002 initial release
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dblscan is
	port (
		--  NOTE CLOCKS MUST BE PHASE LOCKED !!
		clk_6m_i			: in  std_logic;				-- input pixel clock (6MHz)
		clk_en_6m_i		: in  std_logic;
		clk_12m_i		: in  std_logic;				-- output clock      (12MHz)
		clk_en_12m_i	: in  std_logic;
		col_i				: in  std_logic_vector(3 downto 0);
		col_o				: out std_logic_vector(3 downto 0);
		oddline_o		: out std_logic;
		hsync_n_i		: in  std_logic;
		vsync_n_i		: in  std_logic;
		hsync_n_o		: out std_logic;
		vsync_n_o		: out std_logic;
		blank_o			: out std_logic
  );
end entity;

architecture rtl of dblscan is

	--
	-- input timing
	--
	signal hsync_n_t1_s		: std_logic;
	signal vsync_n_t1_s		: std_logic;
	signal hpos_s				: std_logic_vector(8 downto 0) := (others => '0');    -- input capture postion
	signal ibank_s				: std_logic;
	signal we_a_s				: std_logic;
	signal we_b_s				: std_logic;
	signal rgb_in_s			: std_logic_vector(3 downto 0);
	--
	-- output timing
	--
	signal hpos_o_s			: std_logic_vector(8 downto 0) := (others => '0');
	signal ohs_s				: std_logic;
	signal ohs_t1_s			: std_logic;
	signal ovs_s				: std_logic;
	signal ovs_t1_s			: std_logic;
	signal obank_s				: std_logic;
	signal oddline_s			: std_logic;
	--
	signal vs_cnt_s			: std_logic_vector(2 downto 0);
	signal rgb_out_a_s		: std_logic_vector(3 downto 0);
	signal rgb_out_b_s		: std_logic_vector(3 downto 0);

begin

	p_input_timing : process(clk_6m_i)
		variable rising_h_v : boolean;
		variable rising_v_v : boolean;
	begin
		if rising_edge (clk_6m_i) then
			if clk_en_6m_i = '1' then
				hsync_n_t1_s <= hsync_n_i;
				vsync_n_t1_s <= vsync_n_i;

				rising_h_v := (hsync_n_i = '0') and (hsync_n_t1_s = '1');
				rising_v_v := (vsync_n_i = '0') and (vsync_n_t1_s = '1');

				if rising_v_v then
					ibank_s <= '0';
				elsif rising_h_v then
					ibank_s <= not ibank_s;
				end if;

				if rising_h_v then
					hpos_s <= (others => '0');
				else
					hpos_s <= hpos_s + "1";
				end if;
			end if;
		end if;
	end process;

	we_a_s	<=     ibank_s and clk_en_6m_i;
	we_b_s	<= not ibank_s and clk_en_6m_i;
	rgb_in_s	<= col_i;

	u_ram_a : entity work.dpram
	generic map (
		addr_width_g => 9,
		data_width_g => 4
	)
	port map (
		clk_a_i  => clk_6m_i,
		we_i     => we_a_s,
		addr_a_i => hpos_s,
		data_a_i => rgb_in_s,
		data_a_o => open,
		clk_b_i  => clk_12m_i,
		addr_b_i => hpos_o_s,
		data_b_o => rgb_out_a_s
	);

	u_ram_b : entity work.dpram
	generic map (
		addr_width_g => 9,
		data_width_g => 4
	)
	port map (
		clk_a_i  => clk_6m_i,
		we_i     => we_b_s,
		addr_a_i => hpos_s,
		data_a_i => rgb_in_s,
		data_a_o => open,
		clk_b_i  => clk_12m_i,
		addr_b_i => hpos_o_s,
		data_b_o => rgb_out_b_s
	);

	p_output_timing : process (clk_12m_i)
		variable rising_h_v : boolean;
	begin
		if rising_edge (clk_12m_i) then
			if clk_en_12m_i = '1' then
				rising_h_v := (ohs_s = '0') and (ohs_t1_s = '1');

				if rising_h_v or (hpos_o_s = "101010101") then			-- 341
					hpos_o_s <= (others => '0');
					oddline_s <= not oddline_s;
				else
					hpos_o_s <= hpos_o_s + "1";
				end if;

				if (ovs_s = '0') and (ovs_t1_s = '1') then				-- rising_v_v
					obank_s <= '0';
					oddline_s <= '0';
					vs_cnt_s <= "000";
				elsif rising_h_v then
					obank_s <= not obank_s;
					if (vs_cnt_s(2) = '0') then
						vs_cnt_s <= vs_cnt_s + "1";
					end if;
				end if;

				ohs_s <= hsync_n_i; -- reg on clk_12m_i
				ohs_t1_s <= ohs_s;

				ovs_s <= vsync_n_i; -- reg on clk_12m_i
				ovs_t1_s <= ovs_s;
			end if;
		end if;
	end process;
	
	oddline_o <= oddline_s;

	p_op : process (clk_12m_i)
	begin
		if rising_edge(clk_12m_i) then
			if clk_en_12m_i = '1' then

				hsync_n_o <= '1';
				if (hpos_o_s < 32) then								-- 8
					hsync_n_o <= '0';
				end if;

				blank_o <= '0';
				if hpos_o_s < 56 or hpos_o_s > 295 then		-- <56  >295
					blank_o <= '1';
				end if;

				if (obank_s = '1') then
					col_o <= rgb_out_b_s;
				else
					col_o <= rgb_out_a_s;
				end if;

				vsync_n_o <= vs_cnt_s(2);
			end if;
		end if;
	end process;

end architecture;
