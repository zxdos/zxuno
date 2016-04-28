library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- 0x0  read data
-- 0x0  write data
-- 0x01 write dummy 0xff
-- 0x02 write dummy 0x00
-- 0x03 set cs
-- 0x04 clr cs 

entity SPI_Port is
  port (
    nRST    : in  std_logic;
    clk     : in  std_logic;
    enable  : in  std_logic;
    nwe     : in  std_logic;
    address : in  std_logic_vector (2 downto 0);
    datain  : in  std_logic_vector (7 downto 0);
    dataout : out std_logic_vector (7 downto 0);
    MISO    : in  std_logic;
    MOSI    : out std_logic;
    NSS     : out std_logic;
    SPICLK  : out std_logic
    );
end SPI_Port;

architecture Behavioral of SPI_Port is
  type STATE_TYPE is (init, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17);
  signal state     : STATE_TYPE;
  signal SerialOut : std_logic_vector(7 downto 0);
  signal SerialIn  : std_logic_vector(7 downto 0);
  signal count  : std_logic_vector(12 downto 0);
begin

--------------------------------------------------------------
-- Process Copies SPI port word to appropriate ctrl register
--------------------------------------------------------------
  SPIport : process (nRST, clk, SerialOut, SerialIn)
  begin

    if nRST = '0' then

      state     <= init;
      NSS       <= '1';
      MOSI      <= '1';
      SPICLK    <= '0';
      SerialOut <= (others => '1');
      count     <= (others => '0');
      
    elsif rising_edge(clk) then
    
      if (state = init) then
        if (count = 5663) then -- 88 * 64 + 31
           state  <= s0;
           SPICLK <= '0';
           NSS    <= '0';
        else
           SPICLK <= count(5); -- 250 KHz
           count <= count + 1;
        end if;
        
      elsif enable = '1' and nwe = '0' then

        if address = "010" then
          SerialOut <= (others => '0');
          state <= s1;
        elsif address = "001" then
          SerialOut <= (others => '1');
          state <= s1;
        elsif address = "000" then
          SerialOut <= datain;
          state <= s1;
        elsif address = "011" then
          NSS <= '1';
        elsif address = "100" then
          NSS <= '0';          
        elsif address = "101" then
          SPICLK <= '1';
        elsif address = "110" then
          SPICLK <= '0';
        elsif address = "111" then
          state     <= init;
          NSS       <= '1';
          MOSI      <= '1';
          SPICLK    <= '0';
          SerialOut <= (others => '1');
          count     <= (others => '0');
        end if;
        
      else
        case state is                   -- Address state machine
          when s1     => state <= s2; SPICLK <= '0'; MOSI <= SerialOut(7);
          when s2     => state <= s3; SPICLK <= '1';
          when s3     => state <= s4; SPICLK <= '0'; MOSI <= SerialOut(6); SerialIn(7) <= MISO;  --SerialIn
          when s4     => state <= s5; SPICLK <= '1';
          when s5     => state <= s6; SPICLK <= '0'; MOSI <= SerialOut(5); SerialIn(6) <= MISO;
          when s6     => state <= s7; SPICLK <= '1';
          when s7     => state <= s8; SPICLK <= '0'; MOSI <= SerialOut(4); SerialIn(5) <= MISO;
          when s8     => state <= s9; SPICLK <= '1';
          when s9     => state <= s10; SPICLK <= '0'; MOSI <= SerialOut(3); SerialIn(4) <= MISO;
          when s10    => state <= s11; SPICLK <= '1';
          when s11    => state <= s12; SPICLK <= '0'; MOSI <= SerialOut(2); SerialIn(3) <= MISO;
          when s12    => state <= s13; SPICLK <= '1';
          when s13    => state <= s14; SPICLK <= '0'; MOSI <= SerialOut(1); SerialIn(2) <= MISO;
          when s14    => state <= s15; SPICLK <= '1';
          when s15    => state <= s16; SPICLK <= '0'; MOSI <= SerialOut(0); SerialIn(1) <= MISO;
          when s16    => state <= s17; SPICLK <= '1';
          when s17    => state <= s0; SPICLK <= '0'; MOSI <= '0'; SerialIn(0) <= MISO;
          when others => state <= s0;  -- retrun to idle state 
        end case;
      end if;

      dataout <= SerialIn;
      
    end if;
  end process;
  
end Behavioral;



