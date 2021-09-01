library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.all;

entity system is
	port (
		clk_cpu:		in		STD_LOGIC;
		clk_vdp:		in		STD_LOGIC;
		clk32:		in		STD_LOGIC;
		
		ram_we_n:	out	STD_LOGIC;
		ram_a:		out	STD_LOGIC_VECTOR(19 downto 0);
		ram_d:		inout	STD_LOGIC_VECTOR(7 downto 0); --Q

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
--		vblank:		in		STD_LOGIC;
--		hblank:		in		STD_LOGIC;
		color:		out	STD_LOGIC_VECTOR(5 downto 0);
		audio:		out	STD_LOGIC;
		
      ps2_clk: 	in    std_logic;
      ps2_data: 	in    std_logic;	

		scanSW:		out	std_logic;
		scanL:		out	std_logic;
		vfreQ:		out	std_logic;

		spi_do:		in		STD_LOGIC;
		spi_sclk:	out	STD_LOGIC;
		spi_di:		out	STD_LOGIC;
		spi_cs_n:	buffer	STD_LOGIC;
		sel_cpu:		out	std_logic
	);
end system;

architecture Behavioral of system is

	
	component T80se is
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n:			in std_logic;
		CLK_n:			in std_logic;
		CLKEN:			in std_logic;
		WAIT_n:			in std_logic;
		INT_n:			in std_logic;
		NMI_n:			in std_logic;
		BUSRQ_n:			in std_logic;
		M1_n:				out std_logic;
		MREQ_n:			out std_logic;
		IORQ_n:			out std_logic;
		RD_n:				out std_logic;
		WR_n:				out std_logic;
		RFSH_n:			out std_logic;
		HALT_n:			out std_logic;
		BUSAK_n:			out std_logic;
		A:					out std_logic_vector(15 downto 0);
		DI:				in std_logic_vector(7 downto 0);
		DO:				out std_logic_vector(7 downto 0)
		
	;	RestorePC   : in std_logic_vector(15 downto 0); --Q
		RestoreINT  : in std_logic_vector(7 downto 0);	--Q
		RestorePC_n : in std_logic --Q
	);
	end component;

	component vdp is
	port (
		cpu_clk:			in  STD_LOGIC;
		vdp_clk:			in  STD_LOGIC;
		RD_n:				in  STD_LOGIC;
		WR_n:				in  STD_LOGIC;
		IRQ_n:			out STD_LOGIC;
		A:					in  STD_LOGIC_VECTOR(7 downto 0);
		D_in:				in  STD_LOGIC_VECTOR(7 downto 0);
		D_out:			out STD_LOGIC_VECTOR(7 downto 0);			
		x:					in  unsigned(8 downto 0);
		y:					in  unsigned(7 downto 0);
--		vblank:			in  std_logic;
--		hblank:			in  std_logic;
		RST_vram:		in std_logic;
		color: 			out std_logic_vector (5 downto 0));
	end component;
	
	component psg is
   port (
		clk:				in  STD_LOGIC;
		WR_n:				in  STD_LOGIC;
		D_in:				in  STD_LOGIC_VECTOR (7 downto 0);
		output:			out STD_LOGIC);
	end component;
	
	
	component io is
   port (
		clk:				in		STD_LOGIC;
		WR_n:				in		STD_LOGIC;
		RD_n:				in		STD_LOGIC;
		A:					in		STD_LOGIC_VECTOR (7 downto 0);
		D_in:				in		STD_LOGIC_VECTOR (7 downto 0);
		D_out:			out	STD_LOGIC_VECTOR (7 downto 0);
		J1_up:			in 	STD_LOGIC;
		J1_down:			in 	STD_LOGIC;
		J1_left:			in 	STD_LOGIC;
		J1_right:		in 	STD_LOGIC;
		J1_tl:			in 	STD_LOGIC;
		J1_tr:			inout STD_LOGIC;
		J2_up:			in 	STD_LOGIC;
		J2_down:			in 	STD_LOGIC;
		J2_left:			in 	STD_LOGIC;
		J2_right:		in 	STD_LOGIC;
		J2_tl:			in 	STD_LOGIC;
		J2_tr:			inout STD_LOGIC;
		RESET:			in 	STD_LOGIC);
	end component;

	component ram is
	port (
		clk:				in  STD_LOGIC;
		RD_n:				in  STD_LOGIC;
		WR_n:				in  STD_LOGIC;
		A:					in  STD_LOGIC_VECTOR(12 downto 0);
		D_in:				in  STD_LOGIC_VECTOR(7 downto 0);
		D_out:			out STD_LOGIC_VECTOR(7 downto 0));
	end component;

	component boot_rom is
	port (
		clk:				in  STD_LOGIC;
		RD_n:				in  STD_LOGIC;
		A:					in  STD_LOGIC_VECTOR(13 downto 0);
		D_out:			out STD_LOGIC_VECTOR(7 downto 0));
	end component;
	
	component spi is
	port (
		clk:				in  STD_LOGIC;
		RD_n:				in  STD_LOGIC;
		WR_n:				in  STD_LOGIC;
		A:					in  STD_LOGIC_VECTOR (7 downto 0);
		D_in:				in  STD_LOGIC_VECTOR (7 downto 0);
		D_out:			out STD_LOGIC_VECTOR (7 downto 0);
			
		cs_n:				out STD_LOGIC;
		sclk:				out STD_LOGIC;
		miso:				in  STD_LOGIC;
		mosi:				out STD_LOGIC);
	end component;
	
    component multiboot is
     port (
		clk_icap:				in  STD_LOGIC;
		REBOOT:				in  STD_LOGIC
		);
	end component;	

	signal RESET_n:			std_logic;
	signal resetKey:			std_logic;
	signal MRESET:				std_logic;
