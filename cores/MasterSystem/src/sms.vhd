library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity sms is
	port (
		clk:			in			STD_LOGIC;
		
		sram_we_n:	out		STD_LOGIC;
		sram_a:		out		STD_LOGIC_VECTOR(20 downto 0);
		ram_d:		inout		STD_LOGIC_VECTOR(7 downto 0); --Q

		j1_up:		in			STD_LOGIC;
		j1_down:		in			STD_LOGIC;
		j1_left:		in			STD_LOGIC;
		j1_right:	in			STD_LOGIC;
		j1_tl:		in			STD_LOGIC;
		j1_tr:		inout		STD_LOGIC;
		j1_fire3:	out		STD_LOGIC;
		
		j2_up:		in			STD_LOGIC;
		j2_down:		in			STD_LOGIC;
		j2_left:		in			STD_LOGIC;
		j2_right:	in			STD_LOGIC;
		j2_tl:		in			STD_LOGIC;
		j2_tr:		inout		STD_LOGIC;	

		SW1:			in			STD_LOGIC;
		SW2:			in			STD_LOGIC;		

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
		
      NTSC: 		out   	std_logic; 
      PAL: 			out   	std_logic	

--	   ;hdmi_out_p: out   	std_logic_vector(3 downto 0);
--	   hdmi_out_n: out   	std_logic_vector(3 downto 0)	
		);
end sms;

architecture Behavioral of sms is

-- Cambiar segun tipo de placa/opción joysticks
-- JoyType: 0 = un Joy. 1 = dos Joys
constant JoyType : integer := 1; 

	signal clk_cpu:		std_logic;
	signal clk16:			std_logic;
	signal clk8:			std_logic;
	signal clk32:			std_logic;
	signal cpu_pclock:	std_logic;
	
	signal sel_pclock:	std_logic;
	signal sel_cpu:	std_logic;
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
	signal scanL:			std_logic;
	signal vfreQ:			std_logic;
	
	signal poweron_reset:	unsigned(7 downto 0) := "00000000";
	signal scandoubler_ctrl: std_logic_vector(1 downto 0);
	signal ram_we_n: std_logic;
	signal ram_a:	std_logic_vector(19 downto 0);
	
	signal joy1:  std_logic_vector(5 downto 0);
	signal joy2:  std_logic_vector(5 downto 0);
	signal joy_mux:  std_logic_vector(16 downto 0);
	signal j1_f3: std_logic;
	signal ePause: std_logic;
	signal eReset: std_logic;
	
	signal pwon: std_logic;
	
begin

	clock_inst: entity work.clock
	port map (
		clk_in		=> clk,
		sel_pclock  => sel_pclock,
		sel_cpu  	=> sel_cpu,
		clk8			=> clk8,
		clk16			=> clk16,
		clk_cpu		=> clk32,		
		pclock		=> rgb_clk,
		cpu_pclock		=> cpu_pclock
		);
		
	video_inst: entity work.rgb_video
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
		blue			=> rgb_blue, 
		vfreq			=> vfreQ
	);
	
	video_vga_inst: entity work.vga_video --vga
	port map (
		clk16			=> clk16, 
		x	 			=> vga_x,
		y				=> vga_y,
--		vblank		=> vga_vblank,
--		hblank		=> vga_hblank,
		color			=> color,		
		hsync			=> vga_hsync,
		vsync			=> vga_vsync,
		red			=> vga_red, 
		green			=> vga_green, 
		blue			=> vga_blue, 
		blank			=> blank,
		scanlines	=> scandoubler_ctrl(1) xor scanL,
		vfreq			=> vfreQ
	);	


JT1 : if (JoyType = 1) generate	
	j1_fire3 <= j1_f3;

	process (j1_f3)
	begin		
			if j1_f3 = '0' then
				joy2 <= j1_up & j1_down & j1_left & j1_right & j1_tl & j1_tr;
			else
				joy1 <= j1_up & j1_down & j1_left & j1_right & j1_tl & j1_tr;
			end if;	
	end process;
	
	process (clk32)
	begin
		if rising_edge(clk32) then			
			j1_f3 <= joy_mux(16);
			joy_mux <= joy_mux + 1;
		end if;
	end process;	

	ePause <= '1';
	eReset <= '1';
	
end generate JT1;
	

