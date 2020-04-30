-------------------------------------------------------------------------------
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
--
-- Generic single port RAM.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity spram is
	generic (
		addr_width_g : integer := 8;
		data_width_g : integer := 8
	);
	port (
		clk_i	: in  std_logic;
		we_i		: in  std_logic;
		addr_i	: in  std_logic_vector(addr_width_g-1 downto 0);
		data_i	: in  std_logic_vector(data_width_g-1 downto 0);
		data_o	: out std_logic_vector(data_width_g-1 downto 0)
	);

end spram;

library ieee;
use ieee.numeric_std.all;

architecture rtl of spram is

	type ram_t is array (natural range 2**addr_width_g-1 downto 0) of std_logic_vector(data_width_g-1 downto 0);
	signal ram_q : ram_t
		-- pragma translate_off
		:= (others => (others => '0'))
		-- pragma translate_on
	;
	signal read_addr_q : unsigned(addr_width_g-1 downto 0);

begin

	process (clk_i)
	begin
		if rising_edge(clk_i) then
			if we_i = '1' then
				ram_q(to_integer(unsigned(addr_i))) <= data_i;
			end if;

			read_addr_q <= unsigned(addr_i);
		end if;
	end process;

	data_o <= ram_q(to_integer(read_addr_q));

end rtl;
