library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity keyboard is
    port (
        ps2_clk    : in  std_logic;
        ps2_data   : in  std_logic;
		  clk        : in  std_logic;
        rst_n      : in  std_logic;
		  readd		: in std_logic;
		  K        : out unsigned(7 downto 0);
		  scanSW		:	out	std_logic_vector(3 downto 0);
		  imageCount : out unsigned(7 downto 0);
		  AReset : out std_logic
        );
end entity;

architecture rtl of keyboard is

    type   key_matrix is array(0 to 13) of std_logic_vector(3 downto 0);
    signal keys       : key_matrix;
    signal release    : std_logic;
    signal extended   : std_logic;

    signal keyb_data  : std_logic_vector(7 downto 0);
    signal keyb_valid : std_logic;
    signal keyb_error : std_logic;
    
	 signal CTRL	: std_logic;
	 signal ALT		: std_logic;
	 signal SHIFT	: std_logic;
	 signal VIDEO	: std_logic;
	 signal SCANL	: std_logic;
	 signal VMODE	: std_logic;
	 
	 signal ascii      : unsigned(7 downto 0);  -- decoded
	 
	 signal inList		: std_logic := '0';
    
begin
  
    ps2 : entity work.ps2_intf port map (
        CLK      => clk,
        nRESET   => rst_n,
        PS2_CLK  => ps2_clk,
        PS2_DATA => ps2_data,
        DATA     => keyb_data,
        VALID    => keyb_valid,
        error    => keyb_error
    );
	 
		 K <= inList & "00" & ascii(4 downto 0) when CTRL = '1' else
			 inList & ascii(6 downto 0);

    process(clk, rst_n)
    begin
        if rst_n = '0' then

            release  <= '0';
            extended <= '0';

        elsif rising_edge(clk) then
		  
				if readd = '1' then 
					inList <= '0'; 
				end if; --q
                    
            if keyb_valid = '1' then
                if keyb_data = X"e0" then
                    extended <= '1';
                elsif keyb_data = X"f0" then
                    release <= '1';
						  inList <= '0';
                else
                    release  <= '0';
                    extended <= '0';
                    
                    case keyb_data is
							 --disk slot insertion (up to 20 images)
                        when X"05" => if SHIFT = '0' then imageCount <= X"00"; -- F1
										else imageCount <= X"0A"; end if; inList <= '0'; -- SHIFT F1 
                        when X"06" => if SHIFT = '0' then imageCount <= X"01"; -- F2
										else imageCount <= X"0B"; end if; inList <= '0'; -- SHIFT F2 
                        when X"04" => if SHIFT = '0' then imageCount <= X"02"; -- F3
										else imageCount <= X"0C"; end if; inList <= '0'; -- SHIFT F3 
                        when X"0C" => if SHIFT = '0' then imageCount <= X"03"; -- F4
										else imageCount <= X"0D"; end if; inList <= '0'; -- SHIFT F4 
                        when X"03" => if SHIFT = '0' then imageCount <= X"04"; -- F5
										else imageCount <= X"0E"; end if; inList <= '0'; -- SHIFT F5 
                        when X"0B" => if SHIFT = '0' then imageCount <= X"05"; -- F6
										else imageCount <= X"0F"; end if; inList <= '0'; -- SHIFT F6 
                        when X"83" => if SHIFT = '0' then imageCount <= X"06"; -- F7
										else imageCount <= X"10"; end if; inList <= '0'; -- SHIFT F7 
                        when X"0A" => if SHIFT = '0' then imageCount <= X"07"; -- F8
										else imageCount <= X"11"; end if; inList <= '0'; -- SHIFT F8 
                        when X"01" => if SHIFT = '0' then imageCount <= X"08"; -- F9
										else imageCount <= X"12"; end if; inList <= '0'; -- SHIFT F9 
                        when X"09" => if SHIFT = '0' then imageCount <= X"09"; -- F10
										else imageCount <= X"13"; end if; inList <= '0'; -- SHIFT F10 
								
                        when X"07" => AReset <= not release; inList <= '0';	-- F12 reset								
								
								when X"11" => ALT   <= not release;  inList <= '0'; -- ALT
								when X"14" => CTRL  <= not release;  inList <= '0'; -- CTRL
								when X"59" => SHIFT <= not release;  inList <= '0'; -- RSHIFT
								when X"12" => SHIFT <= not release;  inList <= '0'; -- LSHIFT
									   							                     
                        when X"74" => ascii <= X"15"; inList <= not release;  -- RIGHT           
                        when X"6B" => ascii <= X"08"; inList <= not release;  -- LEFT
                        when X"72" => ascii <= X"0a"; inList <= not release;  -- DOWN
                        when X"75" => ascii <= X"0b"; inList <= not release;  -- UP
                        when X"5A" => ascii <= X"0d"; inList <= not release;  -- RETURN
                        when X"66" => if (CTRL = '1' and ALT = '1') then		-- MASTER RESET
														scanSW(0) <= not release; inList <= '0';
												  else
													ascii <= X"08"; inList <= not release; -- BACKSPACE (DELETE)
												  end if; 													
                        when X"0D" => ascii <= X"09"; inList <= not release;  -- HORIZ TAB
								when X"29" => ascii <= X"20"; inList <= not release;  -- SPACE
                        when X"4E" => if SHIFT = '0' then ascii <= X"2d";   	-- -  
								 else ascii <= X"5f"; end if; inList <= not release;  --- _								
                        when X"0E" => if SHIFT = '0' then ascii <= X"60";   	-- `  
								 else ascii <= X"7e"; end if; inList <= not release;  --- ~								
                        when X"54" => if SHIFT = '0' then ascii <= X"5b";   	-- [ 
								 else ascii <= X"7b"; end if; inList <= not release;  --- {
								when X"5B" => if SHIFT = '0' then ascii <= X"5d";  	-- ]
								 else ascii <= X"7d"; end if; inList <= not release;  --- }
                        when X"52" => if SHIFT = '0' then ascii <= X"27";   	-- '
								 else ascii <= X"22"; end if; inList <= not release;  --- "        
                        when X"4D" => if SHIFT = '0' then ascii <= X"50";   	-- P
								 else ascii <= X"40"; end if; inList <= not release;  --- @
                        when X"4C" => if SHIFT = '0' then ascii <= X"3b";   	-- ;
								 else ascii <= X"3a"; end if; inList <= not release;  --- :								 
                        when X"4A" => if SHIFT = '0' then ascii <= X"2f";   	-- /
								 else ascii <= X"3f"; end if; inList <= not release;  --- ?
                        when X"55" => if SHIFT = '0' then ascii <= X"3d";   	-- =
								 else ascii <= X"2b"; end if; inList <= not release;  --- +								 
                        when X"44" => ascii <= X"4f"; inList <= not release;  -- O
                        when X"4B" => ascii <= X"4c"; inList <= not release;  -- L
                        when X"49" => if SHIFT = '0' then ascii <= X"2e";   	-- .
								 else ascii <= X"3e"; end if; inList <= not release;  --- >	                                            
                        when X"43" => ascii <= X"49"; inList <= not release;  -- I
                        when X"42" => ascii <= X"4b"; inList <= not release;  -- K
                        when X"41" => if SHIFT = '0' then ascii <= X"2c";   	-- ,
								 else ascii <= X"3c"; end if; inList <= not release;  --- <	                   
                        when X"3C" => ascii <= X"55"; inList <= not release;  -- U
                        when X"3B" => ascii <= X"4a"; inList <= not release;  -- J                                       
                        when X"3A" => ascii <= X"4d"; inList <= not release;  -- M              
                        when X"35" => ascii <= X"59"; inList <= not release;  -- Y
                        when X"33" => ascii <= X"48"; inList <= not release;  -- H                                      
                        when X"31" => ascii <= X"4e"; inList <= not release;  -- N                                         
                        when X"2C" => ascii <= X"54"; inList <= not release;  -- T
                        when X"34" => ascii <= X"47"; inList <= not release;  -- G
                        when X"32" => ascii <= X"42"; inList <= not release;  -- B    
                        when X"2D" => ascii <= X"52"; inList <= not release;  -- R
                        when X"2B" => ascii <= X"46"; inList <= not release;  -- F
                        when X"2A" => ascii <= X"56"; inList <= not release;  -- V                      
                        when X"24" => ascii <= X"45"; inList <= not release;  -- E       
                        when X"23" => ascii <= X"44"; inList <= not release;  -- D
                        when X"21" => ascii <= X"43"; inList <= not release;  -- C       
                        when X"1D" => ascii <= X"57"; inList <= not release;  -- W
                        when X"1B" => ascii <= X"53"; inList <= not release;  -- S
                        when X"22" => ascii <= X"58"; inList <= not release;  -- X
								when X"45" => if SHIFT = '0' then ascii <= X"30";   	-- 0
								 else ascii <= X"29"; end if; inList <= not release;  --- )
                        when X"16" => if SHIFT = '0' then ascii <= X"31"; 		-- 1
								 else ascii <= X"21"; end if; inList <= not release;  --- !
								when X"1E" => if SHIFT = '0' then ascii <= X"32"; 		-- 2
								 else ascii <= X"40"; end if; inList <= not release;  --- @
								when X"26" => if SHIFT = '0' then ascii <= X"33";     -- 3
								 else ascii <= X"23"; end if; inList <= not release;  --- #
								when X"25" => if SHIFT = '0' then ascii <= X"34";   	-- 4
								 else ascii <= X"24"; end if; inList <= not release;  --- $
								when X"2E" => if SHIFT = '0' then ascii <= X"35";  	-- 5 
								 else ascii <= X"25"; end if; inList <= not release;  --- %
								when X"36" => if SHIFT = '0' then ascii <= X"36";   	-- 6
								 else ascii <= X"5e"; end if; inList <= not release;  --- &
								when X"3D" => if SHIFT = '0' then ascii <= X"37";    -- 7
								 else ascii <= X"26"; end if; inList <= not release;  --- '
								when X"3E" => if SHIFT = '0' then ascii <= X"38";   	-- 8
								 else ascii <= X"2a"; end if; inList <= not release;  --- *
                        when X"46" => if SHIFT = '0' then ascii <= X"39";   	-- 9	
								 else ascii <= X"28"; end if; inList <= not release;  --- (
                        when X"15" => ascii <= X"51"; inList <= not release;  -- Q
                        when X"1C" => ascii <= X"41"; inList <= not release;  -- A
                        when X"1A" => ascii <= X"5a"; inList <= not release;  -- Z
                        when X"76" => ascii <= X"1b"; inList <= not release;  -- ESCAPE
                        when X"71" => ascii <= X"7f"; inList <= not release;  -- DEL
								
								when X"7E" => 										 			-- scrolLock RGB/VGA
										if (VIDEO = '0' and release = '0') then		-- NOT impplemented YET
											scanSW(1) <= '1';	VIDEO <= '1';
										elsif (VIDEO = '1' and release = '0') then
											scanSW(1) <= '0';	VIDEO <= '0';
										end if;		
										inList <= '0';
										
								when X"7B" => 										 			-- "-" Scanlines
										if (SCANL = '0' and release = '0') then
											scanSW(2) <= '1';	SCANL <= '1';
										elsif (SCANL = '1' and release = '0') then
											scanSW(2) <= '0';	SCANL <= '0';
										end if;		
										inList <= '0';				

								when X"7C" => 										 			-- "*" Mode COLOR / B&W
										if (VMODE = '0' and release = '0') then
											scanSW(3) <= '1';	VMODE <= '1';
										elsif (VMODE = '1' and release = '0') then
											scanSW(3) <= '0';	VMODE <= '0';
										end if;		
										inList <= '0';											

                        when others => inList <= '0'; 
                    end case;
  
                end if;
            end if;
        end if;
    end process;
    
end architecture;
