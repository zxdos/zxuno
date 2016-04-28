library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wm8731_audio is
port (
    clk           : in std_logic; --  Audio CODEC Chip Clock AUD_XCK (18.43 MHz)
    reset         : in std_logic;
    audio_request : out std_logic;  -- Audio controller request new data
    data          : in unsigned(15 downto 0);
  
    -- Audio interface signals
    AUD_ADCLRCK   : out  std_logic;   --    Audio CODEC ADC LR Clock
    AUD_ADCDAT    : in   std_logic;   --    Audio CODEC ADC Data
    AUD_DACLRCK   : out  std_logic;   --    Audio CODEC DAC LR Clock
    AUD_DACDAT    : out  std_logic;   --    Audio CODEC DAC Data
    AUD_BCLK      : inout std_logic  --    Audio CODEC Bit-Stream Clock
  );
end  wm8731_audio;

architecture rtl of wm8731_audio is     

    signal lrck : std_logic;
    signal bclk : std_logic;
    signal xck  : std_logic;
    
    signal lrck_divider : unsigned(7 downto 0); 
    signal bclk_divider : unsigned(3 downto 0);
    
    signal set_bclk : std_logic;
    signal set_lrck : std_logic;
    signal clr_bclk : std_logic;
    signal lrck_lat : std_logic;
    
    signal shift_out : unsigned(15 downto 0);

begin
  
    -- LRCK divider 
    -- Audio chip main clock is 18.432MHz / Sample rate 48KHz
    -- Divider is 18.432 MHz / 48KHz = 192 (X"C0")
    -- Left justify mode set by I2C controller
    
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then 
        lrck_divider <= (others => '0');
      elsif lrck_divider = X"BF"  then        -- "C0" minus 1
        lrck_divider <= X"00";
      else 
        lrck_divider <= lrck_divider + 1;
      end if;
    end if;   
  end process;

  process (clk)
  begin
    if rising_edge(clk) then      
      if reset = '1' then 
        bclk_divider <= (others => '0');
      elsif bclk_divider = X"B" or set_lrck = '1'  then  
        bclk_divider <= X"0";
      else 
        bclk_divider <= bclk_divider + 1;
      end if;
    end if;
  end process;

  set_lrck <= '1' when lrck_divider = X"BF" else '0';
    
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        lrck <= '0';
      elsif set_lrck = '1' then 
        lrck <= not lrck;
      end if;
    end if;
  end process;
    
  -- BCLK divider
  set_bclk <= '1' when bclk_divider(3 downto 0) = "0101" else '0';
  clr_bclk <= '1' when bclk_divider(3 downto 0) = "1011" else '0';
  
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bclk <= '0';
      elsif set_lrck = '1' or clr_bclk = '1' then
        bclk <= '0';
      elsif set_bclk = '1' then 
        bclk <= '1';
      end if;
    end if;
  end process;

  -- Audio data shift output
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        shift_out <= (others => '0');
      elsif set_lrck = '1' then
        shift_out <= data;
      elsif clr_bclk = '1' then 
        shift_out <= shift_out (14 downto 0) & '0';
      end if;
    end if;
  end process;

    -- Audio outputs
    
    AUD_ADCLRCK  <= lrck;          
    AUD_DACLRCK  <= lrck;          
    AUD_DACDAT   <= shift_out(15); 
    AUD_BCLK     <= bclk;          

    process(clk)
    begin
      if rising_edge(clk) then
        lrck_lat <= lrck;
      end if;
    end process;

    process (clk) 
    begin
      if rising_edge(clk) then 
        if lrck_lat = '1' and lrck = '0' then
          audio_request <= '1';
        else 
          audio_request <= '0';
        end if;
      end if;
    end process;

end architecture;


