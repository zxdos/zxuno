library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity ram is
	port (
		clk:		in   STD_LOGIC;
		RD_n:		in   STD_LOGIC;
		WR_n:		in   STD_LOGIC;
		A:			in   STD_LOGIC_VECTOR (12 downto 0);
		D_in:		in   STD_LOGIC_VECTOR (7 downto 0);
		D_out:	out  STD_LOGIC_VECTOR (7 downto 0));
end entity;

architecture Behavioral of ram is
begin
	ram_blocks:
	for i in 0 to 3 generate
	begin
		RAMB16_S2_inst : RAMB16_S2
		port map (
			CLK	=> clk,
			EN		=> '1',
			SSR	=> '0',
			WE		=> not WR_n,
			ADDR	=> a,
			DI		=> D_in((2*i+1) downto (2*i)),
			DO		=> D_out((2*i+1) downto (2*i))
		);
	end generate;

end Behavioral;

