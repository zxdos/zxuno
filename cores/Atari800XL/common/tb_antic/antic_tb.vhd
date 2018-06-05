library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity antic_tb is
end;

architecture rtl of antic_tb is

  constant CLK_A_PERIOD : time := 1 us / (1.79*32);

  signal reset_n : std_logic;
	signal clk_a : std_logic;

	signal cpu_addr : std_logic_vector(15 downto 0);
	signal cpu_data_in : std_logic_vector(7 downto 0);
	signal cpu_wr_en : std_logic;
	signal memory_ready_antic : std_logic;
	signal memory_ready_cpu : std_logic;
	signal memory_data_in : std_logic_vector(7 downto 0);
	signal antic_enable_179 : std_logic;
	signal enable_179_memwait : std_logic;
	signal cpu_shared_enable : std_logic;
	signal an : std_logic_vector(2 downto 0);
	signal cc_out_orig : std_logic;
	signal cc_out_used : std_logic;
	signal cc_out_used_doubled : std_logic;
	signal fetch : std_logic;
	signal fetch_address : std_logic_vector(15 downto 0);
	signal refresh : std_logic;
	signal hcount : std_logic_vector(7 downto 0);

begin
	p_clk_gen_a : process
	begin
	clk_a <= '1';
	wait for CLK_A_PERIOD/2;
	clk_a <= '0';
	wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

--	signal cpu_addr : std_logic_vector(15 downto 0);
--	signal cpu_data_in : std_logic_vector(7 downto 0);
--	signal cpu_wr_en : std_logic;
--	signal memory_ready_antic : std_logic;
--	memory_ready_antic <= '0';
--	signal memory_ready_cpu : std_logic;
	memory_ready_cpu <= cpu_shared_enable and not(fetch) and not(refresh);
--	signal memory_data_in : std_logic_vector(7 downto 0);
--	memory_data_in <= (others=>'0');
--	signal an : std_logic_vector(2 downto 0);
--	signal cc_out_orig : std_logic;
--	signal cc_out_used : std_logic;
--	signal cc_out_used_doubled : std_logic;
--	signal fetch : std_logic;
--	signal fetch_address : std_logic_vector(!5 downto 0);

	process_setup_antic : process
	begin
	cpu_wr_en <= '0';

	wait for 1100ns;

	wait until cpu_shared_enable = '1';
	cpu_wr_en <= '1';
	cpu_addr<= x"d402";
	cpu_data_in <= x"00";
	wait until cpu_shared_enable = '0';
	cpu_wr_en <= '0';

	wait until cpu_shared_enable = '1';
	cpu_wr_en <= '1';
	cpu_addr<= x"d403";
	cpu_data_in <= x"06";
	wait until cpu_shared_enable = '0';
	cpu_wr_en <= '0';

	wait until cpu_shared_enable = '1';
	cpu_wr_en <= '1';
	cpu_addr <= x"d400";
	cpu_data_in <= x"62";
	wait until cpu_shared_enable = '0';
	cpu_wr_en <= '0';

	wait until cpu_shared_enable = '1';
	wait for clk_a_period*7;
	cpu_wr_en <= '1';
	cpu_addr <= x"d40a";
	cpu_data_in <= x"11";
	wait for clk_a_period*1;
	cpu_wr_en <= '0';

	wait for 100000000us;

	end process;

	process_antic_dl_data : process
		variable fetch_pos : integer;
		type MEM is array(0 to 1000) of std_logic_vector(7 downto 0); 
		variable fetch_data : MEM;
	begin
--		fetch_data(0) := x"42";
--		fetch_data(1) := x"11";
--		fetch_data(2) := x"22";
--		fetch_data(3) := x"33";
--		fetch_data(4) := x"44";
--		fetch_data(5) := x"55";
--		fetch_data(6) := x"00";
--		fetch_data(7) := x"07";
--		fetch_data(8) := x"92"; -- char1
--		fetch_data(9) := x"34"; -- char2
--		fetch_data(10) := x"ff"; -- char1 data
--		fetch_data(11) := x"d6"; -- char3
--		fetch_data(12) := x"00"; -- char2 data
--		fetch_data(13) := x"78"; -- char4
--		fetch_data(14) := x"ff"; -- char3 data
--		fetch_data(15):= x"12"; -- char5
--		fetch_data(16):= x"00"; -- char4 data
--		fetch_data(17):= x"12"; -- char6
--		fetch_data(18):= x"a5"; -- char5 data
--		fetch_data(19):= x"12"; -- char7
--		fetch_data(20):= x"a5"; -- char6 data
--		fetch_data(21):= x"12"; -- char8

