---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY zpu_config_regs IS
GENERIC
(
	platform : integer := 1; -- So ROM can detect which type of system...
	spi_clock_div : integer := 4; -- Quite conservative by default - probably want to use 1 with 28MHz input clock, 2 for 57MHz input clock, 4 for 114MHz input clock etc
	usb : integer :=0 -- USB host slave instances
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	
	POKEY_ENABLE : in std_logic;
	
	ADDR : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	RD_EN : IN STD_LOGIC;
	WR_EN : IN STD_LOGIC;
	
	-- GENERIC INPUT REGS (need to synchronize upstream...)
	IN1 : in std_logic_vector(31 downto 0); 
	IN2 : in std_logic_vector(31 downto 0); 
	IN3 : in std_logic_vector(31 downto 0); 
	IN4 : in std_logic_vector(31 downto 0); 
	
	-- GENERIC OUTPUT REGS
	OUT1 : out  std_logic_vector(31 downto 0); 
	OUT2 : out  std_logic_vector(31 downto 0); 
	OUT3 : out  std_logic_vector(31 downto 0); 
	OUT4 : out  std_logic_vector(31 downto 0); 
	OUT5 : out  std_logic_vector(31 downto 0); 
	OUT6 : out  std_logic_vector(31 downto 0); 
	
	-- SDCARD
	SDCARD_CLK : out std_logic;
	SDCARD_CMD : out std_logic;
	SDCARD_DAT : in std_logic;
	SDCARD_DAT3 : out std_logic;

	-- SD DMA
	sd_addr : out std_logic_vector(15 downto 0);
	sd_data : out std_logic_vector(7 downto 0);
	sd_write : out std_logic;
	
	-- ATARI interface (in future we can also turbo load by directly hitting memory...)
	SIO_DATA_IN  : out std_logic;
	SIO_COMMAND : in std_logic;
	SIO_DATA_OUT : in std_logic;
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	PAUSE_ZPU : out std_logic;

	-- USB host
	CLK_USB : in std_logic;

	USBWireVPin :in std_logic_vector(usb-1 downto 0);
	USBWireVMin :in std_logic_vector(usb-1 downto 0);
	USBWireVPout :out std_logic_vector(usb-1 downto 0);
	USBWireVMout :out std_logic_vector(usb-1 downto 0);
	USBWireOE_n :out std_logic_vector(usb-1 downto 0)
);
END zpu_config_regs;

