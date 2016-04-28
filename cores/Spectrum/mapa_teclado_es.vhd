--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mapa_es is
  constant KEY_RELEASED : std_logic_vector(7 downto 0) := X"f0";
  constant KEY_EXTENDED : std_logic_vector(7 downto 0) := X"e0";
  constant KEY_ESC 		: std_logic_vector(7 downto 0) := X"76";
  constant KEY_F1 		: std_logic_vector(7 downto 0) := X"05";
  constant KEY_F2 		: std_logic_vector(7 downto 0) := X"06";
  constant KEY_F3 		: std_logic_vector(7 downto 0) := X"04";
  constant KEY_F4 		: std_logic_vector(7 downto 0) := X"0C";
  constant KEY_F5 		: std_logic_vector(7 downto 0) := X"03";
  constant KEY_F6 		: std_logic_vector(7 downto 0) := X"0B";
  constant KEY_F7 		: std_logic_vector(7 downto 0) := X"83";
  constant KEY_F8 		: std_logic_vector(7 downto 0) := X"0A";
  constant KEY_F9 		: std_logic_vector(7 downto 0) := X"01";
  constant KEY_F10 		: std_logic_vector(7 downto 0) := X"09";
  constant KEY_F11 		: std_logic_vector(7 downto 0) := X"78";
  constant KEY_F12 		: std_logic_vector(7 downto 0) := X"07";

  constant KEY_BL 		: std_logic_vector(7 downto 0) := X"0E";
  constant KEY_1 			: std_logic_vector(7 downto 0) := X"16";
  constant KEY_2 			: std_logic_vector(7 downto 0) := X"1E";
  constant KEY_3 			: std_logic_vector(7 downto 0) := X"26";
  constant KEY_4 			: std_logic_vector(7 downto 0) := X"25";
  constant KEY_5 			: std_logic_vector(7 downto 0) := X"2E";
  constant KEY_6 			: std_logic_vector(7 downto 0) := X"36";
  constant KEY_7 			: std_logic_vector(7 downto 0) := X"3D";
  constant KEY_8 			: std_logic_vector(7 downto 0) := X"3E";
  constant KEY_9 			: std_logic_vector(7 downto 0) := X"46";
  constant KEY_0 			: std_logic_vector(7 downto 0) := X"45";
  constant KEY_APOS 		: std_logic_vector(7 downto 0) := X"4E";
  constant KEY_AEXC 		: std_logic_vector(7 downto 0) := X"55";
  constant KEY_BKSP 		: std_logic_vector(7 downto 0) := X"66";

  constant KEY_TAB 		: std_logic_vector(7 downto 0) := X"0D";
  constant KEY_Q 			: std_logic_vector(7 downto 0) := X"15";
  constant KEY_W 			: std_logic_vector(7 downto 0) := X"1D";
  constant KEY_E 			: std_logic_vector(7 downto 0) := X"24";
  constant KEY_R 			: std_logic_vector(7 downto 0) := X"2D";
  constant KEY_T 			: std_logic_vector(7 downto 0) := X"2C";
  constant KEY_Y 			: std_logic_vector(7 downto 0) := X"35";
  constant KEY_U 			: std_logic_vector(7 downto 0) := X"3C";
  constant KEY_I 			: std_logic_vector(7 downto 0) := X"43";
  constant KEY_O 			: std_logic_vector(7 downto 0) := X"44";
  constant KEY_P 			: std_logic_vector(7 downto 0) := X"4D";
  constant KEY_CORCHA 	: std_logic_vector(7 downto 0) := X"54";
  constant KEY_CORCHC 	: std_logic_vector(7 downto 0) := X"5B";
  constant KEY_ENTER 	: std_logic_vector(7 downto 0) := X"5A";

  constant KEY_CPSLK 	: std_logic_vector(7 downto 0) := X"58";
  constant KEY_A 			: std_logic_vector(7 downto 0) := X"1C";
  constant KEY_S 			: std_logic_vector(7 downto 0) := X"1B";
  constant KEY_D 			: std_logic_vector(7 downto 0) := X"23";
  constant KEY_F 			: std_logic_vector(7 downto 0) := X"2B";
  constant KEY_G 			: std_logic_vector(7 downto 0) := X"34";
  constant KEY_H 			: std_logic_vector(7 downto 0) := X"33";
  constant KEY_J 			: std_logic_vector(7 downto 0) := X"3B";
  constant KEY_K 			: std_logic_vector(7 downto 0) := X"42";
  constant KEY_L 			: std_logic_vector(7 downto 0) := X"4B";
  constant KEY_NT 		: std_logic_vector(7 downto 0) := X"4C";
  constant KEY_LLAVA 	: std_logic_vector(7 downto 0) := X"52";
  constant KEY_LLAVC 	: std_logic_vector(7 downto 0) := X"5D";

  constant KEY_LSHIFT	: std_logic_vector(7 downto 0) := X"12";
  constant KEY_LT 		: std_logic_vector(7 downto 0) := X"61";
  constant KEY_Z 			: std_logic_vector(7 downto 0) := X"1A";
  constant KEY_X 			: std_logic_vector(7 downto 0) := X"22";
  constant KEY_C 			: std_logic_vector(7 downto 0) := X"21";
  constant KEY_V 			: std_logic_vector(7 downto 0) := X"2A";
  constant KEY_B 			: std_logic_vector(7 downto 0) := X"32";
  constant KEY_N 			: std_logic_vector(7 downto 0) := X"31";
  constant KEY_M 			: std_logic_vector(7 downto 0) := X"3A";
  constant KEY_COMA 		: std_logic_vector(7 downto 0) := X"41";
  constant KEY_PUNTO 	: std_logic_vector(7 downto 0) := X"49";
  constant KEY_MENOS 	: std_logic_vector(7 downto 0) := X"4A";
  constant KEY_RSHIFT	: std_logic_vector(7 downto 0) := X"59";

  constant KEY_CTRLI 	: std_logic_vector(7 downto 0) := X"14";
  constant KEY_ALTI 		: std_logic_vector(7 downto 0) := X"11";
  constant KEY_SPACE 	: std_logic_vector(7 downto 0) := X"29";

  constant KEY_KP0 		: std_logic_vector(7 downto 0) := X"70";
  constant KEY_KP1 		: std_logic_vector(7 downto 0) := X"69";
  constant KEY_KP2 		: std_logic_vector(7 downto 0) := X"72";
  constant KEY_KP3 		: std_logic_vector(7 downto 0) := X"7A";
  constant KEY_KP4 		: std_logic_vector(7 downto 0) := X"6B";
  constant KEY_KP5 		: std_logic_vector(7 downto 0) := X"73";
  constant KEY_KP6 		: std_logic_vector(7 downto 0) := X"74";
  constant KEY_KP7 		: std_logic_vector(7 downto 0) := X"6C";
  constant KEY_KP8 		: std_logic_vector(7 downto 0) := X"75";
  constant KEY_KP9 		: std_logic_vector(7 downto 0) := X"7D";
  constant KEY_KPPUNTO 	: std_logic_vector(7 downto 0) := X"71";
  constant KEY_KPMAS 	: std_logic_vector(7 downto 0) := X"79";
  constant KEY_KPMENOS 	: std_logic_vector(7 downto 0) := X"7B";
  constant KEY_KPASTER 	: std_logic_vector(7 downto 0) := X"7C";

  constant KEY_BLKNUM	: std_logic_vector(7 downto 0) := X"77";
  constant KEY_BLKSCR 	: std_logic_vector(7 downto 0) := X"7E";

