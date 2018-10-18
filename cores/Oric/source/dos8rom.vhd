library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dos8rom is
 port (
   addr : in  std_logic_vector(8 downto 0);
   clk  : in  std_logic;
   dout : out std_logic_vector(7 downto 0));
end dos8rom;

architecture rtl of dos8rom is
  type rom_array is array(0 to 511) of unsigned(7 downto 0);

  constant ROM : rom_array := (
     X"30", X"33", X"30", X"30", X"2e", X"2e", X"30", X"33",
     X"30", X"46", X"20", X"2d", X"20", X"56", X"49", X"41",
     X"30", X"33", X"31", X"30", X"2e", X"2e", X"30", X"33",
     X"31", X"46", X"20", X"2d", X"20", X"46", X"44", X"43",
     X"78", X"a2", X"05", X"bd", X"2f", X"03", X"9d", X"ea",
     X"02", X"ca", X"10", X"f7", X"4c", X"ea", X"02", X"8d",
     X"82", X"03", X"4c", X"20", X"03", X"42", X"4f", X"42",
     X"59", X"ff", X"ff", X"8d", X"81", X"03", X"20", X"03",
     X"d4", X"8d", X"80", X"03", X"60", X"8d", X"81", X"03",
     X"20", X"06", X"d4", X"8d", X"80", X"03", X"60", X"8d",
     X"80", X"03", X"20", X"5f", X"c5", X"8d", X"81", X"03",
     X"60", X"8d", X"80", X"03", X"20", X"c5", X"e0", X"8d",
     X"81", X"03", X"60", X"8d", X"80", X"03", X"4c", X"bd",
     X"c4", X"78", X"8d", X"81", X"03", X"20", X"00", X"d4",
     X"8d", X"80", X"03", X"58", X"4c", X"03", X"c0", X"78",
     X"8d", X"81", X"03", X"4c", X"00", X"c0", X"8d", X"80",
     X"03", X"20", X"92", X"c5", X"8d", X"81", X"03", X"60",
     X"8d", X"80", X"03", X"20", X"fb", X"cc", X"8d", X"81",
     X"03", X"60", X"8d", X"80", X"03", X"20", X"a0", X"03",
     X"8d", X"81", X"03", X"40", X"20", X"a0", X"03", X"40",
     X"08", X"48", X"a9", X"03", X"48", X"a9", X"ac", X"48",
     X"08", X"4c", X"22", X"ee", X"68", X"28", X"60", X"ff",
     X"78", X"a9", X"c0", X"85", X"41", X"a9", X"00", X"85",
     X"40", X"a2", X"40", X"a0", X"00", X"8d", X"84", X"03",
     X"b1", X"40", X"8d", X"85", X"03", X"ea", X"91", X"40",
     X"88", X"d0", X"f2", X"e6", X"41", X"8a", X"a2", X"2e",
     X"20", X"d9", X"03", X"aa", X"ca", X"d0", X"e4", X"58",
     X"60", X"8d", X"84", X"03", X"ea", X"20", X"7c", X"f7",
     X"ea", X"ea", X"8d", X"85", X"03", X"60", X"ff", X"ff",
     X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff",
     X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff",
     X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff",
     X"30", X"33", X"30", X"30", X"2e", X"2e", X"30", X"33",
     X"30", X"46", X"20", X"2d", X"20", X"56", X"49", X"41",
     X"30", X"33", X"31", X"30", X"2e", X"2e", X"30", X"33",
     X"31", X"46", X"20", X"2d", X"20", X"46", X"44", X"43",
     X"78", X"d8", X"a0", X"00", X"a2", X"03", X"86", X"78",
     X"8a", X"0a", X"24", X"78", X"f0", X"10", X"05", X"78",
     X"49", X"ff", X"29", X"7e", X"b0", X"08", X"4a", X"d0",
     X"fb", X"98", X"9d", X"56", X"b4", X"c8", X"e8", X"10",
     X"e5", X"2c", X"1e", X"03", X"2c", X"1c", X"03", X"2c",
     X"1a", X"03", X"2c", X"19", X"03", X"a2", X"00", X"a0",
     X"48", X"dd", X"10", X"03", X"98", X"29", X"03", X"0a",
     X"aa", X"dd", X"11", X"03", X"a2", X"08", X"d6", X"76",
     X"d0", X"fc", X"ca", X"10", X"f9", X"aa", X"88", X"10",
     X"e8", X"a9", X"b8", X"85", X"77", X"18", X"08", X"ad",
     X"1c", X"03", X"10", X"fb", X"49", X"d5", X"d0", X"f7",
     X"ad", X"1c", X"03", X"10", X"fb", X"c9", X"aa", X"d0",
     X"f3", X"ea", X"ad", X"1c", X"03", X"10", X"fb", X"c9",
     X"96", X"f0", X"09", X"28", X"90", X"df", X"49", X"ad",
     X"f0", X"25", X"d0", X"d9", X"a0", X"03", X"85", X"7c",
     X"ad", X"1c", X"03", X"10", X"fb", X"2a", X"85", X"78",
     X"ad", X"1c", X"03", X"10", X"fb", X"25", X"78", X"88",
     X"d0", X"ec", X"28", X"c5", X"79", X"d0", X"be", X"a5",
     X"7c", X"c5", X"7d", X"d0", X"b8", X"b0", X"b7", X"a0",
     X"56", X"84", X"78", X"ac", X"1c", X"03", X"10", X"fb",
     X"59", X"d6", X"b3", X"a4", X"78", X"88", X"99", X"00",
     X"b4", X"d0", X"ee", X"84", X"78", X"ac", X"1c", X"03",
     X"10", X"fb", X"59", X"d6", X"b3", X"a4", X"78", X"91",
     X"76", X"c8", X"d0", X"ef", X"ac", X"1c", X"03", X"10",
     X"fb", X"59", X"d6", X"b3", X"d0", X"87", X"a0", X"00",
     X"a2", X"56", X"ca", X"30", X"fb", X"b1", X"76", X"5e",
     X"00", X"b4", X"2a", X"5e", X"00", X"b4", X"2a", X"91",
     X"76", X"c8", X"d0", X"ee", X"4c", X"00", X"b8", X"ff");

begin

process (clk)
  begin
    if rising_edge(clk) then
      dout <= std_logic_vector(ROM(TO_INTEGER(unsigned(addr))));
    end if;
  end process;

end rtl;
