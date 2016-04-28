library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sms_tv is
	port (
		clk:		in  STD_LOGIC;
		
		ram_cs_n:	out	STD_LOGIC;
		ram_we_n:	out	STD_LOGIC;
		ram_oe_n:	out	STD_LOGIC;
		ram_ble_n:	out	STD_LOGIC;
		ram_bhe_n:	out	STD_LOGIC;
		ram_a:		out	STD_LOGIC_VECTOR(18 downto 0);
		ram_d:		inout	STD_LOGIC_VECTOR(15 downto 0);

		j1_gnd:		out	STD_LOGIC;
		j1_up:		in		STD_LOGIC;
		j1_down:		in		STD_LOGIC;
		j1_left:		in		STD_LOGIC;
		j1_right:	in		STD_LOGIC;
		j1_tl:		in		STD_LOGIC;
		j1_tr:		inout	STD_LOGIC;
		
		tv_gnd:		out	STD_LOGIC;
		video:		out	STD_LOGIC_VECTOR (6 downto 1);
		audio:		out	STD_LOGIC;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	out	STD_LOGIC;

		tx:			out	STD_LOGIC);
end sms_tv;

architecture Behavioral of sms_tv is

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
		
		ram_cs_n:	out	STD_LOGIC;
		ram_we_n:	out	STD_LOGIC;
		ram_oe_n:	out	STD_LOGIC;
		ram_ble_n:	out	STD_LOGIC;
		ram_bhe_n:	out	STD_LOGIC;
		ram_a:		out	STD_LOGIC_VECTOR(18 downto 0);
		ram_d:		inout	STD_LOGIC_VECTOR(15 downto 0);

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

		x:				in		UNSIGNED(8 downto 0);
		y:				in		UNSIGNED(7 downto 0);
		vblank:		in		STD_LOGIC;
		hblank:		in		STD_LOGIC;
		color:		out	STD_LOGIC_VECTOR(5 downto 0);
		audio:		out	STD_LOGIC;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	out	STD_LOGIC;

		tx:			out	STD_LOGIC);
	end component;

	component tv_video is
	Port (
		clk8:				in  STD_LOGIC;
		clk64:			in  STD_LOGIC;
		x:					out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		vblank:			out STD_LOGIC;
		hblank:			out STD_LOGIC;
		color:			in  STD_LOGIC_VECTOR(5 downto 0);
		video:	out  STD_LOGIC_VECTOR (6 downto 1));
	end component;
	
	signal clk_cpu:			std_logic;
	signal clk64:				std_logic;
	
	signal x:					unsigned(8 downto 0);
	signal y:					unsigned(7 downto 0);
	signal vblank:				std_logic;
	signal hblank:				std_logic;
	signal color:				std_logic_vector(5 downto 0);
	
	signal j2_tr:				std_logic;

begin

	clock_inst: clock
	port map (
		clk_in		=> clk,
		clk_cpu		=> clk_cpu,
		clk16			=> open,
		clk32			=> open,
		clk64			=> clk64);


	video_inst: tv_video
	port map (
		clk8				=> clk_cpu,
		clk64				=> clk64,
		x					=> x,
		y					=> y,
		vblank			=> open,
		hblank			=> open,
		color				=> color,
		video				=> video);

	system_inst: system
	port map (
		clk_cpu		=> clk_cpu,
		clk_vdp		=> clk_cpu,
		
		ram_cs_n		=> ram_cs_n,
		ram_we_n		=> ram_we_n,
		ram_oe_n		=> ram_oe_n,
		ram_ble_n	=> ram_ble_n,
		ram_bhe_n	=> ram_bhe_n,
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

		x				=> x,
		y				=> y,
		vblank		=> vblank,
		hblank		=> hblank,
		color			=> color,
		audio			=> audio,

		spi_do		=> spi_do,
		spi_sclk		=> spi_sclk,
		spi_di		=> spi_di,
		spi_cs_n		=> spi_cs_n,

		tx				=> tx);
		
	j1_gnd <= '0';
	tv_gnd <= '0';
		
end Behavioral;

