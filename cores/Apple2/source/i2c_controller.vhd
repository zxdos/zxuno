-------------------------------------------------------------------------------
--
-- Simple I2C bus interface for initializing the Wolfson WM8731 audio codec
-- on the DE2
--
-- Stephen A. Edwards (sedwards@cs.columbia.edu)
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_controller is
  
  port (
    CLK   : in    std_logic;           -- 50 MHz main clock
    SCLK  : out   std_logic;           -- I2C clock
    SDAT  : inout std_logic;           -- I2C data
    reset : in    std_logic);
end i2c_controller;

architecture rtl of i2c_controller is

  type phases is (IDLE, START, ZERO, ONE, ACK, STOP);

  type packet_states is (P_IDLE,
                         P_START,
                         P_ADDR,
                         P_WRITE,
                         P_ADDR_ACK,
                         P_DATA1,
                         P_DATA1_ACK,
                         P_DATA2,
                         P_DATA2_ACK,
                         P_STOP);

  type data_states is (D_SEND, D_DONE, D_IDLE);

  signal address : unsigned(6 downto 0);
  signal data1, data2 : unsigned(7 downto 0);
  signal send, done : std_logic;

begin

  address <= "0011010";                 -- fixed address of WM8731

  send_data : process (CLK)
    variable state : data_states;
    variable reg : unsigned(3 downto 0);
  begin
    if rising_edge(CLK) then
      if reset = '1' then
        state := D_DONE;
        reg := X"0";
        send <= '0';
        data2 <= X"00";
      else
        case state is
          when D_DONE =>
              if done = '0' then
                state := D_SEND;
                send <= '1';
                data1 <= "000" & reg & "0";
                case reg is
                when X"0" => data2 <= X"1A";  -- LIN_L
                when X"1" => data2 <= X"1A";  -- LIN_R
                when X"2" => data2 <= X"7B";  -- HEAD_L
                when X"3" => data2 <= X"7B";  -- HEAD_R
                when X"4" => data2 <= X"F8";  -- A_PATH_CTRL
                when X"5" => data2 <= X"06";  -- D_PATH_CTRL
                when X"6" => data2 <= X"00";  -- POWER_ON
                when X"7" => data2 <= X"01";  -- SET_FORMAT
                when X"8" => data2 <= X"02";  -- SAMPLE_CTRL
                when X"9" => data2 <= X"01";  -- SET_ACTIVE
                when others =>
                  state := D_IDLE;
                  send <= '0';
                end case;
                reg := reg + 1;
              end if;

          when D_SEND =>
              if done = '1' then
                send <= '0';
                state := D_DONE;
              end if;
              
          when D_IDLE =>       -- hold
            
        end case;
      end if;
    end if;
  end process;      

  send_packet : process (CLK)
    variable clock_prescaler : unsigned(7 downto 0);
    variable sreg : unsigned(22 downto 0);
    variable state : packet_states;
    variable bit_counter : unsigned(2 downto 0);
    variable phase : phases;
  begin
    if rising_edge(CLK) then
      if reset = '1' then
        state := P_IDLE;
        phase := IDLE;
        SCLK <= '1';
        SDAT <= 'Z';
        clock_prescaler := X"00";
        sreg := (others => '0');
      else
        if clock_prescaler = X"00" then
          done <= '0';
          case state is
            when P_IDLE =>
              phase := IDLE;
              sreg := address & data1 & data2;
              if send = '1' then
                state := P_START;
              end if;

            when P_START =>
              phase := START;
              bit_counter := "110";
              state := P_ADDR;

            when P_ADDR =>
              if sreg(22) = '1' then phase := ONE;
              else phase := ZERO; end if;
              sreg := sreg(21 downto 0) & '0';
              if bit_counter = "000" then state := P_WRITE; end if;
              bit_counter := bit_counter - 1;

            when P_WRITE =>
              phase := ZERO;
              state := P_ADDR_ACK;

            when P_ADDR_ACK =>
              phase := ACK;
              bit_counter := "111";
              state := P_DATA1;
              
            when P_DATA1 =>
              if sreg(22) = '1' then phase := ONE;
              else phase := ZERO; end if;
              sreg := sreg(21 downto 0) & '0';
              if bit_counter = "000" then state := P_DATA1_ACK; end if;
              bit_counter := bit_counter - 1;
              
            when P_DATA1_ACK =>
              phase := ACK;
              bit_counter := "111";
              state := P_DATA2;

            when P_DATA2 =>
              if sreg(22) = '1' then phase := ONE;
              else phase := ZERO; end if;
              sreg := sreg(21 downto 0) & '0';
              if bit_counter = "000" then state := P_DATA2_ACK; end if;
              bit_counter := bit_counter - 1;

            when P_DATA2_ACK =>
              phase := ACK;
              state := P_STOP;

            when P_STOP =>
              phase := STOP;
              done <= '1';
              state := P_IDLE;

          end case;         
        end if;

        case phase is
          when IDLE =>
            SCLK <= '1';
            SDAT <= 'Z';
            
          when START =>
            if clock_prescaler(7 downto 6) = "00" then SDAT <= '1';
            else SDAT <= '0';
            end if;
            if clock_prescaler(7 downto 6) = "11" then SCLK <= '0';
            else SCLK <= '1';
            end if;

          when ZERO | ONE =>
            if phase = ONE then SDAT <= '1'; else SDAT <= '0'; end if;
            if clock_prescaler(7) = clock_prescaler(6) then SCLK <= '0';
            else SCLK <= '1';
            end if;

          when ACK =>
            if clock_prescaler(7) = clock_prescaler(6) then SCLK <= '0';
            else SCLK <= '1'; end if;
            SDAT <= 'Z';

          when STOP =>
            SCLK <= '1';
            if clock_prescaler(7) = '1' then SDAT <= '1';
            else SDAT <= '0'; end if;
            
        end case;

        clock_prescaler := clock_prescaler + 1;
      end if;
    end if;
  end process;

  

end rtl;
