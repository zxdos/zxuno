library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity keymap is
	port(
		A		: in std_logic_vector(7 downto 0);		
		
		ROW	: out std_logic_vector(2 downto 0);
		COL	: out std_logic_vector(2 downto 0);
		EN		: out std_logic
	);
end keymap;

architecture arch of keymap is
begin

-- ROWS

   ROM256X1_ROW2 : ROM256X1
   generic map (
		INIT => X"00140800000000000000000000000000004000402E3400000000004E7C760000")
   port map (
      O => ROW(2),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

   ROM256X1_ROW1 : ROM256X1
   generic map (
		INIT => X"00340000000000000000000000000000000000002834763000146C7E68200000")
   port map (
      O => ROW(1),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

   ROM256X1_ROW0 : ROM256X1
   generic map (
		INIT => X"003008000000000000000000000000000040004004346C4A004A1C7A34400000")
   port map (
      O => ROW(0),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

-- COLUMNS

   ROM256X1_COL2 : ROM256X1
   generic map (
		INIT => X"00340800000000000000000000000000000000400E302E3A5038021038060000")
   port map (
      O => COL(2),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

   ROM256X1_COL1 : ROM256X1
   generic map (
		INIT => X"000000000000000000000000000000000000000026245C64447C00327C100000")
   port map (
      O => COL(1),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

   ROM256X1_COL0 : ROM256X1
   generic map (
		INIT => X"00000000000000000000000000000000004000402E347C7C5800380800220000")
   port map (
      O => COL(0),   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

-- ENABLE

   ROM256X1_EN : ROM256X1
   generic map (
		INIT => X"00340800000000000000000000000000004000402E347E7E7C7E7E7E7C760000")
   port map (
      O => EN,   -- ROM output
      A0 => A(0), -- ROM address[0]
      A1 => A(1), -- ROM address[1]
      A2 => A(2), -- ROM address[2]
      A3 => A(3), -- ROM address[3]
      A4 => A(4), -- ROM address[4]
      A5 => A(5), -- ROM address[5]
      A6 => A(6),  -- ROM address[6]
      A7 => A(7)  -- ROM address[7]
   );

end arch;

