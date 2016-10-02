--
-- A simulation model of VIC20 hardware
-- Copyright (c) MikeJ - March 2003
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
-- Email vic20@fpgaarcade.com
--
--
-- Revision list
--
-- version 001 initial release

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity VIC20_DBLSCAN is
  port (
	I_R               : in    std_logic_vector( 3 downto 0);
	I_G               : in    std_logic_vector( 3 downto 0);
	I_B               : in    std_logic_vector( 3 downto 0);
	I_HSYNC           : in    std_logic;
	I_VSYNC           : in    std_logic;
	I_BLANK           : in    std_logic;
	--
	O_R               : out   std_logic_vector( 3 downto 0);
	O_G               : out   std_logic_vector( 3 downto 0);
	O_B               : out   std_logic_vector( 3 downto 0);
	O_HSYNC           : out   std_logic;
	O_VSYNC           : out   std_logic;
	O_BLANK           : out   std_logic;
	--
	ENA               : in    std_logic;
	CLK               : in    std_logic
	);
end;

architecture RTL of VIC20_DBLSCAN is

  signal ram_ena     : std_logic;
  --
  -- input timing
  --
  signal hsync_in_t1 : std_logic;
  signal vsync_in_t1 : std_logic;
  signal hpos_i      : std_logic_vector(8 downto 0) := (others => '0');    -- input capture postion
  signal hsize_i     : std_logic_vector(8 downto 0);
  signal bank_i      : std_logic;
  signal rgb_in      : std_logic_vector(15 downto 0);
  --
  -- output timing
  --
  signal hpos_o      : std_logic_vector(8 downto 0) := (others => '0');
  signal ohs         : std_logic;
  signal ohs_t1      : std_logic;
  signal ovs         : std_logic;
  signal ovs_t1      : std_logic;
  signal bank_o      : std_logic;
  --
  signal vs_cnt      : std_logic_vector(2 downto 0);
  signal rgb_out     : std_logic_vector(15 downto 0);
   
begin

  p_input_timing : process
	variable rising_h : boolean;
	variable rising_v : boolean;
  begin
	wait until rising_edge (CLK);
	if (ENA = '1') then
	  hsync_in_t1 <= I_HSYNC;
	  vsync_in_t1 <= I_VSYNC;

	  rising_h := (I_HSYNC = '1') and (hsync_in_t1 = '0');
	  rising_v := (I_VSYNC = '1') and (vsync_in_t1 = '0');

	  if rising_v then
		bank_i <= '0';
	  elsif rising_h then
		bank_i <= not bank_i;
	  end if;

	  if rising_h then
		hpos_i <= (others => '0');
		hsize_i  <= hpos_i;
	  else
		hpos_i <= hpos_i + "1";
	  end if;
	end if;
  end process;

  rgb_in <= "000" & I_BLANK & I_B & I_G & I_R;

  u_ram : RAMB16_S18_S18
	generic map (
	  SIM_COLLISION_CHECK => "generate_x_only"
	  )
	port map (
	  -- output
	  DOPB  => open,
	  DOB   => rgb_out,
	  DIPB  => "00",
	  DIB   => x"0000",
	  ADDRB(9)          => bank_o,
	  ADDRB(8 downto 0) => hpos_o(8 downto 0),
	  WEB   => '0',
	  ENB   => '1',
	  SSRB  => '0',
	  CLKB  => CLK,

	  -- input
	  DOPA  => open,
	  DOA   => open,
	  DIPA   => "00",
	  DIA   => rgb_in,
	  ADDRA(9)          => bank_i,
	  ADDRA(8 downto 0) => hpos_i(8 downto 0),
	  WEA   => '1',
	  ENA   => ENA,
	  SSRA  => '0',
	  CLKA  => CLK
	  );

  p_output_timing : process
	variable rising_h : boolean;
  begin
	wait until rising_edge (CLK);

	  rising_h := ((ohs = '1') and (ohs_t1 = '0'));

	  if rising_h or (hpos_o = hsize_i) then
		hpos_o <= (others => '0');
	  else
		hpos_o <= hpos_o + "1";
	  end if;

	  if (ovs = '1') and (ovs_t1 = '0') then -- rising_v
		bank_o <= '1';
		vs_cnt <= "000";
	  elsif rising_h then
		bank_o <= not bank_o;
		if (vs_cnt(2) = '0') then
		  vs_cnt <= vs_cnt + "1";
		end if;
	  end if;

	  ohs <= I_HSYNC; -- reg on clk_12
	  ohs_t1 <= ohs;

	  ovs <= I_VSYNC; -- reg on clk_12
	  ovs_t1 <= ovs;

  end process;

  p_op : process
  begin
	wait until rising_edge (CLK);
	  O_HSYNC <= '0';
	  if (hpos_o < 32) then -- may need tweaking !
		O_HSYNC <= '1';
	  end if;
	    
	  O_BLANK <= rgb_out(12); 
	  
	  O_B <= rgb_out(11 downto 8);
	  O_G <= rgb_out(7 downto 4);
	  O_R <= rgb_out(3 downto 0);

	  O_VSYNC <= not vs_cnt(2);

  end process;

end architecture RTL;
