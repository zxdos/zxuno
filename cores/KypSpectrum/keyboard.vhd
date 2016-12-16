library ieee;
  use ieee.std_logic_1164.all;

entity keyboard is
  port
  (
    sw       : in std_logic_vector(7 downto 0);
    col      : in std_logic_vector(4 downto 0);
    boot     : out std_logic;
    reset    : out std_logic;
    nmi      : out std_logic;
    received : in  std_logic;
    scancode : in  std_logic_vector(7 downto 0);
    rows     : in  std_logic_vector(7 downto 0);
    cols     : out std_logic_vector(4 downto 0)
  );
end;

architecture behavioral of keyboard is

  type   matrix is array (7 downto 0) of std_logic_vector(4 downto 0);
  signal keys, mikeys : matrix;
  signal isalt   : std_logic;
  signal pressed : std_logic;

begin
  process(received, scancode)
  begin
    if falling_edge(received) then
      nmi     <= '0';
      boot    <= '0';
      reset   <= '0';
      pressed <= '1';
      case scancode is
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
                        boot <= '1';         -- Master Reset
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
        when X"71" => if keys(7)(1)='1' and isalt='1' then
                        reset <= '1';        -- Reset
                      end if;
        when X"11" => isalt      <= pressed;
        when X"03" => if keys(7)(1)='1' and isalt='1' then
                        nmi <= '1';          -- NMI
                      end if;
        when others => null;
      end case;
    end if;
  end process;

  process (col)
  begin
    for i in 0 to 4 loop
      if col(i)='0' then
        for j in 0 to 7 loop
          mikeys(j)(i)<= sw(j);
        end loop;
      end if;
    end loop;
  end process;

  process (keys, rows)
  variable tmp: std_logic;
  begin
    for i in 0 to 4 loop
      tmp:= '1';
      for j in 0 to 7 loop
        tmp:= tmp and (not keys(j)(i) or not mikeys(j)(i) or rows(j));
      end loop;
      cols(i) <=  tmp;
    end loop;
  end process;
end;