--	signal scanFlag:			unsigned := "0";
	
	-- controles
	signal p1_up:				STD_LOGIC; --0
	signal p1_down:			STD_LOGIC; --1
	signal p1_left:			STD_LOGIC; --2
	signal p1_right:		 	STD_LOGIC; --3
	signal p1_tl:			 	STD_LOGIC; --4
	signal p1_tr:				STD_LOGIC; --5
	signal ctrl_keys:			std_logic_vector(9 downto 0);
	signal Kpause:				std_logic := '1';
	
	signal p2_tr:				STD_LOGIC; 
	
	signal RD_n:				std_logic;
	signal WR_n:				std_logic;
	signal IRQ_n:				std_logic;
	signal IO_n:				std_logic;
	signal A:					std_logic_vector(15 downto 0);
	signal D_in:				std_logic_vector(7 downto 0);
	signal D_out:				std_logic_vector(7 downto 0);
	
	signal vdp_RD_n:			std_logic;
	signal vdp_WR_n:			std_logic;
	signal vdp_D_out:			std_logic_vector(7 downto 0);
	
	signal psg_WR_n:			std_logic;
	
	signal ctl_WR_n:			std_logic;
	
	signal io_RD_n:			std_logic;
	signal io_WR_n:			std_logic;
	signal io_D_out:			std_logic_vector(7 downto 0);
	
	signal ram_WR_n:			std_logic;
	signal ram_D_out:			std_logic_vector(7 downto 0);
	
	signal rom_WR_n:			std_logic;
	signal rom_D_out:			std_logic_vector(7 downto 0);
	
	signal spi_RD_n:			std_logic;
	signal spi_WR_n:			std_logic;
	signal spi_D_out:			std_logic_vector(7 downto 0);
	
	signal boot_rom_D_out:	std_logic_vector(7 downto 0);
	
	signal reset_counter:	unsigned(3 downto 0) := "1111";
	signal bootloader:		std_logic := '0';
	signal irom_D_out:		std_logic_vector(7 downto 0);
	signal irom_RD_n:			std_logic := '1';

	--reset vram
	signal RST_vram:			std_logic;

	signal bank0:				std_logic_vector(5 downto 0);
	signal bank1:				std_logic_vector(5 downto 0); 
	signal bank2:				std_logic_vector(5 downto 0); 
	
	signal downloading : std_logic:='0';
	
	signal A_TOP: integer:=18;
	signal B_TOP: integer:=4;
	
