----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:05:23 07/23/2011 
-- Design Name: 
-- Module Name:    dummy_z80 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dummy_z80 is
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port (
		RESET_n	: in std_logic;
		CLK_n		: in std_logic;
		CLKEN		: in std_logic;
		WAIT_n	: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n	: in std_logic;
		M1_n		: out std_logic;
		MREQ_n	: out std_logic;
		IORQ_n	: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n	: out std_logic;
		HALT_n	: out std_logic;
		BUSAK_n	: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0));
end dummy_z80;

architecture Behavioral of dummy_z80 is

	signal count	: unsigned(8 downto 0) := (others => '0');
	
	type tregisters is array (0 to 15) of std_logic_vector(7 downto 0);
	type tpalette is array (0 to 31) of std_logic_vector(7 downto 0);
	
	signal registers : tregisters := (
		0  => "00000110",
		1  => "11100010",
		2  => "11111111",
		3  => "11111111",
		4  => "11111111",
		5  => "11111111",
		6  => "11111011",
		7  => "00000000",
		8  => "00000000",
		9  => "00000000",
		10 => "11111111",
		11 => "00000000",
		12 => "00000000",
		13 => "00000000",
		14 => "00000000",
		15 => "00000000");
	
	signal palette : tpalette := (
		0  => "00010000",
		1  => "00111111",
		2  => "00111101",
		3  => "00000000",
		4  => "00111001",
		5  => "00001100",
		6  => "00000011",
		7  => "00111111",
		8  => "00110001",
		9  => "00010011",
		10 => "00110101",
		11 => "00111000",
		12 => "00010111",
		13 => "00110011",
		14 => "00001111",
		15 => "00000100",
		16 => "00010000",
		17 => "00000110",
		18 => "00000000",
		19 => "00001011",
		20 => "00011011",
		21 => "00001100",
		22 => "00000011",
		23 => "00111111",
		24 => "00110001",
		25 => "00111010",
		26 => "00110101",
		27 => "00111000",
		28 => "00010111",
		29 => "00110011",
		30 => "00001111",
		31 => "00000100");

begin

	M1_n		<= '1';
	MREQ_n	<= '1';
	RD_n		<= '1';
	RFSH_n	<= '1';
	HALT_n	<= '1';
	BUSAK_n	<= '1';

	process (clk_n)
	begin
		if falling_edge(clk_n) then
			if count(8 downto 2)<32 then
				a <= "0000000010111111"; -- bf
				if count(2)='0' then
					do <= registers(to_integer(count(6 downto 3)));
				else
					do <= "1000"&std_logic_vector(count(6 downto 3)); -- register write
				end if;
			elsif count(8 downto 2)<62 then
			elsif count(8 downto 2)<64 then
				a <= "0000000010111111"; -- bf
				if count(2)='0' then
					do <= "00000000";
				else
					do <= "11000000";
				end if;
			elsif count(8 downto 2)<96 then
				a <= "0000000010111110"; -- be
				do <= palette(to_integer(count(6 downto 2)));
			end if;
			if count(8 downto 2)<96 then
				case count(1 downto 0) is
				when "00" => iorq_n <= '1'; wr_n<='1';
				when "01" => iorq_n <= '0'; wr_n<='0';
				when "10" => iorq_n <= '0'; wr_n<='1';
				when "11" => iorq_n <= '1'; wr_n<='1';
				when others =>
				end case;
				count <= count+1;
			end if;
		end if;
	end process;

end Behavioral;