ARCHITECTURE vhdl OF zpu_config_regs IS

	component usbHostCyc2Wrap_usb1t11
	port (
		clk_i :in std_logic;
		rst_i :in std_logic;
		address_i : in std_logic_vector(7 downto 0);
		data_i : in std_logic_vector(7 downto 0);
		data_o : out std_logic_vector(7 downto 0);
		we_i :in std_logic;
		strobe_i :in std_logic;
		ack_o :out std_logic;
		irq :out std_logic;
		usbClk :in std_logic;
	
		USBWireVPin :in std_logic;
		USBWireVMin :in std_logic;
		USBWireVPout :out std_logic;
		USBWireVMout :out std_logic;
		USBWireOE_n :out std_logic;
		USBFullSpeed :out std_logic
	);
	end component;

	function vectorize(s: std_logic) return std_logic_vector is
	variable v: std_logic_vector(0 downto 0);
	begin
		v(0) := s;
		return v;
	end;
	
	signal device_decoded : std_logic_vector(7 downto 0);	
	signal device_wr_en : std_logic_vector(7 downto 0);	
	signal device_rd_en : std_logic_vector(7 downto 0);	
	signal addr_decoded : std_logic_vector(15 downto 0);	
	
	signal out1_next : std_logic_vector(31 downto 0);
	signal out1_reg : std_logic_vector(31 downto 0);
	signal out2_next : std_logic_vector(31 downto 0);
	signal out2_reg : std_logic_vector(31 downto 0);
	signal out3_next : std_logic_vector(31 downto 0);
	signal out3_reg : std_logic_vector(31 downto 0);
	signal out4_next : std_logic_vector(31 downto 0);
	signal out4_reg : std_logic_vector(31 downto 0);
	signal out5_next : std_logic_vector(31 downto 0);
	signal out5_reg : std_logic_vector(31 downto 0);
	signal out6_next : std_logic_vector(31 downto 0);
	signal out6_reg : std_logic_vector(31 downto 0);
	
	signal spi_miso : std_logic;
	signal spi_mosi : std_logic;
	signal spi_busy : std_logic;	
	signal spi_enable : std_logic;
	signal spi_chip_select : std_logic_vector(0 downto 0);
	signal spi_clk_out : std_logic;
	
	signal spi_tx_data : std_logic_vector(7 downto 0);
	signal spi_rx_data : std_logic_vector(7 downto 0);
	
	signal spi_addr_next : std_logic;
	signal spi_addr_reg : std_logic;
	signal spi_addr_reg_integer : integer;
	signal spi_speed_next : std_logic_vector(7 downto 0);
	signal spi_speed_reg : std_logic_vector(7 downto 0);
	signal spi_speed_reg_integer : integer;

	signal pokey_data_out : std_logic_vector(7 downto 0);
	
	signal pause_next : std_logic_vector(31 downto 0);
	signal pause_reg : std_logic_vector(31 downto 0);
	signal paused_next : std_logic;
	signal paused_reg : std_logic;

	signal subtimer_next : std_logic_vector(10 downto 0);
	signal subtimer_reg : std_logic_vector(10 downto 0);

	signal timer_next : std_logic_vector(31 downto 0);
	signal timer_reg : std_logic_vector(31 downto 0);

	signal spi_dma_addr_next : std_logic_vector(15 downto 0);
	signal spi_dma_addrend_next : std_logic_vector(15 downto 0);
	signal spi_dma_wr : std_logic;
	signal spi_dma_next : std_logic;
	signal spi_dma_addr_reg : std_logic_vector(15 downto 0);
	signal spi_dma_addrend_reg : std_logic_vector(15 downto 0);
	signal spi_dma_reg : std_logic;

	signal spi_clk_div_integer : integer;
	signal spi_addr_integer : integer;

	subtype usb_data_type is std_logic_vector(7 downto 0);
	type usb_data_array is array(0 to USB-1) of usb_data_type;
	signal usb_data : usb_data_array;

	signal data_out_regs : std_logic_vector(31 downto 0);
	signal data_out_mux : std_logic_vector(31 downto 0);
