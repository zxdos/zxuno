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
		dither:			in  std_logic;
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
	signal screen_n:	std_logic_vector (1 downto 0) := (others=>'0');
	
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
	
	x				<= hcount-(91+75);
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
			if vcount=0 and hcount=0 then
				case screen_n is
				when "00"	=> screen_n <= "01";
				when "01"	=> screen_n <= "11";
				when "11"	=> screen_n <= "10";
				when others	=> screen_n <= "00";
				end case;
			end if;
		end if;
	end process;
	
	process (clk16)
		variable pixel_n: std_logic_vector(1 downto 0);
	begin
		if rising_edge(clk16) then
			if visible then
				if dither='1' then
					pixel_n := std_logic_vector(hcount(0 downto 0))&std_logic_vector(vcount(0 downto 0));
					pixel_n(0) := pixel_n(0) xor screen_n(0);
					pixel_n(1) := pixel_n(1) xor screen_n(1);
					case pixel_n is
					when "00" =>
						red(1)	<= color(0);
						green(1)	<= color(2);
						blue(1)	<= color(4);
					when "01" | "10" =>
						red(1)	<= color(1);
						green(1)	<= color(3);
						blue(1)	<= color(5);
					when others =>
						red(1)	<= color(0) and color(1);
						green(1)	<= color(2) and color(3);
						blue(1)	<= color(4) and color(5);
					end case;
					red(0)	<= '0';
					green(0)	<= '0';
					blue(0)	<= '0';
				else
					red	<= color(1 downto 0);
					green	<= color(3 downto 2);
					blue	<= color(5 downto 4);
				end if;
			else
				red	<= (others=>'0');
				green	<= (others=>'0');
				blue	<= (others=>'0');
			end if;
		end if;
	end process;

end Behavioral;