JT0 : if (JoyType = 0) generate	
	joy1 <= j1_up & j1_down & j1_left & j1_right & j1_tl & j1_tr;
	joy2 <= j1_up & j1_down & j1_left & j1_right & j1_tl & j1_tr;
	ePause <= '1';
	eReset <= '1';	
	j1_fire3 <= '0';		
end generate JT0;			

		
	system_inst: entity work.system
	port map (
		clk_cpu		=> cpu_pclock,	--cpu_pclock, --clk_cpu
		clk_vdp		=> rgb_clk,	--rgb_clk, --clk8 = rgb  --clk16 = vga
		clk32			=> clk32,
		
		ram_we_n		=> ram_we_n,
		ram_a			=> ram_a,
		ram_d			=> ram_d,

		j1_up			=> joy1(5), --j1_up,
		j1_down		=> joy1(4), --j1_down,
		j1_left		=> joy1(3), --j1_left,
		j1_right		=> joy1(2), --j1_right,
		j1_tl			=> joy1(1), --j1_tl,
		j1_tr			=> joy1(0), --j1_tr,
		j2_up			=> joy2(5), --'1',
		j2_down		=> joy2(4), --'1',
		j2_left		=> joy2(3), --'1',
		j2_right		=> joy2(2), --'1',
		j2_tl			=> joy2(1), --'1',
		j2_tr			=> joy2(0), --j2_tr,
		reset			=> eReset,
		pause			=> ePause,

		x				=> x,
		y				=> y,
--		vblank		=> vblank,
--		hblank		=> hblank,
		color			=> color,
		audio			=> audio,
		
		ps2_clk		=> ps2_clk,
		ps2_data		=> ps2_data,
		
		scanSW		=> scanSWk,
		scanL			=> scanL,
		vfreQ			=> vfreQ,

		spi_do		=> spi_do,
		spi_sclk		=> spi_sclk,
		spi_di		=> spi_di,
		spi_cs_n		=> spi_cs_n,
		sel_cpu		=> sel_cpu
		);
		
	led <= not spi_cs_n; --Q
--	led <= scandoubler_ctrl(0); --debug scandblctrl reg.

	audio_l <= audio;
	audio_r <= audio;
	
	NTSC <= vfreQ;
	PAL <= not vfreQ;	
	
	---- scandlbctrl register detection for video mode initialization at start ----
	
	process (clk32)
	begin
		if rising_edge(clk32) then
        if (poweron_reset < 90) then
            scandoubler_ctrl <= ram_d(1 downto 0);
		  end if;
		  if poweron_reset < 254 then
				poweron_reset <= poweron_reset + 1;
		  end if;
		end if;
	end process;
	
	sram_a(20) <= '0';
	sram_a(19 downto 0) <= "00001000111111010101" when poweron_reset < 254 else ram_a; --0x8FD5 SRAM (SCANDBLCTRL REG)
	sram_we_n <= '1' when poweron_reset < 254 else ram_we_n;
	pwon <= '1' when poweron_reset < 254 else '0';
	
	-------------------------------------------------------------------------------
	
	vsync <= vga_vsync when scanSW='1'	else '1';
	hsync <= vga_hsync when scanSW='1' 	else rgb_hsync;
	red 	<= vga_red   when scanSW='1' 	else rgb_red;
	green <= vga_green when scanSW='1' 	else rgb_green;
	blue 	<= vga_blue  when scanSW='1' 	else rgb_blue;
	
--	vblank <= vga_vblank when scanSW='1' else rgb_vblank;
--	hblank <= vga_hblank when scanSW='1' else rgb_hblank;

	x <= vga_x when scanSW='1'	else rgb_x;
	y <= vga_y when scanSW='1'	else rgb_y;	
	
	sel_pclock <= '1' when scanSW='1' else '0';
	
--	scanSW <= '1' when scanSWk = '1' else '0';
	scanSW <= scandoubler_ctrl(0) xor scanSWk; -- Video mode change via ScrollLock / SCANDBLCTRL reg.


--HDMI

--Inst_MinimalDVID_encoder: entity work.MinimalDVID_encoder PORT MAP(
--      clk    => clk32,
--      blank  => blank,
--      hsync  => hsync,
--      vsync  => vsync,
--      red    => red,
--      green  => green,
--      blue   => blue,
--      hdmi_p => hdmi_out_p,
--      hdmi_n => hdmi_out_n
--   );
      		
	
end Behavioral;