begin	
	
	z80_inst: T80se
	port map(

		RESET_n		=> RESET_n,
		CLK_n			=> clk_cpu,
		CLKEN			=> '1',
		WAIT_n		=> '1',
		INT_n			=> IRQ_n,
		NMI_n			=> Kpause,
		BUSRQ_n		=> '1',
		M1_n			=> open,
		MREQ_n		=> open,
		IORQ_n		=> IO_n,
		RD_n			=> RD_n,
		WR_n			=> WR_n,
		RFSH_n		=> open,
		HALT_n		=> open,
		BUSAK_n		=> open,
		A				=> A,
		DI				=> D_out,
		DO				=> D_in
		
   ,RestorePC => "0000000000000000", --Q
	RestoreINT => "00000000", --Q
	RestorePC_n => '1' --Q		
	);

	vdp_inst: vdp
	port map (
		cpu_clk		=> clk_cpu,
		vdp_clk		=> clk_vdp,
		RD_n			=> vdp_RD_n,
		WR_n			=> vdp_WR_n,
		IRQ_n			=> IRQ_n,
		A				=> A(7 downto 0),
		D_in			=> D_in,
		D_out			=> vdp_D_out,
		x				=> x,
		y				=> y,
--		vblank		=> vblank,
--		hblank		=> hblank,
		RST_vram		=> RST_vram,
		color			=> color);
		
	psg_inst: psg
	port map (
		clk			=> clk32, --clk_cpu
		WR_n			=> psg_WR_n,
		D_in			=> D_in,
		output		=> audio);
		
			
	io_inst: io
   port map (
		clk			=> clk_cpu,
		WR_n			=> io_WR_n,
		RD_n			=> io_RD_n,
		A				=> A(7 downto 0),
		D_in			=> D_in,
		D_out			=> io_D_out,
		J1_up			=> p1_up,
		J1_down		=> p1_down,
		J1_left		=> p1_left,
		J1_right		=> p1_right,
		J1_tl			=> p1_tl,
		J1_tr			=> p1_tr, 
		J2_up			=> j2_up,
		J2_down		=> j2_down,
		J2_left		=> j2_left,
		J2_right		=> j2_right,
		J2_tl			=> j2_tl,
		J2_tr			=> p2_tr,
		RESET			=> reset);
		
	ram_inst: ram
	port map(
		clk			=> clk_cpu,
		RD_n			=> '0',--ram_RD_n,
		WR_n			=> ram_WR_n,
		A				=> A(12 downto 0),
		D_in			=> D_in,
		D_out			=> ram_D_out);

	boot_rom_inst: boot_rom
	port map(
		clk			=> clk_cpu,
		RD_n			=> '0',--boot_rom_RD_n,
		A				=> A(13 downto 0),
		D_out			=> boot_rom_D_out);
	
	spi_inst: spi
	port map (
		clk			=> clk_cpu,
		RD_n			=> spi_RD_n,
		WR_n			=> spi_WR_n,
		A				=> A(7 downto 0),
		D_in			=> D_in,
		D_out			=> spi_D_out,
			
		cs_n			=> spi_cs_n,
		sclk			=> spi_sclk,
		miso			=> spi_do,
		mosi			=> spi_di);
		
 -- Modulo teclado
    keyb : entity work.keyboard port map (
        clk_cpu, 
        ps2_clk, 
		  ps2_data,
        resetKey,
		  MRESET,
		  ctrl_keys 
        );	

	A_TOP <= 18;
	B_TOP <= 4;
