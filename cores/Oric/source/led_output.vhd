-- multiplexes led t for X-SP6-X9
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity XSP6X9_Led_Output is
port (
	clk  : in  std_logic;
	inputs : in  std_logic_vector(31 downto 0);
	segment   : out std_logic_vector( 7 downto 0);
	position   : out std_logic_vector( 7 downto 0)
);
end;

architecture Implementation of XSP6X9_Led_Output is
	signal temp :std_logic_vector(63 downto 0);
        function convert (
          input :std_logic_vector(3 downto 0))
          return std_logic_vector is
          variable res:std_logic_vector(7 downto 0);
        begin
          res := "00000000";
          if (input = X"0") then
            res := "11000000";
          elsif (input = X"1") then
            res := "11111001";
          elsif (input = X"2") then
            res := "10100100";
          elsif (input = X"3") then
            res := "10110000";
          elsif (input = X"4") then
            res := "10011001";
          elsif (input = X"5") then
            res := "10010010";
          elsif (input = X"6") then
            res := "10000010";
          elsif (input = X"7") then
            res := "11111000";
          elsif (input = X"8") then
            res := "10000000";
          elsif (input = X"9") then
            res := "10010000";
          elsif (input = X"a") then
            res := "10001000";
          elsif (input = X"b") then
            res := "10000011";
          elsif (input = X"c") then
            res := "11000110";
          elsif (input = X"d") then
            res := "10100001";
          elsif (input = X"e") then
            res := "10000110";
          elsif (input = X"f") then
            res := "10001110";
          end if;
          return std_logic_vector(res);
        end convert;
          
begin
  set:process(clk)
  begin
    if rising_edge(clk) then
      temp(7  downto  0) <= convert(inputs(3  downto  0));
      temp(15 downto  8) <= convert(inputs(7  downto  4));
      temp(23 downto 16) <= convert(inputs(11 downto  8));
      temp(31 downto 24) <= convert(inputs(15 downto 12));
      temp(39 downto 32) <= convert(inputs(19 downto 16));
      temp(47 downto 40) <= convert(inputs(23 downto 20));
      temp(55 downto 48) <= convert(inputs(27 downto 24));
      temp(63 downto 56) <= convert(inputs(31 downto 28));
    end if;
  end process;  
  multiplexor: entity work.XSP6X9_Led_Multiplex
    port map (
      clk => clk,
      inputs =>temp,
      segment => segment,
      position => position
      );        
end architecture Implementation;
