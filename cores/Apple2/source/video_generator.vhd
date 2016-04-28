-------------------------------------------------------------------------------
--
-- Apple ][ Video Generation Logic
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
--
-- This takes data from memory and various mode switches to produce the
-- serial one-bit video data stream.
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_generator is
  
  port (
    CLK_14M    : in std_logic;              -- 14.31818 MHz master clock
    CLK_7M     : in std_logic;
    AX         : in std_logic;
    CAS_N      : in std_logic;
    TEXT_MODE  : in std_logic;
    PAGE2      : in std_logic;
    HIRES_MODE : in std_logic;
    MIXED_MODE : in std_logic;
    H0         : in std_logic;
    VA         : in std_logic;
    VB         : in std_logic;
    VC         : in std_logic;
    V2         : in std_logic;
    V4         : in std_logic;
    BLANK      : in std_logic;
    DL         : in unsigned(7 downto 0);  -- Data from RAM
    LDPS_N     : in std_logic;
    LD194      : in std_logic;
    FLASH_CLK  : in std_logic;            -- Low-frequency flashing text clock
    HIRES      : out std_logic;
    VIDEO      : out std_logic;
    COLOR_LINE : out std_logic
    );

end video_generator;

architecture rtl of video_generator is

  signal char_rom_addr : unsigned(8 downto 0);
  signal char_rom_out : unsigned(4 downto 0);
  signal text_shiftreg : unsigned(5 downto 0);
  signal invert_character : std_logic;
  signal text_pixel : std_logic;        -- B2 p11
  signal blank_delayed : std_logic;
  signal video_sig : std_logic;         -- output of B10 p5
  signal graph_shiftreg : unsigned(7 downto 0);
  signal graphics_time_1, graphics_time_2,
    graphics_time_3 : std_logic;  -- B5 p2, B8 p15, B8 p2
  signal lores_time : std_logic;       -- A11 p6
  signal pixel_select : std_logic_vector(1 downto 0);  -- A10 p14, A10 p15
  signal hires_delayed : std_logic;     -- A11 p9
 
begin

  -----------------------------------------------------------------------------
  -- 
  -- Text Mode Circuitry
  --
  -- The character ROM drives a parallel-to-serial shift register
  -- whose output is selectively inverted by inverted or flashing text
  --
  -----------------------------------------------------------------------------

  char_rom_addr <= DL(5 downto 0) & VC & VB & VA;
                   
  thecharrom : entity work.character_rom
    port map(
      addr       => char_rom_addr,
      clk        => CLK_14M,            -- FIXME: a lower frequency?
      dout       => char_rom_out
      );

  -- Parallel-to-serial shifter for text mode
  -- The Apple actually used LDPS_N as the clock, not 14M; this is equivalent
  A3_74166: process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if CLK_7M = '0' then
        if LDPS_N = '0' then        -- load
          text_shiftreg <= char_rom_out & "0";
        else                        -- shift
          text_shiftreg <= '0' & text_shiftreg(5 downto 1);
        end if;
      end if;
    end if;     
  end process;

  -- Latch and decoder for flashing/inverted text
  -- Comprises part of B11, B13, and A10
  flash_invert : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if LD194 = '0' then
        invert_character <= not (DL(7) or (DL(6) and FLASH_CLK));
      end if;
    end if;
  end process;

  text_pixel <= text_shiftreg(0) xor invert_character;

  -----------------------------------------------------------------------------
  --
  -- Lores and Hires Mode Circuitry
  --
  -- An eight-bit shift register that either shifts (hires mode) or rotates
  -- the two nibbles (lores) followed by a mux that selects the video
  -- data from the text mode display, the hires shift register (possibly
  -- delayed by a 14M clock pulse), or one of the bits in the lores shift
  -- register.
  --
  -----------------------------------------------------------------------------

  -- Original Apple clocked this shift register on the rising edge of RAS_N
  B5B8_74LS174 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if AX = '1' and CAS_N = '0' then
       graphics_time_3 <= graphics_time_2;
       graphics_time_2 <= graphics_time_1;
       graphics_time_1 <= not (TEXT_MODE or (V2 and V4 and MIXED_MODE));
      end if;
    end if;
  end process;

  COLOR_LINE <= graphics_time_1;

  HIRES <= HIRES_MODE and graphics_time_3;  -- to address generator

  lores_time <= not HIRES_MODE and graphics_time_3;

  A8A10_74LS194 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if LD194 = '0' then
        if lores_time = '1' then        -- LORES mode
          pixel_select <= VC & H0;
        else                            -- HIRES mode
          pixel_select <= graphics_time_1 & DL(7);
        end if;
      end if;
    end if;
  end process;

  -- Shift hires pixels by one 14M cycle to get orange and blue
  A11_74LS74 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      hires_delayed <= graph_shiftreg(0);
    end if;
  end process;  

  -- A pair of four-bit universal shift registers that either
  -- shift the whole byte (hires mode) or rotate the two nibbles (lores mode)
  B4B9_74LS194 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if LD194 = '0' then
        graph_shiftreg <= DL;
      else
        if lores_time = '1' then          -- LORES configuration
          graph_shiftreg <= graph_shiftreg(4) & graph_shiftreg(7 downto 5) &
                            graph_shiftreg(0) & graph_shiftreg(3 downto 1);
        else                                  -- HIRES configuration
          if CLK_7M = '0' then
            graph_shiftreg <= graph_shiftreg(4) & graph_shiftreg(7 downto 1);
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Synchronize BLANK to LD194
  A10_74LS194: process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if LD194 = '0' then
        blank_delayed <= BLANK;
      end if;
    end if;
  end process;

  -- Video output mux and flip-flop
  A9B10_74LS151 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if blank_delayed = '0' then
        if lores_time = '1' then        -- LORES mode
          case pixel_select is
            when "00" => video_sig <= graph_shiftreg(0);
            when "01" => video_sig <= graph_shiftreg(2);
            when "10" => video_sig <= graph_shiftreg(4);
            when "11" => video_sig <= graph_shiftreg(6);
            when others => video_sig <= 'X';
          end case;
        else
          if pixel_select(1) = '0' then  -- TEXT mode
            video_sig <= text_pixel;
          else            -- HIRES mode
            if pixel_select(0) = '1' then
              video_sig <= hires_delayed;
            else
              video_sig <= graph_shiftreg(0); 
            end if;
          end if;
        end if;
      else
        video_sig <= '0';
      end if;
    end if;
  end process;

  VIDEO <= video_sig;

end rtl;
