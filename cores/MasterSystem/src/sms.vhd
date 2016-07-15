library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sms is
	port (
		clk:			in			STD_LOGIC;
		
		sram_we_n:	out		STD_LOGIC;
		sram_a:		out		STD_LOGIC_VECTOR(18 downto 0);
		ram_d:		inout		STD_LOGIC_VECTOR(7 downto 0); --Q

--		j1_MDsel:	out		STD_LOGIC; --Q
		j1_up:		in			STD_LOGIC;
		j1_down:		in			STD_LOGIC;
		j1_left:		in			STD_LOGIC;
		j1_right:	in			STD_LOGIC;
		j1_tl:		in			STD_LOGIC;
		j1_tr:		inout		STD_LOGIC;

		audio_l:		out		STD_LOGIC;
		audio_r:		out		STD_LOGIC;
		
		red:			buffer	STD_LOGIC_VECTOR(2 downto 0);
		green:		buffer	STD_LOGIC_VECTOR(2 downto 0); 
		blue:			buffer	STD_LOGIC_VECTOR(2 downto 0);
		hsync:		buffer	STD_LOGIC;
		vsync:		buffer	STD_LOGIC;

		spi_do:		in			STD_LOGIC;
		spi_sclk:	out		STD_LOGIC;
		spi_di:		out		STD_LOGIC;
		spi_cs_n:	buffer	STD_LOGIC; 

		led:			out		STD_LOGIC; 
		
      ps2_clk: 	in    	std_logic;
      ps2_data:	in    	std_logic;		
		
      NTSC: 		out   	std_logic; --Q
      PAL: 			out   	std_logic; --Q	

	   hdmi_out_p: out   	std_logic_vector(3 downto 0);
	   hdmi_out_n: out   	std_logic_vector(3 downto 0)	
		);
end sms;

architecture Behavioral of sms is

	component clock is
   port (
		clk_in:		in  std_logic;
		sel_pclock: in  std_logic;
		clk_cpu:		out std_logic;
		clk16:		out std_logic;
		clk8:			out std_logic;
		clk32:		out std_logic;
		pclock:		out std_logic);
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
--		pause:		in		STD_LOGIC;

		x:				in		UNSIGNED(8 downto 0);
		y:				in		UNSIGNED(7 downto 0);
--		vblank:		in		STD_LOGIC;
--		hblank:		in		STD_LOGIC;
		color:		out	STD_LOGIC_VECTOR(5 downto 0);
		audio:		out	STD_LOGIC;
		
      ps2_clk: 	in    std_logic;
      ps2_data: 	in    std_logic;	

		scanSW:		out	std_logic;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	buffer	STD_LOGIC
);
	end component;
	
	component rgb_video is
	port (
		clk16:		in  	std_logic;
		clk8:			in  	std_logic; --Q
		x: 			out 	unsigned(8 downto 0);
		y:				out 	unsigned(7 downto 0);
		vblank:		out 	std_logic;
		hblank:		out 	std_logic;
		color:		in  	std_logic_vector(5 downto 0);
		hsync:		out 	std_logic;
		vsync:		out 	std_logic;
		red:			out 	std_logic_vector(2 downto 0);
		green:		out 	std_logic_vector(2 downto 0);
		blue:			out 	std_logic_vector(2 downto 0)
--		; blank:		out 	std_logic
);
	end component;
	
  COMPONENT MinimalDVID_encoder
   PORT(
      clk: 			IN 	std_logic;
      blank: 		IN 	std_logic;
      hsync: 		IN 	std_logic;
      vsync: 		IN 	std_logic;
      red: 			IN 	std_logic_vector(2 downto 0);
      green: 		IN 	std_logic_vector(2 downto 0);
      blue: 		IN 	std_logic_vector(2 downto 0);          
      hdmi_p: 		OUT 	std_logic_vector(3 downto 0);
      hdmi_n: 		OUT 	std_logic_vector(3 downto 0)
      );
   END COMPONENT;
	
	signal clk_cpu:		std_logic;
	signal clk16:			std_logic;
	signal clk8:			std_logic;
	signal clk32:			std_logic;
	
	signal sel_pclock:	std_logic;
	signal blank:			std_logic;
--	signal blankr:			std_logic;
	
	signal x:				unsigned(8 downto 0);
	signal y:				unsigned(7 downto 0);
	signal vblank:			std_logic;
	signal hblank:			std_logic;
	signal color:			std_logic_vector(5 downto 0);
	signal audio:			std_logic;
	
	signal vga_hsync:		std_logic;
	signal vga_vsync:		std_logic;
	signal vga_red:		std_logic_vector(2 downto 0);
	signal vga_green:		std_logic_vector(2 downto 0);
	signal vga_blue:		std_logic_vector(2 downto 0);
	signal vga_x:			unsigned(8 downto 0);
	signal vga_y:			unsigned(7 downto 0);
	signal vga_vblank:	std_logic;
	signal vga_hblank:	std_logic;
	
	signal rgb_hsync:		std_logic;
	signal rgb_vsync:		std_logic;
	signal rgb_red:		std_logic_vector(2 downto 0);
	signal rgb_green:		std_logic_vector(2 downto 0);
	signal rgb_blue:		std_logic_vector(2 downto 0);
	signal rgb_x:			unsigned(8 downto 0);
	signal rgb_y:			unsigned(7 downto 0);
	signal rgb_vblank:	std_logic;
	signal rgb_hblank:	std_logic;	
	
	signal rgb_clk:		std_logic;
	
	signal scanSWk:		std_logic;
	signal scanSW:			std_logic;
	
	signal j2_tr:			std_logic;
	
	signal c0, c1, c2 : 	std_logic_vector(9 downto 0);	--hdmi
	
	signal poweron_reset:	unsigned(7 downto 0) := "00000000";
	signal scandoubler_ctrl: std_logic_vector(1 downto 0);
	signal ram_we_n: std_logic;
	signal ram_a:	std_logic_vector(18 downto 0);
	
