library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mapa_es.all;

entity ps2k is port (
    clk     : in  std_logic;
    ps2clk  : in  std_logic;
    ps2data : in  std_logic;
    rows    : in  std_logic_vector(7 downto 0);
    cols    : out std_logic_vector(4 downto 0);
    joy     : out std_logic_vector(4 downto 0);
    scancode: out std_logic_vector(7 downto 0);
    rst     : out std_logic;
    nmi     : out std_logic;
    mrst    : out std_logic);
end ps2k;

architecture behavioral of ps2k is

  type    key_matrix  is array (7 downto 0) of std_logic_vector(4 downto 0);
  signal  keys      : key_matrix;
  signal  pressed   : std_logic;
  signal  isalt     : std_logic;
  signal  lastclk   : std_logic_vector(4 downto 0);
  signal  bit_count : unsigned (3 downto 0);
  signal  shiftreg  : std_logic_vector(8 downto 0);
  signal  parity    : std_logic;

begin
  process (clk)
  begin
    if rising_edge(clk) then
      rst <= '1';
      nmi <= '1';
      mrst <= '1';
      lastclk <= lastclk(3 downto 0) & ps2clk;
      if lastclk="11100" and ps2clk='0' then  -- detector de flanco de bajada de PS2CLK
        if bit_count=0 then
          parity <= '0';
          if ps2data='0' then
            bit_count <= bit_count + 1;
          end if;
        else
          if bit_count<10 then
            bit_count <= bit_count + 1;
            shiftreg  <= ps2data & shiftreg(8 downto 1);
            parity    <= parity xor ps2data;
          elsif ps2data='1' then
            bit_count <= (others => '0');
            if parity = '1' then -- nueva pulsacion completa en shiftreg.
              pressed  <= '1';
              scancode <= shiftreg(7 downto 0);
              case shiftreg(7 downto 0) is
                when X"f0" => pressed    <= '0';
                when X"12" |
                     X"59" => keys(0)(0) <= pressed; -- Left or Right shift (CAPS SHIFT)
                when X"1a" => keys(0)(1) <= pressed; -- Z
                when X"22" => keys(0)(2) <= pressed; -- X
                when X"21" => keys(0)(3) <= pressed; -- C
                when X"2a" => keys(0)(4) <= pressed; -- V
                when X"1c" => keys(1)(0) <= pressed; -- A
                when X"1b" => keys(1)(1) <= pressed; -- S
                when X"23" => keys(1)(2) <= pressed; -- D
                when X"2b" => keys(1)(3) <= pressed; -- F
                when X"34" => keys(1)(4) <= pressed; -- G
                when X"15" => keys(2)(0) <= pressed; -- Q
                when X"1d" => keys(2)(1) <= pressed; -- W
                when X"24" => keys(2)(2) <= pressed; -- E
                when X"2d" => keys(2)(3) <= pressed; -- R
                when X"2c" => keys(2)(4) <= pressed; -- T
                when X"16" => keys(3)(0) <= pressed; -- 1
                when X"1e" => keys(3)(1) <= pressed; -- 2
                when X"26" => keys(3)(2) <= pressed; -- 3
                when X"25" => keys(3)(3) <= pressed; -- 4
                when X"2e" => keys(3)(4) <= pressed; -- 5
                when X"45" => keys(4)(0) <= pressed; -- 0
                when X"46" => keys(4)(1) <= pressed; -- 9
                when X"3e" => keys(4)(2) <= pressed; -- 8
                when X"3d" => keys(4)(3) <= pressed; -- 7
                when X"36" => keys(4)(4) <= pressed; -- 6
                when X"4d" => keys(5)(0) <= pressed; -- P
                when X"44" => keys(5)(1) <= pressed; -- O
                when X"43" => keys(5)(2) <= pressed; -- I
                when X"3c" => keys(5)(3) <= pressed; -- U
                when X"35" => keys(5)(4) <= pressed; -- Y
                when X"5a" => keys(6)(0) <= pressed; -- ENTER
                when X"4b" => keys(6)(1) <= pressed; -- L
                when X"42" => keys(6)(2) <= pressed; -- K
                when X"3b" => keys(6)(3) <= pressed; -- J
                when X"33" => keys(6)(4) <= pressed; -- H
                when X"29" => keys(7)(0) <= pressed; -- SPACE
                when X"14" => keys(7)(1) <= pressed; -- CTRL (Symbol Shift)
                when X"3a" => keys(7)(2) <= pressed; -- M
                when X"31" => keys(7)(3) <= pressed; -- N
                when X"32" => keys(7)(4) <= pressed; -- B
                when X"76" => keys(0)(0) <= pressed; -- Break (Caps Space)
                              keys(7)(0) <= pressed;
                when X"0e" |
                     X"06" => keys(0)(0) <= pressed; -- Edit (Caps 1)
                              keys(3)(0) <= pressed;
                when X"4e" |
                     X"09" => keys(0)(0) <= pressed; -- Graph (Caps 9)
                              keys(4)(1) <= pressed;
                when X"66" => keys(0)(0) <= pressed; -- Backspace (Caps 0)
                              keys(4)(0) <= pressed;
                              if keys(7)(1)='1' and isalt='1' then
                                mrst <= '0';         -- Master Reset
                              end if;
                when X"0d" => keys(0)(0) <= pressed; -- Extend
                              keys(7)(1) <= pressed;
                when X"54" => keys(0)(0) <= pressed; -- True Video (Caps 3)
                              keys(3)(2) <= pressed;
                when X"5b" => keys(0)(0) <= pressed; -- Inv. Video (Caps 4)
                              keys(3)(3) <= pressed;
                when X"58" => keys(0)(0) <= pressed; -- Caps lock (Caps 2)
                              keys(3)(1) <= pressed;
                when X"6b" => keys(0)(0) <= pressed; -- Left (Caps 5)
                              keys(3)(4) <= pressed;
                when X"72" => keys(0)(0) <= pressed; -- Down (Caps 6)
                              keys(4)(4) <= pressed;
                when X"75" => keys(0)(0) <= pressed; -- Up (Caps 7)
                              keys(4)(3) <= pressed;
                when X"74" => keys(0)(0) <= pressed; -- Right (Caps 8)
                              keys(4)(2) <= pressed;
                when X"55" => keys(7)(1) <= pressed; -- = (Symb L)
                              keys(6)(1) <= pressed;
                when X"4a" => keys(7)(1) <= pressed; -- / (Symb V)
                              keys(0)(4) <= pressed;
                when X"7c" => keys(7)(1) <= pressed; -- * (Symb B)
                              keys(7)(4) <= pressed;
                when X"7b" => keys(7)(1) <= pressed; -- - (Symb J)
                              keys(6)(3) <= pressed;
                when X"79" => keys(7)(1) <= pressed; -- + (Symb K)
                              keys(6)(2) <= pressed;
                when X"4c" => keys(7)(1) <= pressed; -- ; (Symb O)
                              keys(5)(1) <= pressed;
                when X"52" => keys(7)(1) <= pressed; -- " (Symb P)
                              keys(5)(0) <= pressed;
                when X"41" => keys(7)(1) <= pressed; -- , (Symb N)
                              keys(7)(3) <= pressed;
                when X"49" => keys(7)(1) <= pressed; -- , (Symb M)
                              keys(7)(2) <= pressed;
                when X"71" => joy(1)     <= pressed; -- Joy Left
                              if keys(7)(1)='1' and isalt='1' then
                                rst <= '0';          -- Reset
                              end if;
                when X"69" => joy(2)     <= pressed; -- Joy Down
                when X"6c" => joy(3)     <= pressed; -- Joy Up
                when X"7a" => joy(0)     <= pressed; -- Joy Right
                when X"11" => joy(4)     <= pressed; -- Joy Fire
                              isalt      <= pressed;
                when X"03" => if keys(7)(1)='1' and isalt='1' then
                                nmi <= '0';          -- NMI
                              end if;
                when others=> null;
              end case;
            end if;
          else
            bit_count <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  process (keys, rows)
  variable tmp: std_logic;
  begin
    for i in 0 to 4 loop
      tmp:= '0';
      for j in 0 to 7 loop
        tmp:= tmp or (keys(j)(i) and not rows(j));
      end loop;
      cols(i) <=  not tmp;
    end loop;
  end process;

end architecture;
