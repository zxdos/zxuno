library ieee;
	use ieee.std_logic_1164.all;
library unisim;
	use unisim.vcomponents.all;

entity clock is
	port
	(
		clock32  : in  std_logic;
		clockVGA : out std_logic;
		clockDAC : out std_logic;
		clockCPU : out std_logic;
		clockAY  : out std_logic
	);
end;

architecture behavioral of clock is

	signal ci32  : std_logic;
	signal c1fb  : std_logic;
	signal c2fb  : std_logic;
	signal covga : std_logic;
	signal codac : std_logic;
	signal cocpu : std_logic;
	signal coay  : std_logic;

begin

	Uibufg : ibufg port map(i => clock32, o => ci32);
	IbufgVGA : bufg port map(i => covga, o => clockVGA);
	IbufgDAC : bufg port map(i => codac, o => clockDAC);
	IbufgCPU : bufg port map(i => cocpu, o => clockCPU);
	IbufgAY  : bufg port map(i => coay,  o => clockAY );

	Uclock1 : pll_base -- 25 MHz
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
		clkout0            => covga,
		clkout1            => open,
		clkout2            => open,
		clkout3            => open,
		clkout4            => open,
		clkout5            => open,
		locked             => open,
		clkfbout           => c1fb
	);
	Uclock2 : pll_base -- 3.5 MHz
	generic map
	(
		bandwidth           => "optimized",
		clk_feedback        => "clkfbout",
		compensation        => "system_synchronous",
		divclk_divide       => 1,
		clkfbout_mult       => 14,
		clkfbout_phase      => 0.000,
		clkout0_divide      => 32,
		clkout0_phase       => 0.000,
		clkout0_duty_cycle  => 0.500,
		clkout1_divide      => 128,
		clkout1_phase       => 0.000,
		clkout1_duty_cycle  => 0.500,
		clkin_period        => 31.250,
		ref_jitter          => 0.010
	)
	port map
	(
		rst                 => '0',
		clkin               => ci32,
		clkfbin             => c2fb,
		clkout0             => codac,
		clkout1             => cocpu,
		clkout2             => open,
		clkout3             => open,
		clkout4             => open,
		clkout5             => open,
		locked              => open,
		clkfbout            => c2fb
	);
	
	coay <= cocpu;--not coay when rising_edge(cocpu);

end;