begin

	clock_inst: clock
	port map (
		clk_in		=> clk,
		sel_pclock  => sel_pclock,
		clk_cpu		=> clk_cpu,
		clk16			=> clk16,
		clk8			=> clk8, --clk32 => open
		clk32			=> clk32,
		pclock		=> rgb_clk);
		
	video_inst: rgb_video
	port map (
		clk16			=> clk16, 
		clk8			=> clk8, --Q
		x	 			=> rgb_x,
		y				=> rgb_y,
		vblank		=> rgb_vblank,
		hblank		=> rgb_hblank,
		color			=> color,		
		hsync			=> rgb_hsync,
		vsync			=> rgb_vsync,
		red			=> rgb_red, 
		green			=> rgb_green, 
		blue			=> rgb_blue 
--		,blank		=> blankr
	);
	
	video_vga_inst: entity work.vga_video --vga
	port map (
		clk16			=> clk16, 
		x	 			=> vga_x,
		y				=> vga_y,
		vblank		=> vga_vblank,
		hblank		=> vga_hblank,
		color			=> color,		
		hsync			=> vga_hsync,
		vsync			=> vga_vsync,
		red			=> vga_red, 
		green			=> vga_green, 
		blue			=> vga_blue, 
		blank			=> blank
	);	
		
	system_inst: system
	port map (
		clk_cpu		=> clk_cpu, --clk_cpu
		clk_vdp		=> rgb_clk,	--clk8 = rgb  --clk16 = vga
		
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
--		pause			=> '1',

		x				=> x,
		y				=> y,
--		vblank		=> vblank,
--		hblank		=> hblank,
		color			=> color,
		audio			=> audio,
		
		ps2_clk		=> ps2_clk,
		ps2_data		=> ps2_data,
		
		scanSW		=> scanSWk,

		spi_do		=> spi_do,
		spi_sclk		=> spi_sclk,
		spi_di		=> spi_di,
		spi_cs_n		=> spi_cs_n
		);
	
	led <= not spi_cs_n; --Q
--	led <= scandoubler_ctrl(0); --debug scandblctrl reg.

	audio_l <= audio;
	audio_r <= audio;
	
	NTSC <= '0';
	PAL <= '1';	
	
	---- scandlbctrl register detection for video mode initialization at start ----
	
	process (clk_cpu)
	begin
		if rising_edge(clk_cpu) then
        if (poweron_reset < 126) then
            scandoubler_ctrl <= ram_d(1 downto 0);
		  end if;
		  if poweron_reset < 254 then
				poweron_reset <= poweron_reset + 1;
		  end if;
		end if;
	end process;
	

	sram_a <= "0001000111111010101" when poweron_reset < 254 else ram_a; --0x8FD5 SRAM (SCANDBLCTRL REG)
	sram_we_n <= '1' when poweron_reset < 254 else ram_we_n;
	
	-------------------------------------------------------------------------------
	
	vsync <= vga_vsync when scanSW='1'	else '1';
	hsync <= vga_hsync when scanSW='1' 	else rgb_hsync;
	red 	<= vga_red when scanSW='1' 	  else rgb_red;
	green <= vga_green when scanSW='1' 	else rgb_green;
	blue 	<= vga_blue when scanSW='1' 	else rgb_blue;
	
--	vblank <= vga_vblank when scanSW='1' else rgb_vblank;
--	hblank <= vga_hblank when scanSW='1' else rgb_hblank;

	x <= vga_x when scanSW='1'	else rgb_x;
	y <= vga_y when scanSW='1'	else rgb_y;	
	
	sel_pclock <= '1' when scanSW='1' else '0';
	
--	scanSW <= '1' when scanSWk = '1' else '0';
	scanSW <= scandoubler_ctrl(0) xor scanSWk; -- Video mode change via ScrollLock / SCANDBLCTRL reg.


--HDMI

Inst_MinimalDVID_encoder: MinimalDVID_encoder PORT MAP(
      clk    => clk32,
      blank  => blank,
      hsync  => hsync,
      vsync  => vsync,
      red    => red,
      green  => green,
      blue   => blue,
      hdmi_p => hdmi_out_p,
      hdmi_n => hdmi_out_n
   );
      		
	
end Behavioral;
