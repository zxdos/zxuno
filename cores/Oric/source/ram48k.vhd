--
-- 48K RAM comprised of three smaller 16K RAMs
--
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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity ram48k is
port (
	clk  : in  std_logic;
	cs   : in  std_logic;
	oe   : in  std_logic;
	we   : in  std_logic;
	addr : in  std_logic_vector(15 downto 0);
	di   : in  std_logic_vector( 7 downto 0);
	do   : out std_logic_vector( 7 downto 0)
);
end;

architecture RTL of ram48k is
	signal ro0, ro1, ro2, ro3 : std_logic_vector(7 downto 0);
	signal cs0, cs1, cs2, cs3: std_logic := '0';
begin

	cs0 <= '1' when cs='1' and addr(15 downto 14)="00" else '0';
	cs1 <= '1' when cs='1' and addr(15 downto 14)="01" else '0';
	cs2 <= '1' when cs='1' and addr(15 downto 14)="10" else '0';
        cs3 <= '1' when cs='1' and addr(15 downto 14)="11" else '0';

	do <=   
          ro0 when oe='1' and cs0='1' else
          ro1 when oe='1' and cs1='1' else
          ro2 when oe='1' and cs2='1' else
          ro3 when oe='1' and cs3='1' else
          (others=>'0');

	RAM_0000_3FFF : entity work.ram16k
	port map (
		clk  => clk,
		cs   => cs0,
		we   => we,
		addr => addr(13 downto 0),
		di   => di,
		do   => ro0
	);

	RAM_4000_7FFF : entity work.ram16k
	port map (
		clk  => clk,
		cs   => cs1,
		we   => we,
		addr => addr(13 downto 0),
		di   => di,
		do   => ro1
	);
	RAM_8000_BFFF : entity work.ram16k
	port map (
		clk  => clk,
		cs   => cs2,
		we   => we,
		addr => addr(13 downto 0),
		di   => di,
		do   => ro2
	);
        ro3 <= (others => '0');
	-- RAM_C000_FFFF : entity work.ram16k
	-- port map (
	-- 	clk  => clk,
	-- 	cs   => cs3,
	-- 	we   => we,
	-- 	addr => addr(13 downto 0),
	-- 	di   => di,
	-- 	do   => ro3
	-- );

end RTL;