--		fetch_data(0) := x"42";
--		fetch_data(1) := x"00";
--		fetch_data(2) := x"07";
--		fetch_data(3) := x"92"; -- char1
--		fetch_data(4) := x"34"; -- char2
--		fetch_data(5) := x"ff"; -- char1 data
--		fetch_data(6) := x"d6"; -- char3
--		fetch_data(7) := x"00"; -- char2 data
--		fetch_data(8) := x"78"; -- char4
--		fetch_data(9) := x"ff"; -- char3 data
--		fetch_data(10):= x"12"; -- char5
--		fetch_data(11):= x"00"; -- char4 data
--		fetch_data(12):= x"12"; -- char6
--		fetch_data(13):= x"a5"; -- char5 data
--		fetch_data(14):= x"12"; -- char7
--		fetch_data(15):= x"a5"; -- char6 data
--		fetch_data(16):= x"12"; -- char8

		fetch_data(0) := x"42";
		fetch_data(1) := x"00";
		fetch_data(2) := x"07";
		fetch_data(3) := x"ff"; -- char1
		fetch_data(4) := x"55"; -- char2
		fetch_data(5) := x"ff"; -- char1 data
		fetch_data(6) := x"ff"; -- char3
		fetch_data(7) := x"ff"; -- char2 data
		fetch_data(8) := x"ff"; -- char4
		fetch_data(9) := x"ff"; -- char3 data
		fetch_data(10):= x"ff"; -- char5
		fetch_data(11):= x"ff"; -- char4 data
		fetch_data(12):= x"ff"; -- char6
		fetch_data(13):= x"ff"; -- char5 data
		fetch_data(14):= x"ff"; -- char7
		fetch_data(15):= x"ff"; -- char6 data
		fetch_data(16):= x"ff"; -- char8

		fetch_pos := 0;

		memory_ready_antic <= '0';
		memory_data_in <= (others=>'0');
		loop
			wait until fetch='1';
			--wait for fetch_delay(fetch_pos);
			--wait for clk_a_period*9;
			wait for clk_a_period*3;
			memory_data_in <= fetch_data(fetch_pos);
			memory_ready_antic <= '1';
			wait until fetch = '0';
			memory_ready_antic <= '0';
			memory_data_in <= (others=>'0');

			fetch_pos := fetch_pos +1;
		end loop;
	end process;
	
	enables : entity work.shared_enable
	GENERIC MAP(cycle_length => 16)
	PORT MAP(CLK => CLK_a,
		 RESET_N => RESET_N,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 ANTIC_REFRESH => refresh,
		 PAUSE_6502 => '0',
		 THROTTLE_COUNT_6502 => "000001",
		 ANTIC_ENABLE_179 => ANTIC_ENABLE_179,
		 oldcpu_enable => ENABLE_179_MEMWAIT,
		 CPU_ENABLE_OUT => CPU_SHARED_ENABLE);

	antic1: entity work.antic
	generic map
	(
		cycle_length => 16
	)
	port map 
	( 
		CLK => clk_a,
		ADDR => cpu_addr(3 downto 0),
		CPU_DATA_IN => cpu_data_in, -- for writes
		WR_EN => cpu_wr_en,
		
		RESET_N => reset_n,
		
		MEMORY_READY_ANTIC => memory_ready_antic,
		MEMORY_READY_CPU => memory_ready_cpu,
		MEMORY_DATA_IN => memory_data_in, -- for fetches
		ANTIC_ENABLE_179 => antic_enable_179,
		
		PAL => '1',
		
		lightpen => '0',
		
		-- CPU interface
		DATA_OUT => open,
		NMI_N_OUT => open,
		ANTIC_READY => open,
		
		-- GTIA interface
		AN => an,
		COLOUR_CLOCK_ORIGINAL_OUT => cc_out_orig,
		COLOUR_CLOCK_OUT => cc_out_used,
		HIGHRES_COLOUR_CLOCK_OUT => cc_out_used_doubled,
		
		-- DMA fetch
		dma_fetch_out => fetch,
		dma_address_out => fetch_address,
		
		-- refresh
		refresh_out =>refresh,
		
		-- for debugging
		dma_clock_out => open,
		hcount_out => hcount,
		vcount_out => open
	);

end rtl;

