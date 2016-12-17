--Q
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity VIC20_RAM8 is
  port (
  V_ADDR : in  std_logic_vector(12 downto 0);
  DIN    : in  std_logic_vector(7 downto 0);
  DOUT   : out std_logic_vector(7 downto 0);
  V_RW_L : in  std_logic;
  CS_L   : in  std_logic;
  ENA    : in  std_logic;
  CLK    : in  std_logic
  );
end;

architecture RTL of VIC20_RAM8 is

  signal addr         : std_logic_vector(12 downto 0);
  signal we           : std_logic;

begin
  addr <=  V_ADDR;

	RAM0 : RAMB16_S2
	port map (
		CLK  => clk,
		DI   => din(1 downto 0),
		DO   => dout(1 downto 0),
		ADDR => addr,
		EN   => ENA,
		SSR  => '0',
		WE   => we
	);

	RAM1 : RAMB16_S2
	port map (
		CLK  => clk,
		DI   => din(3 downto 2),
		DO   => dout(3 downto 2),
		ADDR => addr,
		EN   => ENA,
		SSR  => '0',
		WE   => we
	);
	RAM2 : RAMB16_S2
	port map (
		CLK  => clk,
		DI   => din(5 downto 4),
		DO   => dout(5 downto 4),
		ADDR => addr,
		EN   => ENA,
		SSR  => '0',
		WE   => we
	);
	RAM3 : RAMB16_S2
	port map (
		CLK  => clk,
		DI   => din(7 downto 6),
		DO   => dout(7 downto 6),
		ADDR => addr,
		EN   => ENA,
		SSR  => '0',
		WE   => we
	);

  p_we : process(V_RW_L, CS_L)
  begin
    we <= (not CS_L) and (not V_RW_L);
  end process;

end architecture RTL;