begin
	-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			out1_reg <= (others=>'0');
			out2_reg <= (others=>'0');
			out3_reg <= (others=>'0');
			out4_reg <= (others=>'0');
			out5_reg <= (others=>'0');
			out6_reg <= (others=>'0');
			
			spi_addr_reg <= '1';
			spi_speed_reg <= X"80";

			pause_reg <= (others=>'0');
			paused_reg <= '0';

			subtimer_reg <= (others=>'0');
			timer_reg <= (others=>'0');

			spi_dma_addr_reg <= (others=>'0');
			spi_dma_addrend_reg <= (others=>'0');
			spi_dma_reg <= '0';
		elsif (clk'event and clk='1') then	
			out1_reg <= out1_next;
			out2_reg <= out2_next;
			out3_reg <= out3_next;
			out4_reg <= out4_next;
			out5_reg <= out5_next;
			out6_reg <= out6_next;
			
			spi_addr_reg <= spi_addr_next;
			spi_speed_reg <= spi_speed_next;

			pause_reg <= pause_next;
			paused_reg <= paused_next;

			subtimer_reg <= subtimer_next;
			timer_reg <= timer_next;

			spi_dma_addr_reg <= spi_dma_addr_next;
			spi_dma_addrend_reg <= spi_dma_addrend_next;
			spi_dma_reg <= spi_dma_next;
		end if;
	end process;

	-- decode address
	decode_addr : entity work.complete_address_decoder
		generic map(width=>4)
		port map (addr_in=>addr(3 downto 0), addr_decoded=>addr_decoded);

	decode_device : entity work.complete_address_decoder
		generic map(width=>3)
		port map (addr_in=>addr(10 downto 8), addr_decoded=>device_decoded);

	-- spi - for sd card access without bit banging...
	-- 200KHz to start with - probably fine for 8-bit, can up it later after init
	spi_clk_div_integer <= to_integer(unsigned(spi_speed_reg));
	spi_addr_integer <= to_integer(unsigned(vectorize(spi_addr_reg)));
	spi_master1 : entity work.spi_master
		generic map(slaves=>1,d_width=>8)
		port map (clock=>clk,reset_n=>reset_n,enable=>spi_enable,cpol=>'0',cpha=>'0',cont=>'0',clk_div=>spi_clk_div_integer,addr=>spi_addr_integer,
		          tx_data=>spi_tx_data, miso=>spi_miso,sclk=>spi_clk_out,ss_n=>spi_chip_select,mosi=>spi_mosi,
					 rx_data=>spi_rx_data,busy=>spi_busy);
					 
	-- spi-programming model:
	-- reg for write/read
	-- data (send/receive)
	-- busy
	-- speed - 0=400KHz, 1=10MHz? Start with 400KHz then atari800core...
	-- chip select

	-- device decode
	-- 0x000 - own regs (0)
	-- 0x100 - pokey (1)
	-- 0x200 - usb1 (2)
	-- 0x300 - usb2 (3)
	-- 0x400 - usb3 (4)
	-- 0x500 - usb4 (5)
	-- 0x600 - usb5 (6)
	-- 0x700 - usb6 (7)

	device_wr_en <= device_decoded and (wr_en&wr_en&wr_en&wr_en&wr_en&wr_en&wr_en&wr_en);
	device_rd_en <= device_decoded and (rd_en&rd_en&rd_en&rd_en&rd_en&rd_en&rd_en&rd_en);
	
	-- uart - another Pokey! Running at atari frequency.
	-- with a state machine to capture command packets
	-- can not easily poll frequently enough with zpu when also polling usb
--	pokey1 : entity work.pokey
--		port map (clk=>clk,ENABLE_179=>pokey_enable,addr=>addr(3 downto 0),data_in=>cpu_data_in(7 downto 0),wr_en=>device_wr_en(1), 
--		reset_n=>reset_n,keyboard_response=>"11",pot_in=>X"00",
--		sio_in1=>sio_data_out,sio_in2=>'1',sio_in3=>'1', -- TODO, pokey dir...
--		data_out=>pokey_data_out, 
--		sio_out1=>sio_data_in);

pokey1 : entity work.sio_device
PORT  MAP
( 
	CLK => CLK,
	ADDR => addr(4 downto 0),
	CPU_DATA_IN => cpu_data_in(7 downto 0),
	EN => device_rd_en(1),
	WR_EN => device_wr_en(1),
	
	RESET_N => reset_n,

	POKEY_ENABLE => pokey_enable,

	SIO_DATA_IN  => sio_data_in,
	SIO_COMMAND => sio_command,
	SIO_DATA_OUT => sio_data_out,
	
	-- CPU interface
	DATA_OUT => pokey_data_out
);

	-- timer for approx ms
	process(timer_reg,subtimer_reg, pokey_enable)
	begin
		timer_next <= timer_reg;
		subtimer_next <= subtimer_reg;

		if (pokey_enable = '1') then
			subtimer_next <= std_logic_vector(unsigned(subtimer_reg)-1);
		end if;

		if (subtimer_reg = "000"&x"00") then
			subtimer_next <= std_logic_vector(to_unsigned(11#1790#,11));
			timer_next <= std_logic_vector(unsigned(timer_reg)+1);
		end if;

	end process;

	-- USB host
	USBGEN:
	for I in 0 to USB-1 generate
		usbcon : usbHostCyc2Wrap_usb1t11
		port map 
		(
			clk_i => clk,
			rst_i => not(reset_n),
			address_i => addr(7 downto 0),
			data_i => cpu_data_in(7 downto 0),
			data_o => usb_data(I), -- 2D array
			we_i => device_wr_en(I+2),
			strobe_i => device_wr_en(I+2) or device_rd_en(I+2),
			ack_o => open, -- always right away - checked in sim
			irq => open,
			usbClk => CLK_USB,
		
			USBWireVPin => USBWireVPin(I),
			USBWireVMin => USBWireVMin(I),
			USBWireVPout => USBWireVPout(I),
			USBWireVMout => USBWireVMout(I),
			USBWireOE_n => USBWireOE_n(I),
			USBFullSpeed => open
		);
	end generate USBGEN;

	process(device_decoded, data_out_regs, pokey_data_out, usb_data)
	begin
		data_out_mux <= (others=>'0');
		if (device_decoded(0) = '1') then
			data_out_mux <= data_out_regs;
		end if;

		if (device_decoded(1) = '1') then
			data_out_mux(7 downto 0) <= pokey_data_out;
		end if;

		for I in 0 to USB-1 loop
			if (device_decoded(I+2) = '1') then
				data_out_mux(7 downto 0) <= usb_data(I);
			end if;
		end loop;
	end process;

	-- hardware regs for ZPU
	--
	-- 0-3: GENERIC INPUT (RO)
	-- 4-7: GENERIC OUTPUT (R/W)
	--  8: W:PAUSE, R:Timer (1ms)
	--   9: SPI_DATA
	-- SPI_DATA (DONE) 
	--		W - write data (starts transmission)
	--		R - read data (wait for complete first)
	--  10: SPI_STATE
	-- SPI_STATE/SPI_CTRL (DONE) 
	--    R: 0=busy
	--    W: 0=select_n, speed
	--  11: SIO
	-- SIO
	--    R: 0=CMD
	--  12: TYPE
	-- FPGA board (DONE) 
	--    R(32 bits) 0=DE1
	--  13 : SPI_DMA
	--    W(15 downto 0 = addr),(31 downto 16 = endAddr)
	--  14-15 : GENERIC OUTPUT (R/W)
	--  16-31: POKEY! Low bytes only... i.e. pokey reg every 4 bytes...
				
	-- Writes to registers
	process(cpu_data_in,device_wr_en,addr,addr_decoded, spi_speed_reg, spi_addr_reg, out1_reg, out2_reg, out3_reg, out4_reg, out5_reg, out6_reg, pause_reg, pokey_enable, spi_dma_addr_reg, spi_dma_addrend_reg, spi_dma_reg, spi_busy, spi_dma_addr_next)
	begin
		spi_speed_next <= spi_speed_reg;
		spi_addr_next <= spi_addr_reg;
		spi_tx_data <= (others=>'0');
		spi_enable <= '0';

		out1_next <= out1_reg;
		out2_next <= out2_reg;
		out3_next <= out3_reg;
		out4_next <= out4_reg;
		out5_next <= out5_reg;
		out6_next <= out6_reg;

		paused_next <= '0';
		pause_next <= pause_reg;
		if (not(pause_reg = X"00000000")) then
			if (POKEY_ENABLE='1') then
				pause_next <= std_LOGIC_VECTOR(unsigned(pause_reg)-to_unsigned(1,32));
			end if;
			paused_next <= '1';
		end if;

		spi_dma_addr_next <= spi_dma_addr_reg;
		spi_dma_addrend_next <= spi_dma_addrend_reg;
		spi_dma_wr <= '0';
		spi_dma_next <= spi_dma_reg;
		if (spi_dma_reg = '1') then
			paused_next <= '1';

			if (spi_busy = '0') then
				spi_dma_wr <= '1';
				spi_dma_addr_next <= std_logic_vector(unsigned(spi_dma_addr_reg)+to_unsigned(1,16));
				spi_dma_next <= '0';

				if (not(spi_dma_addr_next = spi_dma_addrend_reg)) then
					spi_tx_data <= X"ff";
					spi_enable <= '1';
					spi_dma_next <= '1';
				end if;
			end if;
		end if;
	
		if (device_wr_en(0) = '1') then
			if(addr_decoded(4) = '1') then
				out1_next <= cpu_data_in;
			end if;	
			
			if(addr_decoded(5) = '1') then
				out2_next <= cpu_data_in;
			end if;	

			if(addr_decoded(6) = '1') then
				out3_next <= cpu_data_in;
			end if;	

			if(addr_decoded(7) = '1') then
				out4_next <= cpu_data_in;
			end if;	

			if(addr_decoded(14) = '1') then
				out5_next <= cpu_data_in;
			end if;	

			if(addr_decoded(15) = '1') then
				out6_next <= cpu_data_in;
			end if;	

			if(addr_decoded(8) = '1') then
				pause_next <= cpu_data_in;
				paused_next <= '1';
			end if;	

			if(addr_decoded(9) = '1') then
				-- TODO, check overrun?
				spi_tx_data <= cpu_data_in(7 downto 0);
				spi_enable <= '1';
			end if;	

			if(addr_decoded(10) = '1') then
				spi_addr_next <= cpu_data_in(0);
				if (cpu_data_in(1) = '1') then
					spi_speed_next <= X"80"; -- slow, for init
				else
					spi_speed_next <= std_logic_vector(to_unsigned(spi_clock_div,8)); -- turbo - up to 25MHz for SD, 20MHz for MMC I believe... If 1 then clock is half input, if 2 then clock is 1/4 input etc.
				end if;
			end if;	

			if(addr_decoded(13) = '1') then
				paused_next <= '1';
				spi_dma_addr_next <= cpu_data_in(15 downto 0);
				spi_dma_addrend_next <= cpu_data_in(31 downto 16);

				spi_dma_next <= '1';

				spi_tx_data <= X"ff";
				spi_enable <= '1';
			end if;
			
		end if;
	end process;
	
	-- Read from registers
	process(addr,addr_decoded, in1, in2, in3, in4, out1_reg, out2_reg, out3_reg, out4_reg, out5_reg, out6_reg, SIO_COMMAND, spi_rx_data, spi_busy, timer_reg)
	begin
		data_out_regs <= (others=>'0');

		if (addr_decoded(0) = '1') then
			data_out_regs <= in1;
		end if;
		
		if (addr_decoded(1) = '1') then
			data_out_regs <= in2;
		end if;		
		
		if (addr_decoded(2) = '1') then
			data_out_regs <= in3;
		end if;		
		
		if (addr_decoded(3) = '1') then
			data_out_regs <= in4;
		end if;

		if (addr_decoded(4) = '1') then
			data_out_regs <= out1_reg;
		end if;
		
		if (addr_decoded(5) = '1') then
			data_out_regs <= out2_reg;
		end if;		
		
		if (addr_decoded(6) = '1') then
			data_out_regs <= out3_reg;
		end if;		
		
		if (addr_decoded(7) = '1') then
			data_out_regs <= out4_reg;
		end if;

		if (addr_decoded(14) = '1') then
			data_out_regs <= out5_reg;
		end if;

		if (addr_decoded(15) = '1') then
			data_out_regs <= out6_reg;
		end if;

		if (addr_decoded(8) = '1') then
			data_out_regs <= timer_reg;
		end if;

		if (addr_decoded(9) = '1') then
			data_out_regs(7 downto 0) <= spi_rx_data;
		end if;

		if (addr_decoded(10) = '1') then
			data_out_regs(0) <= spi_busy;
		end if;		

		if(addr_decoded(11) = '1') then
			data_out_regs(0) <= SIO_COMMAND;
		end if;	
		
		if (addr_decoded(12) = '1') then
			data_out_regs <= std_logic_vector(to_unsigned(platform,32));
		end if;
	end process;	
	
	-- outputs
	PAUSE_ZPU <= paused_reg;

	out1 <= out1_reg;
	out2 <= out2_reg;
	out3 <= out3_reg;
	out4 <= out4_reg;
	out5 <= out5_reg;
	out6 <= out6_reg;
	
	SDCARD_CLK <= spi_clk_out;
	SDCARD_CMD <= spi_mosi;
	spi_miso <= SDCARD_DAT; -- INPUT!! XXX
	SDCARD_DAT3 <= spi_chip_select(0);

	data_out <= data_out_mux;

	sd_addr <= spi_dma_addr_reg;
	sd_data <= spi_rx_data;
	sd_write <= spi_dma_wr;
end vhdl;


