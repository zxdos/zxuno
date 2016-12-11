library ieee;
	use ieee.std_logic_1164.all;

entity keyboard is
	port
	(
		boot     : out std_logic;
		reset    : out std_logic;
		nmi      : out std_logic;
		received : in  std_logic;
		scancode : in  std_logic_vector(7 downto 0);
		rows     : in  std_logic_vector(7 downto 0);
		cols     : out std_logic_vector(4 downto 0)
	);
end;

architecture behavioral of keyboard is

	type   matrix is array (57 downto 0) of std_logic;
	signal keys : matrix := (others => '1');

	signal pressed  : std_logic := '0';
	signal extended : std_logic := '0';

begin

	process(received, scancode)
	begin
		if falling_edge(received) then

			case scancode is
				when x"E0"  => extended <= '1'; -- extended
				when x"F0"  => pressed  <= '1'; -- released
				when others =>
					extended <= '0';
					pressed  <= '0';
			end case;

			if extended = '0' then
				case scancode is
					when x"12"  => keys( 0) <= pressed; -- CS (LSHIFT)
					when x"1A"  => keys( 1) <= pressed; -- Z
					when x"22"  => keys( 2) <= pressed; -- X
					when x"21"  => keys( 3) <= pressed; -- C
					when x"2A"  => keys( 4) <= pressed; -- V

					when x"1C"  => keys( 5) <= pressed; -- A
					when x"1B"  => keys( 6) <= pressed; -- S
					when x"23"  => keys( 7) <= pressed; -- D
					when x"2B"  => keys( 8) <= pressed; -- F
					when x"34"  => keys( 9) <= pressed; -- G

					when x"15"  => keys(10) <= pressed; -- Q
					when x"1D"  => keys(11) <= pressed; -- W
					when x"24"  => keys(12) <= pressed; -- E
					when x"2D"  => keys(13) <= pressed; -- R
					when x"2C"  => keys(14) <= pressed; -- T

					when x"16"  => keys(15) <= pressed; -- 1
					when x"1E"  => keys(16) <= pressed; -- 2
					when x"26"  => keys(17) <= pressed; -- 3
					when x"25"  => keys(18) <= pressed; -- 4
					when x"2E"  => keys(19) <= pressed; -- 5

					when x"45"  => keys(20) <= pressed; -- 0
					when x"46"  => keys(21) <= pressed; -- 9
					when x"3E"  => keys(22) <= pressed; -- 8
					when x"3D"  => keys(23) <= pressed; -- 7
					when x"36"  => keys(24) <= pressed; -- 6

					when x"4D"  => keys(25) <= pressed; -- P
					when x"44"  => keys(26) <= pressed; -- O
					when x"43"  => keys(27) <= pressed; -- I
					when x"3C"  => keys(28) <= pressed; -- U
					when x"35"  => keys(29) <= pressed; -- Y

					when x"5A"  => keys(30) <= pressed; -- ENTER
					when x"4B"  => keys(31) <= pressed; -- L
					when x"42"  => keys(32) <= pressed; -- K
					when x"3B"  => keys(33) <= pressed; -- J
					when x"33"  => keys(34) <= pressed; -- H

					when x"29"  => keys(35) <= pressed; -- SPACE
					when x"59"  => keys(36) <= pressed; -- SS (RSHIFT)
					when x"3A"  => keys(37) <= pressed; -- M
					when x"31"  => keys(38) <= pressed; -- N
					when x"32"  => keys(39) <= pressed; -- B

					when x"14"  => keys(40) <= pressed; -- LCTRL
					when x"11"  => keys(41) <= pressed; -- LALT
					when x"71"  => keys(42) <= pressed; -- KP.

					when x"66"  => keys(43) <= pressed; -- BKSP
					when x"4A"  => keys(44) <= pressed; -- -
					when x"49"  => keys(45) <= pressed; -- .
					when x"41"  => keys(46) <= pressed; -- ,

					when x"03"  => keys(54) <= pressed; -- F5
					when x"78"  => keys(57) <= pressed; -- F11
					when x"07"  => keys(55) <= pressed; -- F12
					when x"76"  => keys(56) <= pressed; -- ESCAPE

					when others => null;
				end case;
			else
				case scancode is
					when x"14"  => keys(47) <= pressed; -- RCTRL
					when x"11"  => keys(48) <= pressed; -- RALT
					when x"71"  => keys(49) <= pressed; -- DEL

					when x"75"  => keys(50) <= pressed; -- UP
					when x"72"  => keys(51) <= pressed; -- DOWN
					when x"6B"  => keys(52) <= pressed; -- LEFT
					when x"74"  => keys(53) <= pressed; -- RIGHT

					when others => null;
				end case;
			end if;
		end if;
	end process;

	cols(0) <=  ( keys( 0) or rows(0) ) and -- CS
				( keys( 5) or rows(1) ) and -- A
				( keys(10) or rows(2) ) and -- Q
				( keys(15) or rows(3) ) and -- 1
				( keys(20) or rows(4) ) and -- 0
				( keys(25) or rows(5) ) and -- P
				( keys(30) or rows(6) ) and -- ENTER
				( keys(35) or rows(7) ) and -- SPACE
				( keys(43) or rows(0) ) and -- DELETE(CS)
				( keys(43) or rows(4) ) and -- DELETE(0)
				( keys(50) or rows(0) ) and -- UP(CS)
				( keys(51) or rows(0) ) and -- DOWN(CS)
				( keys(52) or rows(0) ) and -- LEFT(CS)
				( keys(53) or rows(0) ) and -- RIGHT(CS)
				( keys(56) or rows(0) ) and -- ESC
				( keys(56) or rows(7) );    -- ESC

	cols(1) <=  ( keys( 1) or rows(0) ) and -- Z
				( keys( 6) or rows(1) ) and -- S
				( keys(11) or rows(2) ) and -- W
				( keys(16) or rows(3) ) and -- 2
				( keys(21) or rows(4) ) and -- 9
				( keys(26) or rows(5) ) and -- O
				( keys(31) or rows(6) ) and -- L
				( keys(36) or rows(7) ) and -- SS
				( keys(44) or rows(7) ) and -- -(SS)
				( keys(45) or rows(7) ) and -- .(SS)
				( keys(46) or rows(7) );    -- ,(SS)

	cols(2) <=  ( keys( 2) or rows(0) ) and -- X
				( keys( 7) or rows(1) ) and -- D
				( keys(12) or rows(2) ) and -- E
				( keys(17) or rows(3) ) and -- 3
				( keys(22) or rows(4) ) and -- 8
				( keys(27) or rows(5) ) and -- I
				( keys(32) or rows(6) ) and -- K
				( keys(37) or rows(7) ) and -- M
				( keys(45) or rows(7) ) and -- .(M)
				( keys(53) or rows(4) );    -- RIGHT(8)

	cols(3) <=  ( keys( 3) or rows(0) ) and -- C
				( keys( 8) or rows(1) ) and -- F
				( keys(13) or rows(2) ) and -- R
				( keys(18) or rows(3) ) and -- 4
				( keys(23) or rows(4) ) and -- 7
				( keys(28) or rows(5) ) and -- U
				( keys(33) or rows(6) ) and -- J
				( keys(38) or rows(7) ) and -- N
				( keys(44) or rows(6) ) and -- -(J)
				( keys(46) or rows(7) ) and -- ,(N)
				( keys(50) or rows(4) );    -- UP(7)

	cols(4) <=  ( keys( 4) or rows(0) ) and -- V
				( keys( 9) or rows(1) ) and -- G
				( keys(14) or rows(2) ) and -- T
				( keys(19) or rows(3) ) and -- 5
				( keys(24) or rows(4) ) and -- 6
				( keys(29) or rows(5) ) and -- Y
				( keys(34) or rows(6) ) and -- H
				( keys(39) or rows(7) ) and -- B
				( keys(52) or rows(3) ) and -- LEFT(5)
				( keys(51) or rows(4) );    -- DOWN(7)

	nmi   <= keys(54);
	boot  <= keys(57) and ((keys(40) and keys(47)) or (keys(41) and keys(48)) or (keys(43)));
	reset <= keys(55) and ((keys(40) and keys(47)) or (keys(41) and keys(48)) or (keys(42) and keys(49)));

end;
