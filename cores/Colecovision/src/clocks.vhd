-------------------------------------------------------------------------------
--
-- CoelcoFPGA project
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
use ieee.numeric_std.all;

entity clocks is
	port (
		clock_i			: in  std_logic;				-- 21 MHz
		por_i				: in  std_logic;
		clock_vdp_en_o	: out std_logic;
		clock_5m_en_o	: out std_logic;
		clock_3m_en_o	: out std_logic
	);
end entity;

architecture rtl of clocks is

	-- Clocks
	signal clk1_cnt_q			: unsigned(1 downto 0);
	signal clk2_cnt_q			: unsigned(1 downto 0);
	signal clock_vdp_en_s	: std_logic								:= '0';	-- 10.7 MHz 
	signal clock_5m_en_s		: std_logic								:= '0';
	signal clock_3m_en_s		: std_logic								:= '0';

begin

	-----------------------------------------------------------------------------
	process (clock_i, por_i)
	begin
		if por_i = '1' then
			clk1_cnt_q		<= (others => '0');
			clock_vdp_en_s	<= '0';
			clock_5m_en_s	<= '0';

		elsif rising_edge(clock_i) then
	 
			-- Clock counter --------------------------------------------------------
			if clk1_cnt_q = 3 then
				clk1_cnt_q <= (others => '0');
			else
				clk1_cnt_q <= clk1_cnt_q + 1;
			end if;

			-- 10.7 MHz clock enable ------------------------------------------------
			case clk1_cnt_q is
				when "01" | "11" =>
					clock_vdp_en_s <= '1';
				when others =>
					clock_vdp_en_s <= '0';
			end case;

			-- 5.37 MHz clock enable ------------------------------------------------
			case clk1_cnt_q is
				when "11" =>
					clock_5m_en_s <= '1';
				when others =>
					clock_5m_en_s <= '0';
			end case;
		end if;
	end process;


	-----------------------------------------------------------------------------
	process (clock_i, por_i)
	begin
		if por_i = '1' then
			clk2_cnt_q     <= (others => '0');
		elsif rising_edge(clock_i) then
			if clock_vdp_en_s = '1' then
				if clk2_cnt_q = 0 then
					clk2_cnt_q <= "10";
				else
					clk2_cnt_q <= clk2_cnt_q - 1;
				end if;
			end if;
		end if;
	end process;

	clock_3m_en_s <= clock_vdp_en_s	when	clk2_cnt_q = 0	else	'0';

	--
	clock_vdp_en_o	<= clock_vdp_en_s;
	clock_5m_en_o	<= clock_5m_en_s;
	clock_3m_en_o	<= clock_3m_en_s;

end architecture;