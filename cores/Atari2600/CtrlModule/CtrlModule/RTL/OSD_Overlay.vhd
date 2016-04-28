library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity OSD_Overlay is
port (
	clk : in std_logic;
	red_in : in std_logic_vector(7 downto 0);
	green_in : in std_logic_vector(7 downto 0);
	blue_in : in std_logic_vector(7 downto 0);
	window_in : in std_logic;
	hsync_in : in std_logic;
	osd_window_in : in std_logic;
	osd_pixel_in : in std_logic;
	red_out : out std_logic_vector(7 downto 0);
	green_out : out std_logic_vector(7 downto 0);
	blue_out : out std_logic_vector(7 downto 0);
	window_out : out std_logic;
	scanline_ena : in std_logic
);
end entity;

architecture RTL of OSD_Overlay is
	signal hsync_r : std_logic;
	signal scanline : std_logic :='0';
begin

	process(clk)
	begin
		if rising_edge(clk) then
			hsync_r<=hsync_in;
			if hsync_r='0' and hsync_in='1' then
				scanline<=not scanline;
			end if;
		end if;
	end process;

	process(clk, window_in, osd_window_in, osd_pixel_in,red_in, green_in, blue_in, scanline, scanline_ena)
	begin
	
--		if rising_edge(clk) then
			window_out<=window_in;
			
			if osd_window_in='1' then
				red_out<=osd_pixel_in&osd_pixel_in&red_in(7 downto 2);
				green_out<=osd_pixel_in&osd_pixel_in&green_in(7 downto 2);
				blue_out<=osd_pixel_in&'1'&blue_in(7 downto 2);
			elsif scanline='1' and scanline_ena='1' then
				red_out<='0'&red_in(7 downto 1);
				green_out<='0'&green_in(7 downto 1);
				blue_out<='0'&blue_in(7 downto 1);
			else
				red_out<=red_in;
				green_out<=green_in;
				blue_out<=blue_in;
			end if;
			
--		end if;
	
	end process;

end architecture;
