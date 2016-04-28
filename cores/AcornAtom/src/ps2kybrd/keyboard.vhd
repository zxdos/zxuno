library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity keyboard is
    port (
        CLOCK      : in  std_logic;
        nRESET     : in  std_logic;
        CLKEN_1MHZ : in  std_logic;
        PS2_CLK    : in  std_logic;
        PS2_DATA   : in  std_logic;
        KEYOUT     : out std_logic_vector(5 downto 0);
        ROW        : in  std_logic_vector(3 downto 0);
        ESC_IN     : in  std_logic;        
        BREAK_IN   : in  std_logic;        
        SHIFT_OUT  : out std_logic;
        CTRL_OUT   : out std_logic;
        REPEAT_OUT : out std_logic;
        BREAK_OUT  : out std_logic;
        TURBO      : out std_logic_vector(1 downto 0);
        ESC_OUT    : out std_logic;
        Joystick1  : in  std_logic_vector (7 downto 0)
--      ;  Joystick2  : in  std_logic_vector (7 downto 0)        
        );
end entity;

architecture rtl of keyboard is
    component ps2_intf is
        generic (filter_length : positive := 8);
        port(
            CLK      : in  std_logic;
            nRESET   : in  std_logic;
            PS2_CLK  : in  std_logic;
            PS2_DATA : in  std_logic;
            DATA     : out std_logic_vector(7 downto 0);
            VALID    : out std_logic;
            error    : out std_logic
            );
    end component;

    signal keyb_data  : std_logic_vector(7 downto 0);
    signal keyb_valid : std_logic;
    signal keyb_error : std_logic;
    type   key_matrix is array(0 to 15) of std_logic_vector(7 downto 0);
    signal keys       : key_matrix;
    signal col        : unsigned(3 downto 0);
    signal release    : std_logic;
    signal extended   : std_logic;
    signal key_data   : std_logic_vector(7 downto 0);
    signal ESC_IN1    : std_logic;
    signal BREAK_IN1  : std_logic;

begin
    ps2 : ps2_intf port map (
        CLOCK,
        nRESET,
        PS2_CLK,
        PS2_DATA,
        keyb_data,
        keyb_valid,
        keyb_error);

    process(keys, ROW)
    begin
        key_data <= keys(conv_integer(ROW(3 downto 0)));
		  KEYOUT   <= key_data(5 downto 0); --Q
--        -- 0 U R D L F
--        if (ROW = "0000") then
--            KEYOUT <= key_data(5 downto 0) and
--                ('1' & Joystick1(0) & Joystick1(3) & Joystick1(1) & Joystick1(2) & Joystick1(5));
--        elsif (ROW = "0001") then
--            KEYOUT <= key_data(5 downto 0) and
--                ('1' & Joystick2(0) & Joystick2(3) & Joystick2(1) & Joystick2(2) & Joystick2(5));
--        else
--            KEYOUT <= key_data(5 downto 0);
--        end if;
    end process;

    process(CLOCK, nRESET)
    begin
        if nRESET = '0' then
            release  <= '0';
            extended <= '0';
            TURBO    <= "00";

            BREAK_OUT  <= '1';
            SHIFT_OUT  <= '1';
            CTRL_OUT   <= '1';
            REPEAT_OUT <= '1';
            
            ESC_IN1 <= ESC_IN;
            BREAK_IN1 <= BREAK_IN;

            keys(0) <= (others => '1');
            keys(1) <= (others => '1');
            keys(2) <= (others => '1');
            keys(3) <= (others => '1');
            keys(4) <= (others => '1');
            keys(5) <= (others => '1');
            keys(6) <= (others => '1');
            keys(7) <= (others => '1');
            keys(8) <= (others => '1');
            keys(9) <= (others => '1');

            keys(10) <= (others => '1');
            keys(11) <= (others => '1');
            keys(12) <= (others => '1');
            keys(13) <= (others => '1');
            keys(14) <= (others => '1');
            keys(15) <= (others => '1');
        elsif rising_edge(CLOCK) then
        
            -- handle the escape key seperately, as it's value also depends on ESC_IN
            if keyb_valid = '1' and keyb_data = X"76" then
                keys(0)(5) <= release;
            elsif ESC_IN /= ESC_IN1 then
                keys(0)(5) <= ESC_IN;
            end if;

            ESC_IN1 <= ESC_IN;           
            -- handle the break key seperately, as it's value also depends on BREAK_IN
            if keyb_valid = '1' and keyb_data = X"09" then
                BREAK_OUT <= release;
            elsif BREAK_IN /= BREAK_IN1 then
                BREAK_OUT <= BREAK_IN;
            end if;
            BREAK_IN1 <= BREAK_IN;
            
            if keyb_valid = '1' then
                if keyb_data = X"e0" then
                    extended <= '1';
                elsif keyb_data = X"f0" then
                    release <= '1';
                else
                    release  <= '0';
                    extended <= '0';
                    
                    case keyb_data is
                        when X"05" => TURBO      <= "00";     -- F1 (1MHz)
                        when X"06" => TURBO      <= "01";     -- F2 (2MMz)
                        when X"04" => TURBO      <= "10";     -- F3 (4MHz)
                        when X"0C" => TURBO      <= "11";     -- F4 (8MHz)
