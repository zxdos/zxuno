-------------------------------------------------------------------------------
--
-- PS/2 Keyboard interface for the Apple ][
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
-- After an original by Alex Freed
-- i18n & French keyboard by Michel Stempin
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard is

  generic (
    KEYMAP : string := "EN-us"          -- English US keymap
    -- KEYMAP : string := "FR-fr"          -- French keymap
    );

  port (
    PS2_Clk  : in std_logic;            -- From PS/2 port
    PS2_Data : in std_logic;            -- From PS/2 port
    CLK_14M  : in std_logic;
    read     : in std_logic;            -- Read strobe
    reset    : in std_logic;
    K        : out unsigned(7 downto 0) -- Latched, decoded keyboard data
    );
end keyboard;

architecture rtl of keyboard is

  signal code, latched_code : unsigned(7 downto 0);
  signal code_available     : std_logic;
  signal ascii              : unsigned(7 downto 0);  -- decoded
  signal shifted_code       : unsigned(11 downto 0);

  signal key_pressed        : std_logic;  -- Key pressed & not read
  signal ctrl, shift, alt   : std_logic;

  -- Special PS/2 keyboard codes
  constant KEY_UP_CODE      : unsigned(7 downto 0) := X"F0";
  constant EXTENDED_CODE    : unsigned(7 downto 0) := X"E0";
  constant LEFT_SHIFT       : unsigned(7 downto 0) := X"12";
  constant RIGHT_SHIFT      : unsigned(7 downto 0) := X"59";
  constant LEFT_CTRL        : unsigned(7 downto 0) := X"14";
  constant ALT_GR           : unsigned(7 downto 0) := X"11";

  type states is (IDLE,
                  HAVE_CODE,
                  DECODE,
                  GOT_KEY_UP_CODE,
                  GOT_KEY_UP2,
                  GOT_KEY_UP3,
                  KEY_UP,
                  NORMAL_KEY
                  );

  signal state, next_state : states;

begin

  ps2_controller : entity work.PS2_Ctrl port map (
    Clk       => CLK_14M,
    Reset     => reset,
    PS2_Clk   => PS2_Clk,
    PS2_Data  => PS2_Data,
    DoRead    => code_available,
    Scan_DAV  => code_available,
    Scan_Code => code);

  K <= key_pressed & "00" & ascii(4 downto 0) when ctrl = '1' else
       key_pressed & ascii(6 downto 0);

  shift_ctrl : process (CLK_14M, reset)
  begin
    if reset = '1' then
      shift <= '0';
      ctrl <= '0';
    elsif rising_edge(CLK_14M) then
      if state = HAVE_CODE then
        if code = LEFT_SHIFT or code = RIGHT_SHIFT then
          shift <= '1';
        elsif code = LEFT_CTRL then
          ctrl <= '1';
        elsif code = ALT_GR then
          alt <= '1';
        end if;
      elsif state = KEY_UP then
        if code = LEFT_SHIFT or code = RIGHT_SHIFT then
          shift <= '0';
        elsif code = LEFT_CTRL then
          ctrl <= '0';
        elsif code = ALT_GR then
          alt <= '0';
        end if;
      end if;
    end if;
  end process shift_ctrl;

  fsm : process (CLK_14M, reset)
  begin
    if reset = '1' then
      state <= IDLE;
      latched_code <= (others => '0');
      key_pressed <= '0';
    elsif rising_edge(CLK_14M) then
      state <= next_state;
      if read = '1' then key_pressed <= '0'; end if;
      if state = NORMAL_KEY then
        latched_code <= code ;
        key_pressed <= '1';
      end if;
    end if;
  end process fsm;

  fsm_next_state : process (code, code_available, state)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if code_available = '1' then next_state <= HAVE_CODE; end if;

      when HAVE_CODE =>
        next_state <= DECODE;

      when DECODE =>
        if code = KEY_UP_CODE then
          next_state <= GOT_KEY_UP_CODE;
        elsif code = EXTENDED_CODE then  -- Treat extended codes as normal
          next_state <= IDLE;
        elsif code = LEFT_SHIFT or code = RIGHT_SHIFT or code = LEFT_CTRL then
          next_state <= IDLE;
        else
          next_state <= NORMAL_KEY;
        end if;

      when GOT_KEY_UP_CODE =>
        next_state <= GOT_KEY_UP2;

      when GOT_KEY_UP2 =>
        next_state <= GOT_KEY_UP3;

      when GOT_KEY_UP3 =>
        if code_available = '1' then
          next_state <= KEY_UP;
        end if;

      when KEY_UP | NORMAL_KEY =>
        next_state <= IDLE;
    end case;
  end process fsm_next_state;

  -- PS/2 scancode to ASCII translation

  shifted_code <= "00" & alt & shift & latched_code;

  EN_us: if KEYMAP = "EN-us" generate
    with shifted_code select
      ascii <=
      X"08" when X"066", -- Backspace ("backspace" key)
      X"08" when X"166", -- Backspace ("backspace" key)
      X"09" when X"00d", -- Horizontal Tab
      X"09" when X"10d", -- Horizontal Tab
      X"0d" when X"05a", -- Carriage return ("enter" key)
      X"0d" when X"15a", -- Carriage return ("enter" key)
      X"1b" when X"076", -- Escape ("esc" key)
      X"1b" when X"176", -- Escape ("esc" key)
      X"20" when X"029", -- Space
      X"20" when X"129", -- Space
      X"21" when X"116", -- !
      X"22" when X"152", -- "
      X"23" when X"126", -- #
      X"24" when X"125", -- $
      X"25" when X"12e", --
      X"26" when X"13d", --
      X"27" when X"052", --
      X"28" when X"146", --
      X"29" when X"145", --
      X"2a" when X"13e", -- *
      X"2b" when X"155", -- +
      X"2c" when X"041", -- ,
      X"2d" when X"04e", -- -
      X"2e" when X"049", -- .
      X"2f" when X"04a", -- /
      X"30" when X"045", -- 0
      X"31" when X"016", -- 1
      X"32" when X"01e", -- 2
      X"33" when X"026", -- 3
      X"34" when X"025", -- 4
      X"35" when X"02e", -- 5
      X"36" when X"036", -- 6
      X"37" when X"03d", -- 7
      X"38" when X"03e", -- 8
      X"39" when X"046", -- 9
      X"3a" when X"14c", -- :
      X"3b" when X"04c", -- ;
      X"3c" when X"141", -- <
      X"3d" when X"055", -- =
      X"3e" when X"149", -- >
      X"3f" when X"14a", -- ?
      X"40" when X"11e", -- @
      X"41" when X"11c", -- A
      X"42" when X"132", -- B
      X"43" when X"121", -- C
      X"44" when X"123", -- D
      X"45" when X"124", -- E
      X"46" when X"12b", -- F
      X"47" when X"134", -- G
      X"48" when X"133", -- H
      X"49" when X"143", -- I
      X"4a" when X"13b", -- J
      X"4b" when X"142", -- K
      X"4c" when X"14b", -- L
      X"4d" when X"13a", -- M
      X"4e" when X"131", -- N
      X"4f" when X"144", -- O
      X"50" when X"14d", -- P
      X"51" when X"115", -- Q
      X"52" when X"12d", -- R
      X"53" when X"11b", -- S
      X"54" when X"12c", -- T
      X"55" when X"13c", -- U
      X"56" when X"12a", -- V
      X"57" when X"11d", -- W
      X"58" when X"122", -- X
      X"59" when X"135", -- Y
      X"5a" when X"11a", -- Z
      X"5b" when X"054", -- [
      X"5c" when X"05d", -- \
      X"5d" when X"05b", -- ]
      X"5e" when X"136", -- ^
      X"5f" when X"14e", -- _
      X"60" when X"00e", -- `
      X"41" when X"01c", -- A
      X"42" when X"032", -- B
      X"43" when X"021", -- C
      X"44" when X"023", -- D
      X"45" when X"024", -- E
      X"46" when X"02b", -- F
      X"47" when X"034", -- G
      X"48" when X"033", -- H
      X"49" when X"043", -- I
      X"4a" when X"03b", -- J
      X"4b" when X"042", -- K
      X"4c" when X"04b", -- L
      X"4d" when X"03a", -- M
      X"4e" when X"031", -- N
      X"4f" when X"044", -- O
      X"50" when X"04d", -- P
      X"51" when X"015", -- Q
      X"52" when X"02d", -- R
      X"53" when X"01b", -- S
      X"54" when X"02c", -- T
      X"55" when X"03c", -- U
      X"56" when X"02a", -- V
      X"57" when X"01d", -- W
      X"58" when X"022", -- X
      X"59" when X"035", -- Y
      X"5a" when X"01a", -- Z
      X"7b" when X"154", -- {
      X"7c" when X"15d", -- |
      X"7d" when X"15b", -- }
      X"7e" when X"10e", -- ~
      X"7f" when X"071", -- (Delete OR DEL on numeric keypad)
      X"15" when X"074", -- right arrow (cntrl U)
      X"08" when X"06b", -- left arrow (BS)
      X"0B" when X"075", -- (up arrow)
      X"0A" when X"072", -- (down arrow, ^J, LF)
      X"7f" when X"171", -- (Delete OR DEL on numeric keypad)
      X"00" when others;
  end generate EN_us;

  FR_fr: if KEYMAP = "FR-fr" generate
    with shifted_code select
      ascii <=
      X"08" when X"066", -- Backspace ("backspace" key)
      X"08" when X"166", -- Backspace ("backspace" key)
      X"09" when X"00d", -- Horizontal Tab
      X"09" when X"10d", -- Horizontal Tab
      X"0d" when X"05a", -- Carriage return ("enter" key)
      X"0d" when X"15a", -- Carriage return ("enter" key)
      X"1b" when X"076", -- Escape ("esc" key)
      X"1b" when X"176", -- Escape ("esc" key)
      X"20" when X"029", -- Space
      X"20" when X"129", -- Space
      X"21" when X"04a", -- !
      X"22" when X"026", -- "
      X"23" when X"226", -- #
      X"24" when X"05b", -- $
      X"25" when X"152", -- %
      X"26" when X"016", -- &
      X"27" when X"025", -- '
      X"28" when X"02e", -- (
      X"29" when X"04e", -- )
      X"2a" when X"05d", -- *
      X"2b" when X"155", -- +
      X"2c" when X"03a", -- ,
      X"2d" when X"036", -- -
      X"2e" when X"141", -- .
      X"2f" when X"149", -- /
      X"30" when X"145", -- 0
      X"31" when X"116", -- 1
      X"32" when X"11e", -- 2
      X"33" when X"126", -- 3
      X"34" when X"125", -- 4
      X"35" when X"12e", -- 5
      X"36" when X"136", -- 6
      X"37" when X"13d", -- 7
      X"38" when X"13e", -- 8
      X"39" when X"146", -- 9
      X"3a" when X"049", -- :
      X"3b" when X"041", -- ;
      X"3c" when X"061", -- <
      X"3d" when X"055", -- =
      X"3e" when X"161", -- >
      X"3f" when X"13a", -- ?
      X"40" when X"245", -- @
      X"41" when X"115", -- A
      X"42" when X"132", -- B
      X"43" when X"121", -- C
      X"44" when X"123", -- D
      X"45" when X"124", -- E
      X"46" when X"12b", -- F
      X"47" when X"134", -- G
      X"48" when X"133", -- H
      X"49" when X"143", -- I
      X"4a" when X"13b", -- J
      X"4b" when X"142", -- K
      X"4c" when X"14b", -- L
      X"4d" when X"14c", -- M
      X"4e" when X"131", -- N
      X"4f" when X"144", -- O
      X"50" when X"14d", -- P
      X"51" when X"11c", -- Q
      X"52" when X"12d", -- R
      X"53" when X"11b", -- S
      X"54" when X"12c", -- T
      X"55" when X"13c", -- U
      X"56" when X"12a", -- V
      X"57" when X"11a", -- W
      X"58" when X"122", -- X
      X"59" when X"135", -- Y
      X"5a" when X"11d", -- Z
      X"5b" when X"22e", -- [
      X"5c" when X"23e", -- \
      X"5d" when X"24e", -- ]
      X"5e" when X"054", -- ^
      X"5f" when X"03e", -- _
      X"60" when X"23d", -- `
      X"41" when X"015", -- A
      X"42" when X"032", -- B
      X"43" when X"021", -- C
      X"44" when X"023", -- D
      X"45" when X"024", -- E
      X"46" when X"02b", -- F
      X"47" when X"034", -- G
      X"48" when X"033", -- H
      X"49" when X"043", -- I
      X"4a" when X"03b", -- J
      X"4b" when X"042", -- K
      X"4c" when X"04b", -- L
      X"4d" when X"04c", -- M
      X"4e" when X"031", -- N
      X"4f" when X"044", -- O
      X"50" when X"04d", -- P
      X"51" when X"01c", -- Q
      X"52" when X"02d", -- R
      X"53" when X"01b", -- S
      X"54" when X"02c", -- T
      X"55" when X"03c", -- U
      X"56" when X"02a", -- V
      X"57" when X"01a", -- W
      X"58" when X"022", -- X
      X"59" when X"035", -- Y
      X"5a" when X"01d", -- Z
      X"7b" when X"225", -- {
      X"7c" when X"236", -- |
      X"7d" when X"255", -- }
      X"7e" when X"21e", -- ~
      X"7f" when X"071", -- (Delete OR DEL on numeric keypad)
      X"15" when X"074", -- right arrow (cntrl U)
      X"08" when X"06b", -- left arrow (BS)
      X"0B" when X"075", -- (up arrow)
      X"0A" when X"072", -- (down arrow, ^J, LF)
      X"7f" when X"171", -- (Delete OR DEL on numeric keypad)
      X"00" when others;
  end generate FR_fr;

end rtl;
