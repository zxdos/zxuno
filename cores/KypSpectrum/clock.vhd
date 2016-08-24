library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
library unisim;
	use unisim.vcomponents.all;

entity clock is
	port
	(
		clock32  : in  std_logic;
		clockCPU : out std_logic;
		clockVGA : out std_logic;
		clockPS2 : out std_logic;
		clockDAC : out std_logic;
		clockAY  : out std_logic
	);
end;

architecture behavioral of clock is

	signal ci32  : std_logic;
	signal c1fb  : std_logic;
	signal c2fb  : std_logic;
	signal co25  : std_logic;
	signal co14  : std_logic;
	signal count : std_logic_vector(1 downto 0);

begin

	Uibufg : ibufg port map(i => clock32, o => ci32);
	IbufgVGA : bufg port map(i => co25, o => clockVGA);
	IbufgPS2 : bufg port map(i => ci32, o => clockPS2);
	IbufgDAC : bufg port map(i => co14, o => clockDAC);
	IbufgCPU : bufg port map(i => count(1), o => clockCPU);
	IbufgAY  : bufg port map(i => count(1), o => clockAY);

	Uclock1 : pll_base -- clkout0 = 25.143 MHz
	generic map
	(
		bandwidth          => "optimized",
		clk_feedback       => "clkfbout",
		compensation       => "system_synchronous",
		divclk_divide      => 1,
		clkfbout_mult      => 22,
		clkfbout_phase     => 0.000,
		clkout0_divide     => 28,
		clkout0_phase      => 0.000,
		clkout0_duty_cycle => 0.500,
		clkin_period       => 31.250,
		ref_jitter         => 0.010
	)
	port map
	(
		rst                => '0',
		clkin              => ci32,
		clkfbin            => c1fb,
		clkout0            => co25,
		clkout1            => open,
		clkout2            => open,
		clkout3            => open,
		clkout4            => open,
		clkout5            => open,
		locked             => open,
		clkfbout           => c1fb
	);
	Uclock2 : pll_base -- clkout0 = 14 MHz
	generic map
	(
		bandwidth           => "optimized",
		clk_feedback        => "clkfbout",
		compensation        => "system_synchronous",
		divclk_divide       => 1,
		clkfbout_mult       => 28,
		clkfbout_phase      => 0.000,
		clkout0_divide      => 64,
		clkout0_phase       => 0.000,
		clkout0_duty_cycle  => 0.500,
		clkin_period        => 31.250,
		ref_jitter          => 0.010
	)
	port map
	(
		rst                 => '0',
		clkin               => ci32,
		clkfbin             => c2fb,
		clkout0             => co14,
		clkout1             => open,
		clkout2             => open,
		clkout3             => open,
		clkout4             => open,
		clkout5             => open,
		locked              => open,
		clkfbout            => c2fb
	);
	
	count <= count+1 when rising_edge(co14);

end;
