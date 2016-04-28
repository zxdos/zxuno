library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity vdp_vram is
	port (
		cpu_clk:		in  STD_LOGIC;
		cpu_WE:		in  STD_LOGIC;
		cpu_A:		in  STD_LOGIC_VECTOR (13 downto 0);
		cpu_D_in:	in  STD_LOGIC_VECTOR (7 downto 0);
		cpu_D_out:	out STD_LOGIC_VECTOR (7 downto 0);
		vdp_clk:	 	in  STD_LOGIC;
		vdp_A:		in  STD_LOGIC_VECTOR (13 downto 0);
		vdp_D_out:	out STD_LOGIC_VECTOR (7 downto 0));
end vdp_vram;

architecture Behavioral of vdp_vram is
begin
	ram_blocks:
	for b in 0 to 7 generate
	begin
		inst: RAMB16_S1_S1
		port map (
			CLKA	=> cpu_clk,
			ADDRA	=> cpu_A,
			DIA	=> cpu_D_in(b downto b),
			DOA	=> cpu_D_out(b downto b),
			ENA	=> '1',
			SSRA	=> '0',
			WEA	=> cpu_WE,

			CLKB	=> not vdp_clk,
			ADDRB	=> vdp_A,
			DIB	=> "0",
			DOB	=> vdp_D_out(b downto b),
			ENB	=> '1',
			SSRB	=> '0',
			WEB	=> '0'
		);
	end generate;

end Behavioral;
