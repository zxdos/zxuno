-- multiplexes led t for X-SP6-X9
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;
        use ieee.std_logic_arith.all;

entity XSP6X9_onebit is
    generic (k : integer := 255);  -- ratio by which to divide the clk: clkout = clk/DIVRATIO.
    port (
        nreset  : in std_logic;         -- active-low asynchronous global reset
	clk  : in  std_logic;
	input : in  std_logic_vector(7 downto 0);
	output   : out std_logic;
        voutput : out std_logic_vector (7 downto 0)
);
end;

architecture Implementation of XSP6X9_onebit is
  signal final: std_logic_vector(15 downto 0);
  signal sum : std_logic_vector(15 downto 0);
  signal difference:std_logic_vector (7 downto 0);
  signal product :std_logic_vector (15 downto 0);
  signal divided_clock:std_logic;
begin

  inst_clock_div :entity work.clkdiv
    generic map (
      DIVRATIO => 512
      )
    port map (
      nreset => nreset,
      clk =>clk,
      clkout => divided_clock
      );

  
  change: process(divided_clock, nreset)
    variable kvec: std_logic_vector(7 downto 0);
  begin
    if (nreset = '0') then
      final <= (others => '1');
      difference <= (others => '0');
      product <= (others => '0');
    else
      if (rising_edge(divided_clock)) then
        difference <= input - final(15 downto 8);
        kvec := conv_std_logic_vector(k, 8);
        product <= kvec * difference;
        sum <= sum + product;
        final <= sum;
      end if;
    end if;
  end process;
  outputbit: process(divided_clock, nreset)
  begin
    if (nreset = '0') then
      output <= '1';
    else
      if (rising_edge(divided_clock)) then
        output <= not final(15);
        voutput <= final(15 downto 8);
      end if;     
    end if;
  end process;
end architecture Implementation;