--                        when X"09" => BREAK_OUT  <= release;  -- F10 (BREAK)
                        when X"11" => REPEAT_OUT <= release;  -- LEFT ALT (SHIFT LOCK)
                        when X"12" | X"59" =>
                            if (extended = '0') then -- Ignore fake shifts
                                SHIFT_OUT  <= release; -- Left SHIFT -- Right SHIFT
                            end if; 
                        when X"14" => CTRL_OUT   <= release;  -- LEFT/RIGHT CTRL (CTRL) 
                        -----------------------------------------------------
                        -- process matrix
                        -----------------------------------------------------
                        when X"29" => keys(9)(0) <= release;  -- SPACE
                        when X"54" => keys(8)(0) <= release;  -- [       
                        when X"5D" => keys(7)(0) <= release;  -- \    -- 5D   
                        when X"5B" => keys(6)(0) <= release;  -- ]
                        when X"0D" => keys(5)(0) <= release;  -- UP      
                        when X"58" => keys(4)(0) <= release;  -- CAPS LOCK                                       
                        when X"74" => keys(3)(0) <= release;  -- RIGHT           
                        when X"75" => keys(2)(0) <= release;  -- UP

                        when X"5A" => keys(6)(1) <= release;  -- RETURN
                        when X"69" => keys(5)(1) <= release;  -- END (COPY)
                        when X"66" => keys(4)(1) <= release;  -- BACKSPACE (DELETE)
                        when X"45" => keys(3)(1) <= release;  -- 0
                        when X"16" => keys(2)(1) <= release;  -- 1
                        when X"1E" => keys(1)(1) <= release;  -- 2
                        when X"26" => keys(0)(1) <= release;  -- 3

                        when X"25" => keys(9)(2) <= release;  -- 4
                        when X"2E" => keys(8)(2) <= release;  -- 5                                       
                        when X"36" => keys(7)(2) <= release;  -- 6
                        when X"3D" => keys(6)(2) <= release;  -- 7               
                        when X"3E" => keys(5)(2) <= release;  -- 8                               
                        when X"46" => keys(4)(2) <= release;  -- 9
                        when X"52" => keys(3)(2) <= release;  -- '   full colon substitute
                        when X"4C" => keys(2)(2) <= release;  -- ;
                        when X"41" => keys(1)(2) <= release;  -- ,       
                        when X"4E" => keys(0)(2) <= release;  -- -

                        when X"49" => keys(9)(3) <= release;  -- .
                        when X"4A" => keys(8)(3) <= release;  -- /
                        when X"55" => keys(7)(3) <= release;  -- @ (TAB)
                        when X"1C" => keys(6)(3) <= release;  -- A
                        when X"32" => keys(5)(3) <= release;  -- B
                        when X"21" => keys(4)(3) <= release;  -- C
                        when X"23" => keys(3)(3) <= release;  -- D
                        when X"24" => keys(2)(3) <= release;  -- E       
                        when X"2B" => keys(1)(3) <= release;  -- F
                        when X"34" => keys(0)(3) <= release;  -- G

                        when X"33" => keys(9)(4) <= release;  -- H
                        when X"43" => keys(8)(4) <= release;  -- I
                        when X"3B" => keys(7)(4) <= release;  -- J                                       
                        when X"42" => keys(6)(4) <= release;  -- K
                        when X"4B" => keys(5)(4) <= release;  -- L
                        when X"3A" => keys(4)(4) <= release;  -- M
                        when X"31" => keys(3)(4) <= release;  -- N
                        when X"44" => keys(2)(4) <= release;  -- O
                        when X"4D" => keys(1)(4) <= release;  -- P
                        when X"15" => keys(0)(4) <= release;  -- Q

                        when X"2D" => keys(9)(5) <= release;  -- R
                        when X"1B" => keys(8)(5) <= release;  -- S
                        when X"2C" => keys(7)(5) <= release;  -- T
                        when X"3C" => keys(6)(5) <= release;  -- U
                        when X"2A" => keys(5)(5) <= release;  -- V
                        when X"1D" => keys(4)(5) <= release;  -- W
                        when X"22" => keys(3)(5) <= release;  -- X
                        when X"35" => keys(2)(5) <= release;  -- Y       
                        when X"1A" => keys(1)(5) <= release;  -- Z
--                        when X"76" => keys(0)(5) <= release;  -- ESCAPE

                        when others => null;
                    end case;
                    
                end if;
            end if;
        end if;
    end process;
    
    ESC_OUT <= keys(0)(5);

end architecture;


