--
-- PS2 keyboard module to emulate Oric Atmos key matrix
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity keyboard is
port(
	CLK		: in std_logic;
	RESETn	: in std_logic;

	PS2CLK	: in std_logic;
	PS2DATA	: in std_logic;

	COL		: in std_logic_vector(2 downto 0);
	ROWbit	: out std_logic_vector(7 downto 0)	;
        KEY_PG_UP : out std_logic;
        KEY_PG_DOWN : out std_logic;
        KEY_S_LOCK : out std_logic;
        KEY_HOME : out std_logic;
        KEY_END : out std_logic
);
end keyboard;

architecture arch of keyboard is

	signal MAT_wROW : std_logic_vector(2 downto 0);
	signal MAT_wCOL : std_logic_vector(2 downto 0);
	signal MAT_wVAL : std_logic;
	signal MAT_WE   : std_logic;
	signal MAT_wEN  : std_logic;

	signal ROM_A    : std_logic_vector(7 downto 0);

begin

  decode: process (CLK, RESETn)
  begin
    if RESETn = '0' then
      KEY_PG_UP <= '0';
      KEY_PG_DOWN <= '0';
      KEY_S_LOCK <= '0';
      KEY_HOME <= '0';
      KEY_END <= '0';
    elsif rising_edge(CLK) then
      if (MAT_WE = '1') then
        if (ROM_A = x"7e") then
          KEY_S_LOCK <=not  MAT_wVAL;
        elsif (ROM_A = x"fd") then
          KEY_PG_UP <= not MAT_wVAL;
        elsif (ROM_A = x"fa") then
          KEY_PG_DOWN <= not MAT_wVAL;
        elsif (ROM_A = x"ec") then
          KEY_HOME <= not MAT_wVAL;
        elsif (ROM_A = x"e9") then
          KEY_END <= not MAT_wVAL;
        end if;
      end if;
    end if;
  end process;
  
        
          

	PS2 : entity work.ps2key port map(
		CLK      => CLK,
		RESETn   => RESETn,

		PS2CLK   => PS2CLK,
		PS2DATA  => PS2DATA,

		BREAK    => MAT_wVAL,
		EXTENDED => ROM_A(7),
		CODE(0)  => ROM_A(0),
		CODE(1)  => ROM_A(1),
		CODE(2)  => ROM_A(2),
		CODE(3)  => ROM_A(3),
		CODE(4)  => ROM_A(4),
		CODE(5)  => ROM_A(5),
		CODE(6)  => ROM_A(6),

		LATCH		=> MAT_WE
	);

	ROM : entity work.keymap port map(
		A        => ROM_A,
		ROW      => MAT_wROW,
		COL      => MAT_wCOL,
		EN       => MAT_wEN
	);

	MAT : entity work.keymatrix port map(
		CLK      => CLK,
		wROW     => MAT_wROW,
		wCOL     => MAT_wCOL,
		wVAL     => MAT_wVAL,
		wEN      => MAT_wEN,
		WE       => MAT_WE,

		rCOL     => COL,
		rROWbit  => ROWbit
	);

end arch;
