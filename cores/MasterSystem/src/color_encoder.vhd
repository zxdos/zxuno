library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- clk must be a 64Mhz clock
-- sync is the sync signal (0 for 0V, 1 for 0.3V)
-- line_visible is 1 for lines that are displayed (only sync when 0)
-- line_even should be toggled every line
-- color: 222 RGB (b1b0g1g0r1r0)
-- output: 6 bit linear output, "000000" is 0v, "111111" is 1.3V (step is 0.02V)
entity color_encoder is
	Port (
		clk:				in  STD_LOGIC;
		pal:				in  STD_LOGIC;
		sync:				in  STD_LOGIC;
		line_visible:	in  STD_LOGIC;
		line_even:		in  STD_LOGIC;
		color:			in  STD_LOGIC_VECTOR (5 downto 0);
		output:			out STD_LOGIC_VECTOR (5 downto 0));
end color_encoder;

architecture Behavioral of color_encoder is

	component yuv_table
	port (color	: in  std_logic_vector(5 downto 0);
			y		: out std_logic_vector(5 downto 0);
			u		: out std_logic_vector(5 downto 0);
			v		: out std_logic_vector(5 downto 0));
	end component;

	signal counter	: integer range 0 to 4096;
	signal phase	: unsigned (20 downto 0) := (others=>'0');

	signal y1: std_logic_vector (5 downto 0);
	signal u1: std_logic_vector (5 downto 0);
	signal v1: std_logic_vector (5 downto 0);
	signal y	: unsigned (5 downto 0);
	signal u	: unsigned (5 downto 0);
	signal v	: unsigned (5 downto 0);
	
	signal uv		: unsigned (5 downto 0);
	
begin
	yuv_table_inst : yuv_table
	port map (
		color => color,
		y		=> y1,
		u		=> u1,
		v		=> v1);
		
	process (clk, sync, line_visible)
	begin
		if rising_edge(clk) then
			if sync='0' then
				counter <= 0;
				--phase <= (others=>'0');
			else
				if line_visible='1' then
					counter <= counter+1;
				end if;
			end if;
			if pal='1' then
				phase <= phase+145281;
			else
				phase <= phase+117295;
			end if;
		end if;
	end process;
	
	process (clk,counter,color)
		--variable yuv : unsigned(17 downto 0);
	begin
		if rising_edge(clk) then
			-- color burst
			if counter>=2*29 and counter<2*(29+72) then
				-- black
				y	<= "000000";
				-- reference phase
				if pal='1' then
					u	<= "111100";
					v	<= "000100";
				else
					u	<= "111000";
					v	<= "000000";
				end if;
				
			-- visible pixels
			elsif counter>=2*(29+72+85) and counter<2*(29+72+85+1664) then
				--yuv := yuv_table(to_integer(unsigned(color)));
				y	<= unsigned(y1);
				u	<= unsigned(u1);
				v	<= unsigned(v1);
				
			-- front porch, sync and back porch
			else
				y	<= (others=>'0');
				u	<= (others=>'0');
				v	<= (others=>'0');
			end if;
		end if;
	end process;

	process (phase, line_even, u, v)
	begin
		if pal='1' then
			case line_even&phase(20 downto 19) is
			when "000"	=> uv <= u;
			when "001"	=> uv <= v;
			when "010"	=> uv <= 0-u;
			when "011"	=> uv <= 0-v;
			when "100"	=> uv <= u;
			when "101"	=> uv <= 0-v;
			when "110"	=> uv <= 0-u;
			when "111"	=> uv <= v;
			when others	=> uv <= (others=>'0');
			end case;
		else
			case phase(20 downto 19) is
			when "00"	=> uv <= u;
			when "01"	=> uv <= 0-v;
			when "10"	=> uv <= 0-u;
			when "11"	=> uv <= v;
			when others	=> uv <= (others=>'0');
			end case;
		end if;
	end process;
	
	process (clk,sync,y,uv)
	begin
		if rising_edge(clk) then
			output <= std_logic_vector(("0"&sync&"0000")+y+uv);
		end if;
	end process;
	
end Behavioral;

