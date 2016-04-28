--
-- 16K RAM module using Xilinx RAMB blocks
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

library UNISIM;
	use UNISIM.Vcomponents.all;

entity ram16k is
port (
	clk  : in  std_logic;
	cs   : in  std_logic;
	we   : in  std_logic;
	addr : in  std_logic_vector(13 downto 0);
	di   : in  std_logic_vector( 7 downto 0);
	do   : out std_logic_vector( 7 downto 0)
);
end;

architecture RTL of ram16k is
begin

	RAM_CPU_0 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(0 downto 0),
		DO   => do(0 downto 0),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_1 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(1 downto 1),
		DO   => do(1 downto 1),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_2 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(2 downto 2),
		DO   => do(2 downto 2),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_3 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(3 downto 3),
		DO   => do(3 downto 3),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_4 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(4 downto 4),
		DO   => do(4 downto 4),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_5 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(5 downto 5),
		DO   => do(5 downto 5),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_6 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(6 downto 6),
		DO   => do(6 downto 6),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_7 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(7 downto 7),
		DO   => do(7 downto 7),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

end RTL;
