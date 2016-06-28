-------------------------------------------------------------------
-- minimalDVID_encoder.vhd : A quick and dirty DVI-D implementation
--
-- Author: Mike Field <hamster@snap.net.nz>
--
-- DVI-D uses TMDS as the 'on the wire' protocol, where each 8-bit
-- value is mapped to one or two 10-bit symbols, depending on how
-- many 1s or 0s have been sent. This makes it a DC balanced protocol,
-- as a correctly implemented stream will have (almost) an equal 
-- number of 1s and 0s. 
--
-- Because of this implementation quite complex. By restricting the 
-- symbols to a subset of eight symbols, all of which having have 
-- five ones (and therefore five zeros) this complexity drops away
-- leaving a simple implementation. Combined with a DDR register to 
-- send the symbols the complexity is kept very low.
--
-------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity MinimalDVID_encoder is
    Port ( clk                   : in  STD_LOGIC;
           hsync,  vsync,  blank : in  STD_LOGIC;
           red,    green,  blue  : in  STD_LOGIC_VECTOR (2 downto 0);
           hdmi_p, hdmi_n        : out STD_LOGIC_VECTOR (3 downto 0));
end MinimalDVID_encoder;

architecture Behavioral of MinimalDVID_encoder is
   type a_symbols     is array (0 to 3) of std_logic_vector(9 downto 0);
   type a_colours     is array (0 to 2) of std_logic_vector(2 downto 0);
--   type a_ctls        is array (0 to 2) of std_logic_vector(1 downto 0);
   type a_output_bits is array (0 to 3) of std_logic_vector(1 downto 0);

   signal symbols        : a_symbols     := (others => (others => '0'));
   signal high_speed_sr  : a_symbols     := (others => (others => '0'));
   signal colours        : a_colours     := (others => (others => '0'));
--   signal ctls           : a_ctls        := (others => (others => '0'));
   signal output_bits    : a_output_bits := (others => (others => '0'));
	
	signal ctls:	 std_logic_vector(1 downto 0); --Q
   
   -- Controlling when the transfers into the high speed domain occur
   signal latch_high_speed : std_logic_vector(4 downto 0) := "00001";
   
   -- The signals from the DDR outputs to the output buffers
   signal serial_outputs : std_logic_vector(3 downto 0);

   -- For generating the x5 clocks
   signal clk_x5,  clk_x5_unbuffered  : std_logic;
   signal clk_feedback    : std_logic;

begin
   ctls <= vsync & hsync; -- syncs are set in the channel 0 CTL periods

   colours(0) <= blue;
   colours(1) <= green;
   colours(2) <= red;

   symbols(3) <= "0000011111"; -- the clock channel symbol is static

clk_proc: process(clk)
   begin
      if rising_edge(clk) then
         for i in 0 to 2 loop
            if blank = '1' then
               case ctls is 
                  when "00"   => symbols(i) <= "1101010100";
                  when "01"   => symbols(i) <= "0010101011";
                  when "10"   => symbols(i) <= "0101010100";
                  when others => symbols(i) <= "1010101011";      
               end case;
            else
               case colours(i) is 
                  ---  Colour                   TMDS symbol   Value 
                  when "000"  => symbols(i) <= "0111110000"; -- 0x10
                  when "001"  => symbols(i) <= "0001001111"; -- 0x2F
                  when "010"  => symbols(i) <= "0111001100"; -- 0x54
                  when "011"  => symbols(i) <= "0010001111"; -- 0x6F
                  when "100"  => symbols(i) <= "0000101111"; -- 0x8F
                  when "101"  => symbols(i) <= "1000111001"; -- 0xB4
                  when "110"  => symbols(i) <= "1000011011"; -- 0xD2
                  when others => symbols(i) <= "1011110000"; -- 0xEF
               end case;
            end if;
         end loop;
       end if;
   end process;

process(clk_x5)
   begin
      ---------------------------------------------------------------
      -- Now take the 10-bit words and take it into the high-speed
      -- clock domain once every five cycles. 
      -- 
      -- Then send out two bits every clock cycle using DDR output
      -- registers.
      ---------------------------------------------------------------   
      if rising_edge(clk_x5) then
         for i in 0 to 3 loop
            output_bits(i)  <= high_speed_sr(i)(1 downto 0);
            if latch_high_speed(0) = '1' then
               high_speed_sr(i) <= symbols(i);
            else
               high_speed_sr(i) <= "00" & high_speed_sr(i)(9 downto 2);
            end if;
         end loop;
         latch_high_speed <= latch_high_speed(0) & latch_high_speed(4 downto 1);
      end if;
   end process;

g1:   for i in 0 to 3 generate
   --------------------------------------------------------
   -- Convert the TMDS codes into a serial stream, two bits 
   -- at a time using a DDR register
   --------------------------------------------------------
      to_serial: ODDR2
         generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") 
         port map (C0 => clk_x5,  C1 => not clk_x5, CE => '1', R => '0', S => '0',
                   D0 => output_bits(i)(0), D1 => output_bits(i)(1), Q => serial_outputs(i));
      OBUFDS_c0  : OBUFDS port map ( O  => hdmi_p(i), OB => hdmi_n(i), I => serial_outputs(i));
   end generate;
    
   ------------------------------------------------------------------
   -- Use a PLL to generate a x5 clock, which is used to drive 
   -- the DDR registers.This allows 10 bits to be sent for every 
   -- pixel clock
   ------------------------------------------------------------------
PLL_BASE_inst : PLL_BASE generic map (
      CLKFBOUT_MULT => 10,                  
      CLKOUT0_DIVIDE => 2,
      CLKOUT0_PHASE => 0.0,   -- Output 5x original frequency
      CLK_FEEDBACK => "CLKFBOUT",
      CLKIN_PERIOD => 13.33,
      DIVCLK_DIVIDE => 1
   ) port map (
      CLKFBOUT => clk_feedback, 
      CLKOUT0  => clk_x5_unbuffered,
      CLKFBIN  => clk_feedback,    
      CLKIN    => clk, 
      RST      => '0'
   );

BUFG_pclkx5  : BUFG port map ( I => clk_x5_unbuffered,  O => clk_x5);

end Behavioral;
