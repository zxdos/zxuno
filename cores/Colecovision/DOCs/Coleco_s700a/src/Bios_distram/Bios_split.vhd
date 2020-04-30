library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.all;

entity coleco_bios is
	port(
		Clk	: in std_logic;
		A	: in std_logic_vector(12 downto 0);
		D	: out std_logic_vector(7 downto 0)
	);
end coleco_bios;

architecture rtl of coleco_bios is

	signal Ar	: std_logic_vector(12 downto 0);
	signal DATA1	: std_logic_vector(7 downto 0);
	signal DATA2	: std_logic_vector(7 downto 0);
	signal DATA3	: std_logic_vector(7 downto 0);
	signal DATA4	: std_logic_vector(7 downto 0);

begin

	process (Clk)
	begin
		if Clk'event and Clk = '1' then
			Ar <= A;
		end if;
	end process;

	entity_ace_rom_hll : entity cart_rom2(rtl)
		port map(
			CLK	=> Clk,
			ADDR	=> A(11 downto 0),
			DATA => DATA2);

	entity_ace_rom_hlh : entity cart_rom3(rtl)
		port map(
			CLK	=> Clk,
			ADDR	=> Ar(11 downto 0),
			DATA => DATA3);

	entity_ace_rom_hh : entity cart_rom4(rtl)
		port map(
			CLK	=> Clk,
			ADDR	=> Ar(11 downto 0),
			DATA => DATA4);

	entity_ace_rom_l : entity cart_rom1(rtl)
		port map(
			CLK	=> Clk,
			ADDR	=> A(11 downto 0),
			DATA => DATA1);

	D <= DATA2 when Ar(12 downto 10) = "100" else
		DATA3 when Ar(12 downto 10) = "101" else
		DATA4 when Ar(12 downto 11) = "11" 
		else DATA1;

end;
