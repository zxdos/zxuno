library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
library unisim;
	use unisim.vcomponents.all;

entity clock is
	port
	(
		clock50  : in  std_logic;
		clock14  : out std_logic; -- 14.000 MHz
		clock700 : out std_logic; --  7.000 MHz
		clock350 : out std_logic; --  3.500 Mhz
		clock175 : out std_logic  --  1.750 Mhz
	);
end;

architecture behavioral of clock is

	signal cfb : std_logic;
	signal c50 : std_logic;
	signal c14 : std_logic;
	signal count : std_logic_vector(2 downto 0);

begin

	Uibufg : ibufg port map(i => clock50, o => c50);
	Uclock14 : bufg port map(i => c14, o => clock14);
	Uclock700 : bufg port map(i => count(0), o => clock700);
	Uclock350 : bufg port map(i => count(1), o => clock350);
	clock175 <= count(2);
--	Uclock175 : bufg port map(i => count(2), o => clock175);

	uclock : pll_base
	generic map
	(
		bandwidth          => "optimized",
		clk_feedback       => "clkfbout",
		compensation       => "internal",
		clkin_period       => 20.000,
		ref_jitter         => 0.010,
		divclk_divide      => 1,
		clkfbout_mult      => 14,
		clkfbout_phase     => 0.000,
		clkout0_divide     => 50,
		clkout0_phase      => 0.000,
		clkout0_duty_cycle => 0.500
	)
	port map
	(
		rst                => '0',
		clkfbin            => cfb,
		clkfbout           => cfb,
		clkin              => c50,
		clkout0            => c14,
		clkout1            => open,
		clkout2            => open,
		clkout3            => open,
		clkout4            => open,
		clkout5            => open,
		locked             => open
	);
	count <= count+1 when falling_edge(c14);

end;
