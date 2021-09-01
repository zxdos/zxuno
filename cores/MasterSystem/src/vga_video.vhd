library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_video is
	port (
		clk16:			in  std_logic;
		x: 				out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		vblank:			buffer std_logic;
		hblank:			buffer std_logic;
		color:			in  std_logic_vector(5 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		red:				out std_logic_vector(2 downto 0);
		green:			out std_logic_vector(2 downto 0);
		blue:				out std_logic_vector(2 downto 0);
		blank:			out std_logic;
		scanlines:		in	 std_logic;
		vfreq:			in	 std_logic
		);
end vga_video;

architecture Behavioral of vga_video is

	signal hcount:		unsigned (8 downto 0) := (others=>'0');
	signal vcount:		unsigned (9 downto 0) := (others=>'0');
	signal visible:	boolean;
	
	signal y9:			unsigned (8 downto 0);
	
	signal hcount_max: integer range 0 to 1023;
	signal vcount_max: integer range 0 to 1023;
	signal ypos:		 integer range 0 to 64;
	
begin

	hcount_max <= 511 when vfreq = '0' else 507;
	vcount_max <= 622 when vfreq = '0' else 522;
	ypos <= 55 when vfreq = '0' else 27;
	
	process (clk16)
	begin
		if rising_edge(clk16) then
			if hcount=hcount_max then --507 = 60Hz , 511 = 50Hz
				hcount <= (others => '0');
				if vcount=vcount_max then --523 = 60Hz, 623 = 50Hz --622
					vcount <= (others=>'0');
				else
					vcount <= vcount + 1;
				end if;
			else
				hcount <= hcount + 1;
			end if;
		end if;
	end process;
	
	x				<= hcount-(91+60); --62
--	y9				<= vcount(9 downto 1)-(13+27); --60Hz
--	y9				<= vcount(9 downto 1)-(13+55); --50Hz
	y9				<= vcount(9 downto 1)-(13+ypos); --var
	y				<= y9(7 downto 0);
	hblank		<= '1' when hcount=0 and vcount(0 downto 0)=0 else '0';
	vblank		<= '1' when hcount=0 and vcount=0 else '0';
	
	hsync			<= '0' when hcount<61 else '1';
	vsync			<= '0' when vcount<2 else '1';
	
--	visible		<= vcount>=35 and vcount<35+480 and hcount>=91 and hcount<91+406; --60Hz
--	visible		<= vcount>=35 and vcount<35+580 and hcount>=91 and hcount<91+406; --50Hz	
	visible		<= vcount>=35 and vcount<35+vcount_max-42 and hcount>=91 and hcount<91+406; --var	
	
	
	process (clk16)
	begin
		if rising_edge(clk16) then
			if visible then
			   if scanlines = '1' then --scanlines
					if (vcount mod 2) = 0 then
						red	<= '0' & color(1 downto 0);  
						green	<= '0' & color(3 downto 2);  
						blue	<= '0' & color(5 downto 4); 
					else									
						red	<= color(1 downto 0) & color(0);  
						green	<= color(3 downto 2) & color(2);  
						blue	<= color(5 downto 4) & color(4);  
					end if;
				else
					red	<= color(1 downto 0) & color(0);  
					green	<= color(3 downto 2) & color(2);  
					blue	<= color(5 downto 4) & color(4);   
				end if;
				
				blank <= '0';
			else
				red	<= (others=>'0');
				green	<= (others=>'0');
				blue	<= (others=>'0');
				
				blank <= '1';
			end if;
		end if;
		
	end process;

end Behavioral;
