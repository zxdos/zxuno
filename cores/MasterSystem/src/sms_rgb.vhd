library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sms_rgb is
	port (
		clk:			in		STD_LOGIC;
		
		ram_we_n:	out	STD_LOGIC;
		ram_a:		out	STD_LOGIC_VECTOR(18 downto 0);
		ram_d:		inout	STD_LOGIC_VECTOR(7 downto 0); --Q

--		j1_MDsel:	out	STD_LOGIC; --Q
		j1_up:		in		STD_LOGIC;
		j1_down:		in		STD_LOGIC;
		j1_left:		in		STD_LOGIC;
		j1_right:	in		STD_LOGIC;
		j1_tl:		in		STD_LOGIC;
		j1_tr:		inout	STD_LOGIC;

		audio_l:		out	STD_LOGIC;
		audio_r:		out	STD_LOGIC;
		
		red:			out	STD_LOGIC_VECTOR(2 downto 0); --Q
		green:		out	STD_LOGIC_VECTOR(2 downto 0); --Q
		blue:			out	STD_LOGIC_VECTOR(2 downto 0); --Q
		hsync:		out	STD_LOGIC;
		vsync:		out	STD_LOGIC;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	buffer	STD_LOGIC; --Q

		led:			out	STD_LOGIC; --Q
		
      NTSC              : out   std_logic; --Q
      PAL               : out   std_logic --Q		
		);
end sms_rgb;

architecture Behavioral of sms_rgb is

	component clock is
   port (
		clk_in:		in  std_logic;
		clk_cpu:		out std_logic;
		clk16:		out std_logic;
		clk32:		out std_logic;
		clk64:		out std_logic);
	end component;

	component system is
	port (
		clk_cpu:		in		STD_LOGIC;
		clk_vdp:		in		STD_LOGIC;
		
		ram_we_n:	out	STD_LOGIC;
		ram_a:		out	STD_LOGIC_VECTOR(18 downto 0);
		ram_d:		inout	STD_LOGIC_VECTOR(7 downto 0);

		j1_up:		in		STD_LOGIC;
		j1_down:		in		STD_LOGIC;
		j1_left:		in		STD_LOGIC;
		j1_right:	in		STD_LOGIC;
		j1_tl:		in		STD_LOGIC;
		j1_tr:		inout	STD_LOGIC;
		j2_up:		in		STD_LOGIC;
		j2_down:		in		STD_LOGIC;
		j2_left:		in		STD_LOGIC;
		j2_right:	in		STD_LOGIC;
		j2_tl:		in		STD_LOGIC;
		j2_tr:		inout	STD_LOGIC;
		reset:		in		STD_LOGIC;
		pause:		in		STD_LOGIC;

		x:				in		UNSIGNED(8 downto 0);
		y:				in		UNSIGNED(7 downto 0);
		vblank:		in		STD_LOGIC;
		hblank:		in		STD_LOGIC;
		color:		out	STD_LOGIC_VECTOR(5 downto 0);
		audio:		out	STD_LOGIC;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	out	STD_LOGIC
);
	end component;
	
	component rgb_video is
	port (
		clk16:			in  std_logic;
		clk8:				in  std_logic; --Q
		x: 				out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		vblank:			out std_logic;
		hblank:			out std_logic;
		color:			in  std_logic_vector(5 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		red:				out std_logic_vector(1 downto 0);
		green:			out std_logic_vector(1 downto 0);
		blue:				out std_logic_vector(1 downto 0)
);
	end component;
	
	signal clk_cpu:			std_logic;
	signal clk16:				std_logic;
	signal clk8:				std_logic;
	
	signal x:					unsigned(8 downto 0);
	signal y:					unsigned(7 downto 0);
	signal vblank:				std_logic;
	signal hblank:				std_logic;
	signal color:				std_logic_vector(5 downto 0);
	signal audio:				std_logic;
	
	signal j2_tr:				std_logic;
	
begin

	clock_inst: clock
	port map (
		clk_in		=> clk,
		clk_cpu		=> clk_cpu,
		clk16			=> clk16,
		clk32			=> clk8, --clk32 => open
		clk64			=> open);
		
	video_inst: rgb_video
	port map (
		clk16			=> clk16, 
		clk8			=> clk8, --Q
		x	 			=> x,
		y				=> y,
		vblank		=> vblank,
		hblank		=> hblank,
		color			=> color,		
		hsync			=> hsync,
		vsync			=> vsync,
		red			=> red(2 downto 1), --Q
		green			=> green(2 downto 1), --Q
		blue			=> blue(2 downto 1) --Q
	);
	
	red(0) <= '0'; --Q
	green(0) <= '0'; --Q
	blue(0) <= '0'; --Q

	system_inst: system
	port map (
		clk_cpu		=> clk_cpu, --clk_cpu
		clk_vdp		=> clk8,	--clk16
		
		ram_we_n		=> ram_we_n,
		ram_a			=> ram_a,
		ram_d			=> ram_d,

		j1_up			=> j1_up,
		j1_down		=> j1_down,
		j1_left		=> j1_left,
		j1_right		=> j1_right,
		j1_tl			=> j1_tl,
		j1_tr			=> j1_tr,
		j2_up			=> '1',
		j2_down		=> '1',
		j2_left		=> '1',
		j2_right		=> '1',
		j2_tl			=> '1',
		j2_tr			=> j2_tr,
		reset			=> '1',
		pause			=> '1',

		x				=> x,
		y				=> y,
		vblank		=> vblank,
		hblank		=> hblank,
		color			=> color,
		audio			=> audio,

		spi_do		=> spi_do,
		spi_sclk		=> spi_sclk,
		spi_di		=> spi_di,
		spi_cs_n		=> spi_cs_n
		);
	
	led <= not spi_cs_n; --Q

	audio_l <= audio;
	audio_r <= audio;
	
	NTSC <= '0';
	PAL <= '1';	
	
end Behavioral;