-- Teclas con E0 + scancode
  constant KEY_WAKEUP 	: std_logic_vector(7 downto 0) := X"5E";
  constant KEY_SLEEP 	: std_logic_vector(7 downto 0) := X"3F";
  constant KEY_POWER 	: std_logic_vector(7 downto 0) := X"37";
  constant KEY_INS 		: std_logic_vector(7 downto 0) := X"70";
  constant KEY_SUP 		: std_logic_vector(7 downto 0) := X"71";
  constant KEY_HOME 		: std_logic_vector(7 downto 0) := X"6C";
  constant KEY_END 		: std_logic_vector(7 downto 0) := X"69";
  constant KEY_PGU 		: std_logic_vector(7 downto 0) := X"7D";
  constant KEY_PGD 		: std_logic_vector(7 downto 0) := X"7A";
  constant KEY_UP 		: std_logic_vector(7 downto 0) := X"75";
  constant KEY_DOWN 		: std_logic_vector(7 downto 0) := X"72";
  constant KEY_LEFT 		: std_logic_vector(7 downto 0) := X"6B";
  constant KEY_RIGHT 	: std_logic_vector(7 downto 0) := X"74";
  constant KEY_CTRLD 	: std_logic_vector(7 downto 0) := X"14";
  constant KEY_ALTGR 	: std_logic_vector(7 downto 0) := X"11";
  constant KEY_KPENTER 	: std_logic_vector(7 downto 0) := X"5A";
  constant KEY_KPSLASH 	: std_logic_vector(7 downto 0) := X"4A";
  constant KEY_PRTSCR 	: std_logic_vector(7 downto 0) := X"7C";

end package mapa_es;

package body mapa_es is
end package body mapa_es;