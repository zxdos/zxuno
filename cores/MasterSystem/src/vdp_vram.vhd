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
		vdp_D_out:	out STD_LOGIC_VECTOR (7 downto 0)
		;RST_vram:	in	 std_logic
		);
end vdp_vram;

architecture Behavioral of vdp_vram is

--Q --vram_fill
	component vdp_vram_fill is
	port (
		cpu_clk:		in  STD_LOGIC;
		cpu_WE:		in  STD_LOGIC;
		cpu_A:		in  STD_LOGIC_VECTOR (13 downto 0);
		cpu_D_in:	in  STD_LOGIC_VECTOR (7 downto 0);
		cpu_D_out:	out STD_LOGIC_VECTOR (7 downto 0);
		vdp_clk:	 	in  STD_LOGIC;
		vdp_A:		in  STD_LOGIC_VECTOR (13 downto 0);
		vdp_D_out:	out STD_LOGIC_VECTOR (7 downto 0)
		);
	end component;

signal fcpu_D_in:		std_logic_vector (7 downto 0);
signal scpu_D_out:	std_logic_vector (7 downto 0);
signal svdp_D_out:	std_logic_vector (7 downto 0);
signal fcpu_D_out:	std_logic_vector (7 downto 0);
signal fvdp_D_out:	std_logic_vector (7 downto 0);
signal fcpu_WE:		std_logic;

begin
	ram_blocks:
	for b in 0 to 7 generate
	begin
		inst: RAMB16_S1_S1
		port map (
			CLKA	=> cpu_clk,
			ADDRA	=> cpu_A,
			DIA	=> cpu_D_in(b downto b),
			DOA	=> scpu_D_out(b downto b),
			ENA	=> '1',
			SSRA	=> '0',
			WEA	=> cpu_WE,

			CLKB	=> not vdp_clk,
			ADDRB	=> vdp_A,
			DIB	=> "0",
--			DOB	=> s_D_out(b downto b),
			DOB	=> svdp_D_out(b downto b),
			ENB	=> '1',
			SSRB	=> '0',
			WEB	=> '0'
		);
	end generate;
	
--Q --vram_fill
	vdp_vram_fill_inst: vdp_vram_fill
	port map(
		cpu_clk			=> cpu_clk,
		cpu_WE			=> fcpu_WE,
		cpu_A				=> cpu_A,
		cpu_D_in			=> cpu_D_in,
		cpu_D_out		=> fcpu_D_out,
		vdp_clk			=> vdp_clk,
		vdp_A				=> vdp_A,
		vdp_D_out		=> fvdp_D_out
		);		

vdp_D_out <= fvdp_D_out when RST_vram='1' 	else svdp_D_out;		
cpu_D_out <= fcpu_D_out when RST_vram='1' 	else scpu_D_out;		
fcpu_WE <= cpu_WE when RST_vram='1' 	else '0';	

end Behavioral;
