library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

  entity Pointer is
  port ( 
         CLK  : in  std_logic;
         PO   : in  std_logic;
         PS   : in  std_logic_vector (4 downto 0);
         X    : in  std_logic_vector (7 downto 0);
         Y    : in  std_logic_vector (7 downto 0);
         ADDR : in  std_logic_vector (12 downto 0);
         DIN  : in  std_logic_vector (7 downto 0);
         DOUT : out std_logic_vector (7 downto 0)
         );
  end Pointer;

  architecture Behavioral of Pointer is

    signal xrel   : std_logic_vector (5 downto 0);
    signal yrel   : std_logic_vector (7 downto 0);
    signal addrb  : std_logic_vector (7 downto 0);
    signal black  : std_logic_vector (7 downto 0);
    signal white  : std_logic_vector (7 downto 0);
    signal sblack : std_logic_vector (15 downto 0);
    signal swhite : std_logic_vector (15 downto 0);

	COMPONENT PointerRamBlack
	PORT(
		clka : IN std_logic;
		wea : IN std_logic;
		addra : IN std_logic_vector(7 downto 0);
		dina : IN std_logic_vector(7 downto 0);
		clkb : IN std_logic;
		web : IN std_logic;
		addrb : IN std_logic_vector(7 downto 0);
		dinb : IN std_logic_vector(7 downto 0);          
		douta : OUT std_logic_vector(7 downto 0);
		doutb : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
    
	COMPONENT PointerRamWhite
	PORT(
		clka : IN std_logic;
		wea : IN std_logic;
		addra : IN std_logic_vector(7 downto 0);
		dina : IN std_logic_vector(7 downto 0);
		clkb : IN std_logic;
		web : IN std_logic;
		addrb : IN std_logic_vector(7 downto 0);
		dinb : IN std_logic_vector(7 downto 0);          
		douta : OUT std_logic_vector(7 downto 0);
		doutb : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;    


    
   begin
    xrel  <= ('1' & ADDR(4 downto 0)) - ('0' & X(7 downto 3));
    yrel  <= ADDR(12 downto 5) - Y;
    addrb <= PS & yrel(2 downto 0);
    
 	Inst_PointerRamBlack: PointerRamBlack PORT MAP(
		clka => CLK,
		wea => '0',
		addra => (others => '0'),
		dina => (others => '0'),
		douta => open,
		clkb => CLK,
		web => '0',
		addrb => addrb,
		dinb => (others => '0'),
		doutb => black
	);

	Inst_PointerRamWhite: PointerRamWhite PORT MAP(
		clka => CLK,
		wea => '0',
		addra => (others => '0'),
		dina => (others => '0'),
		douta => open,
		clkb => CLK,
		web => '0',
		addrb => addrb,
		dinb => (others => '0'),
		doutb => white
	);    
   
--    process(yrel)
--    begin
--        case yrel(2 downto 0) is
--          when "000" =>
--              black <= "11111111";
--              white <= "00000000";
--          when "001" =>
--              black <= "10000010";
--              white <= "01111100";
--          when "010" =>
--              black <= "10000100";
--              white <= "01111000";
--          when "011" =>
--              black <= "10000100";
--              white <= "01111000";
--          when "100" =>
--              black <= "10000010";
--              white <= "01111100";
--          when "101" =>
--              black <= "10110001";
--              white <= "01001110";
--          when "110" =>
--              black <= "11001010";
--              white <= "00000100";
--          when others =>
--              black <= "10000100";              
--              white <= "00000000";              
--        end case;
--    end process;

    process(X, white, black)
    begin
        case X(2 downto 0) is
          when "000" =>
              swhite <=      white & "00000000";
              sblack <=      black & "00000000";
          when "001" =>
              swhite <= "0" & white & "0000000";
              sblack <= "0" & black & "0000000";
          when "010" =>
              swhite <= "00" & white & "000000";
              sblack <= "00" & black & "000000";
          when "011" =>
              swhite <= "000" & white & "00000";
              sblack <= "000" & black & "00000";
          when "100" =>
              swhite <= "0000" & white & "0000";
              sblack <= "0000" & black & "0000";
          when "101" =>
              swhite <= "00000" & white & "000";
              sblack <= "00000" & black & "000";
          when "110" =>
              swhite <= "000000" & white & "00";
              sblack <= "000000" & black & "00";
          when others =>
              swhite <= "0000000" & white & "0";
              sblack <= "0000000" & black & "0";
        end case;
    end process;

    dout <= (din and (sblack(15 downto 8) xor "11111111")) or swhite(15 downto 8) when PO = '1' and xrel = 32 and yrel < 8 else
            (din and (sblack(7 downto 0)  xor "11111111")) or swhite(7 downto 0)  when PO = '1' and xrel = 33 and yrel < 8 else
            din;
      
  end Behavioral;
