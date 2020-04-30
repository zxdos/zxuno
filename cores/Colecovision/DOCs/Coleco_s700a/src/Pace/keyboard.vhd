library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.kbd_pkg.all;

entity colecoKeyboard is
port
(
    clk       	: in     std_logic;
    reset     	: in     std_logic;

		-- inputs from PS/2 port
    ps2_clk  		: inout  std_logic;                            
    ps2_data 		: inout  std_logic;                            

    -- user outputs
		keys				: out    std_logic_vector(15 downto 0);
		joy					: out		 std_logic_vector(15 downto 0)
);
end colecoKeyboard;

architecture SYN of colecoKeyboard is

  component ps2kbd                                          
    port
    (
      clk      : in  std_logic;                            
      rst_n    : in  std_logic;                            
      tick1us  : in  std_logic;
      ps2_clk  : in  std_logic;                            
      ps2_data : in  std_logic;                            

      reset    : out std_logic;                            
      press    : out std_logic;                            
      release  : out std_logic;                            
      scancode : out std_logic_vector(7 downto 0)
    );
  end component;

  signal rst_n			: std_logic;

  -- 1us tick for PS/2 interface
  signal tick1us		: std_logic;

  signal ps2_reset      : std_logic;
  signal ps2_press      : std_logic;
  signal ps2_release    : std_logic;
  signal ps2_scancode   : std_logic_vector(7 downto 0);

begin

	rst_n <= not reset;
	
	-- produce a 1us tick from the 20MHz ref clock
  process (clk, reset)
		variable count : integer range 0 to 19;
	begin
	  if reset = '1' then
			tick1us <= '0';
			count := 0;
	  elsif rising_edge (clk) then
			if count = 19 then
		  	tick1us <= '1';
		  	count := 0;
			else
		  	tick1us <= '0';
		  	count := count + 1;
			end if;
	  end if;
	end process;
	
    latchInputs: process (clk, rst_n)

    begin

         -- note: all inputs are active HIGH

        if rst_n = '0' then
           keys <= (others => '0');
           joy <= (others => '0');
        elsif rising_edge (clk) then
          if (ps2_press or ps2_release) = '1' then
               case ps2_scancode is

						-- this is not a valid scancode
						-- but stuff the right button in here
						  when SCANCODE_X =>
                         keys(0) <= ps2_press;
                    when SCANCODE_8 =>
                         keys(1) <= ps2_press;
                    when SCANCODE_4 =>
                         keys(2) <= ps2_press;
                    when SCANCODE_5 =>
                         keys(3) <= ps2_press;
                    when SCANCODE_7 =>
                         keys(5) <= ps2_press;
                    when SCANCODE_Q =>						-- '#'
                         keys(6) <= ps2_press;
                    when SCANCODE_2 =>
                         keys(7) <= ps2_press;
                    when SCANCODE_W =>						-- '*'
                         keys(9) <= ps2_press;
                    when SCANCODE_0 =>
                         keys(10) <= ps2_press;
                    when SCANCODE_9 =>
                         keys(11) <= ps2_press;
                    when SCANCODE_3 =>
                         keys(12) <= ps2_press;
                    when SCANCODE_1 =>
                         keys(13) <= ps2_press;
                    when SCANCODE_6 =>
                         keys(14) <= ps2_press;
							
------------------------------------------------ 						
						  when SCANCODE_ESC =>  -- soft reset key : ESC
                         keys(8) <= ps2_press;
-------------------------------------------------	
                    when SCANCODE_UP =>
                         joy(0) <= ps2_press;
                    when SCANCODE_DOWN =>
                         joy(1) <= ps2_press;
                    when SCANCODE_LEFT =>
                         joy(2) <= ps2_press;
                    when SCANCODE_RIGHT =>
                         joy(3) <= ps2_press;
                    when SCANCODE_Z =>
                         joy(4) <= ps2_press;

                    when others =>
               end case;
            end if; -- ps2_press or release
            if (ps2_reset = '1') then
               keys <= (others => '0');
               joy <= (others => '0');
            end if;
        end if; -- rising_edge (clk)
    end process latchInputs;

  ps2kbd_inst : ps2kbd                                        
    port map
    (
      clk      	=> clk,                                     
      rst_n    	=> rst_n,
      tick1us  	=> tick1us,
      ps2_clk  	=> ps2_clk,
      ps2_data 	=> ps2_data,

      reset    	=> ps2_reset,
      press 	=> ps2_press,
      release  	=> ps2_release,
      scancode 	=> ps2_scancode
    );

end SYN;