--	ram_a(19) <= '0';
		  
		   
	
	-- glue logic

	vdp_WR_n <= WR_n when io_n='0' and A(7 downto 6)="10" else '1';
					
	vdp_RD_n <= RD_n when io_n='0' and (A(7 downto 6)="01" or A(7 downto 6)="10") else '1';
	
	psg_WR_n <= WR_n when io_n='0' and A(7 downto 6)="01" else '1';

	ctl_WR_n <=	WR_n when io_n='0' and A(7 downto 6)="00" and A(0)='0' else '1';

	io_WR_n <=	WR_n when io_n='0' and A(7 downto 6)="00" and A(0)='1' else '1';
					
	io_RD_n <=	RD_n when io_n='0' and A(7 downto 6)="11" else '1';
					
	spi_RD_n <= bootloader or RD_n when io_n='0' and A(7 downto 5)="000" else '1';

	spi_WR_n <= bootloader or WR_n when io_n='0' and A(7 downto 5)="110" else '1';

	ram_WR_n <= WR_n when io_n='1' and A(15 downto 14)="11" else '1'; 
	
	rom_WR_n <= bootloader or WR_n when io_n='1' and A(15 downto 14)="10" else '1';
	
	process (clk_cpu)
	begin
		if rising_edge(clk_cpu) then
			if resetKey = '1' or reset = '0' then --q
					bootloader <= '0';
					reset_counter <= (others=>'1');
					--RST_vram <= '1';
			end if;
			-- memory control
			if reset_counter>0 then
				reset_counter <= reset_counter - 1;
			elsif ctl_WR_n='0' then --Q
				if bootloader='0' then
					bootloader <= '1';
					reset_counter <= (others=>'1');
					--RST_vram <= '0';
				end if;
			end if;
		end if;
	end process;
	
	reset_n <= '0' when reset_counter>0 else '1'; --Q
	
	irom_D_out <=	boot_rom_D_out when bootloader='0' and A(15 downto 14)="00" else rom_D_out;
	
	RST_vram <= '1' when bootloader='0' else '0'; --Q -vram fill
	
	sel_cpu <= '1' when bootloader = '0' else '0'; --high speed when downloading rom from SD / bootloader.
	
   process (io_n,A,spi_D_out,vdp_D_out,io_D_out,irom_D_out,ram_D_out)
	begin
		if io_n='0' then
			case A(7 downto 5) is
			when "000" =>
				D_out <= spi_D_out; 
			when "001" =>
				D_out <= "00000000";
			when "110"|"111" =>
				D_out <= io_D_out;
			when others =>
				D_out <= vdp_D_out;
			end case;
		else
			if A(15 downto 14)="11" then
				D_out <= ram_D_out;
			else
				D_out <= irom_D_out;
			end if;
		end if;
	end process;
				
	-- external ram control
	
	process (clk_cpu)
	begin
		if rising_edge(clk_cpu) then
			if WR_n='0' and A(15 downto 2)="11111111111111" then
				case A(1 downto 0) is
				when "01" => bank0(B_TOP downto 0) <= D_in(B_TOP downto 0); --Q
				when "10" => bank1(B_TOP downto 0) <= D_in(B_TOP downto 0); --Q
				when "11" => bank2(B_TOP downto 0) <= D_in(B_TOP downto 0); --Q
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	ram_we_n <= rom_WR_n; --
	
	ram_a(13 downto 0) <= A(13 downto 0);
	process (A,bank0,bank1,bank2)
	begin
		case A(15 downto 14) is
		when "00" =>
			-- first kilobyte is always from bank 0
			if A(13 downto 10)="0000" then
				ram_a(A_TOP downto 14) <= (others=>'0'); --Q
			else
				ram_a(A_TOP downto 14) <= bank0(B_TOP downto 0); --Q
			end if;
		when "01" =>
			ram_a(A_TOP downto 14) <= bank1(B_TOP downto 0); --Q
			
		when others =>
			ram_a(A_TOP downto 14) <= bank2(B_TOP downto 0); --Q
		end case;
	end process;
	
	ram_d(7 downto 0) <= (others=>'Z') when RD_n='0' else D_in; --Q

	rom_D_out<= ram_d(7 downto 0); --Q
	
	-----------
	-- Control tanto por joystick como por teclado
	-- 0,1,2,3,4,5 = up,dn,l,r,bl,br
	-- 6 = rgb / vga
	-- 7 = pause
	
	p1_up <= ctrl_keys(0) xnor not j1_up;
	p1_down <= ctrl_keys(1) xnor not j1_down;
	p1_left <= ctrl_keys(2) xnor not j1_left;
	p1_right <= ctrl_keys(3) xnor not j1_right;
	p1_tl <= ctrl_keys(4) xnor not j1_tl;
	p1_tr <= '0' when ctrl_keys(5)='1' or j1_tr='0' else 'Z';
	
	p2_tr <= '0' when j2_tr='0' else 'Z'; --j2_tr tristate
	

	process (ctrl_keys(7))
	begin
		if ctrl_keys(7) = '1' or pause = '0' then --Pause
			Kpause <= '0';
		else
			Kpause <= '1';
		end if;
	end process;

	process (ctrl_keys(6)) --RGB/VGA
	begin
		if ctrl_keys(6) = '0' then
			scanSW <= '0';
		else
			scanSW <= '1';
		end if;
	end process;
	
	process (ctrl_keys(8)) --scanlines
	begin
		if ctrl_keys(8) = '0' then
			scanL <= '0';
		else
			scanL <= '1';
		end if;
	end process;	
	
	process (ctrl_keys(9)) --vfreq
	begin
		if ctrl_keys(9) = '0' then
			vfreQ <= '0';
		else
			vfreQ <= '1';
		end if;
	end process;	

	
------------multiboot---------------

	multiboot_i: multiboot
	port map(
		clk_icap		      => clk_vdp,
		REBOOT				=> MRESET
	);
	
			
end Behavioral;