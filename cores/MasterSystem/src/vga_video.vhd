----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:59:35 01/22/2012 
-- Design Name: 
-- Module Name:    vdp_vga_timing - Behavioral 
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

entity vga_video is
	port (
		clk16:			in  std_logic;
		x: 				out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		vblank:			out std_logic;
		hblank:			out std_logic;
		color:			in  std_logic_vector(5 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		red:				out std_logic_vector(1 downto 0);
		green:			out std_logic_vector(1 downto 0);
		blue:				out std_logic_vector(1 downto 0));
end vga_video;

architecture Behavioral of vga_video is

	signal hcount:		unsigned (8 downto 0) := (others=>'0');
	signal vcount:		unsigned (9 downto 0) := (others=>'0');
	signal visible:	boolean;
	
	signal y9:			unsigned (8 downto 0);
	
begin
	
	process (clk16)
	begin
		if rising_edge(clk16) then
			if hcount=507 then
				hcount <= (others => '0');
				if vcount=523 then
					vcount <= (others=>'0');
				else
					vcount <= vcount + 1;
				end if;
			else
				hcount <= hcount + 1;
			end if;
		end if;
	end process;
	
	x				<= hcount-(91+62);
	y9				<= vcount(9 downto 1)-(13+27);
	y				<= y9(7 downto 0);
	hblank		<= '1' when hcount=0 and vcount(0 downto 0)=0 else '0';
	vblank		<= '1' when hcount=0 and vcount=0 else '0';
	
	hsync			<= '0' when hcount<61 else '1';
	vsync			<= '0' when vcount<2 else '1';
	
	visible		<= vcount>=35 and vcount<35+480 and hcount>=91 and hcount<91+406;
	
	process (clk16)
	begin
		if rising_edge(clk16) then
			if visible then
					red		<= color(1 downto 0);
					green	<= color(3 downto 2);
					blue	<= color(5 downto 4);
			else
				red		<= (others=>'0');
				green	<= (others=>'0');
				blue	<= (others=>'0');
			end if;
		end if;
	end process;

end Behavioral;
