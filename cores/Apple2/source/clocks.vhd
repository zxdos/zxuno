--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.ALL;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.ALL;

library unisim;
	use unisim.vcomponents.all;

entity CLOCKGEN is
	generic (
		C_CLKFX_DIVIDE   : integer := 14;	-- target is 14 * 2 = 28
		C_CLKFX_MULTIPLY : integer := 8;
		C_CLKIN_PERIOD   : real    := 20.0  
	);
	port (
		I_CLK						: in	std_logic;
		I_RST						: in	std_logic;
		O_CLK_28M				: out	std_logic;
		O_CLK_14M				: out std_logic
	);
end CLOCKGEN;

architecture RTL of CLOCKGEN is
	signal clkfx_buf			: std_logic := '0';
	signal clkfb_buf			: std_logic := '0';
	
	signal clkdiv			: std_logic := '0';
	-- Output clock buffering
	signal clkfb				: std_logic := '0';
	signal clk0					: std_logic := '0';
	signal clkfx				: std_logic := '0';
begin

	O_CLK_28M <= clkfx_buf;
	clkout1_buf	: BUFG  port map (I => clkfx, O => clkfx_buf);

	dcm_sp_inst: DCM_SP
	generic map(
		CLKFX_DIVIDE				=> C_CLKFX_DIVIDE,
		CLKFX_MULTIPLY				=> C_CLKFX_MULTIPLY,
		CLKIN_PERIOD				=> C_CLKIN_PERIOD

	)
	port map (
		-- Input clock
		CLKIN			=> I_CLK,
		CLKFB			=> clkfb,
		-- Output clocks
		CLK0			=> clkfb,
		CLKFX			=> clkfx,
		-- Other control and status signals
		RST			=> I_RST
	);

	gen_clk : process(clkfx_buf, I_RST)
	begin
		if I_RST = '1' then
			clkdiv  <=  '0';
		elsif rising_edge(clkfx_buf) then
			clkdiv <= not clkdiv;
		end if;
	end process gen_clk;

	
	O_CLK_14M <= clkdiv;

end RTL;
