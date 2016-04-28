--
-- VHDL conversion by MikeJ - October 2002
--
-- FPGA video scan doubler
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
-- Email support@fpgaarcade.com
--
-- Revision list
--
-- version 002 initial release
-- version 003 Jan 2006 release, general tidy up
-- version 004 spartan3e release
-- version 005 simplified logic, uses only one RAMB
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity VGA_SCANDBL is
	port (
		I                : in  std_logic_vector( 6 downto 0);
		I_HSYNC          : in  std_logic;
		I_VSYNC          : in  std_logic;
		--
		O                : out std_logic_vector( 6 downto 0);
		O_HSYNC          : out std_logic;
		O_VSYNC          : out std_logic;
		--
		CLK              : in  std_logic;
		CLK_X2           : in  std_logic
	);
end;

architecture RTL of VGA_SCANDBL is
	signal CLK_DUP     : std_logic := '0';
	--
	-- input timing
	--
	signal ihs_t1      : std_logic := '0';
	signal ivs_t1      : std_logic := '0';
	signal hpos_i      : std_logic_vector(8 downto 0) := (others => '0');
	signal bank_i      : std_logic := '0';
	signal data_in     : std_logic_vector(6 downto 0) := (others => '0');
	signal hsize_i     : std_logic_vector(8 downto 0) := (others => '0');
	--
	-- output timing
	--
	signal ohs_t1      : std_logic := '0';
	signal ovs_t1      : std_logic := '0';
	signal hpos_o      : std_logic_vector(8 downto 0) := (others => '0');
	signal bank_o      : std_logic := '0';
	signal data_out    : std_logic_vector(6 downto 0) := (others => '0');
	signal vs_cnt      : std_logic_vector(2 downto 0) := (others => '0');
begin
	data_in <= I;

--u_ram : entity work.vga_framebuffer
--	port map (
--		rdaddress(9)	=> bank_o,
--		rdaddress(8 downto 0)	=> hpos_o,
--		rdclock		=> CLK_X2,
--		q				=> data_out,
--
--		wraddress(9)	=> bank_i,
--		wraddress(8 downto 0)	=> hpos_i,
--		wrclock		=> CLK,
--		wren			=> '1',
--		data			=> data_in
--	);

u_ram : RAMB16_S9_S9
	generic map (
		SIM_COLLISION_CHECK => "generate_x_only"
	)
	port map (
		-- input
		DOA               => open,
		DIA(7)				=> '0',
		DIA(6 downto 0)   => data_in,
		DOPA              => open,
		DIPA              => "0",
		ADDRA(10)         => '0',
		ADDRA(9)          => bank_i,
		ADDRA(8 downto 0) => hpos_i,
		WEA               => '1',
		ENA               => '1',
		SSRA              => '0',
		CLKA              => CLK,

		-- output
		DOB (7)  			=> open,
		DOB (6 downto 0)  => data_out,
		DIB               => x"00",
		DOPB              => open,
		DIPB              => "0",
		ADDRB(10)         => '0',
		ADDRB(9)          => bank_o,
		ADDRB(8 downto 0) => hpos_o,
		WEB               => '0',
		ENB               => '1',
		SSRB              => '0',
		CLKB              => CLK_X2
	);

CLK_DUP <= CLK;
p_input_timing : process(CLK_DUP)
	variable rising_h : boolean;
	variable rising_v : boolean;
begin
	if rising_edge (CLK_DUP) then
		ihs_t1 <= I_HSYNC;
		ivs_t1 <= I_VSYNC;
		rising_h := (I_HSYNC = '1') and (ihs_t1 = '0');
		rising_v := (I_VSYNC = '1') and (ivs_t1 = '0');

		if rising_v then
			bank_i <= '0';
		elsif rising_h then
			bank_i <= not bank_i;
		end if;

		if rising_h then
			hpos_i <= (others => '0');
			hsize_i <= hpos_i;
		else
			hpos_i <= hpos_i + "1";
		end if;
	end if;
end process;

p_output_timing : process(CLK_X2)
	variable rising_h : boolean;
	variable rising_v : boolean;
begin
	if rising_edge (CLK_X2) then
		ohs_t1 <= I_HSYNC;
		ovs_t1 <= I_VSYNC;
		rising_h := (I_HSYNC = '1') and (ohs_t1 = '0');
		rising_v := (I_VSYNC = '1') and (ovs_t1 = '0');

		if rising_h or (hpos_o = hsize_i) then
			hpos_o <= (others => '0');
		else
			hpos_o <= hpos_o + "1";
		end if;

		if rising_v then
			bank_o <= '1';
			vs_cnt <= (others => '0');
		elsif rising_h then
			bank_o <= not bank_o;
			if (vs_cnt(2) = '0') then
				vs_cnt <= vs_cnt + "1";
			end if;
		end if;
	end if;
end process;

p_output : process(CLK_X2)
begin
	if rising_edge (CLK_X2) then
		O_VSYNC <= not vs_cnt(2);
		if (hpos_o < 32) then
			O_HSYNC <= '1';
		else
			O_HSYNC <= '0';
		end if;

		O <= data_out;
	end if;
end process;

end architecture RTL;
