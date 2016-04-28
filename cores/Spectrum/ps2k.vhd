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
  signal  isctrl    : std_logic;
  signal  isshift   : std_logic;
  signal  isalt     : std_logic;
  signal  isextend  : std_logic;
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
              pressed <= '1';
              scancode <= shiftreg(7 downto 0);
              if isextend='1' and shiftreg(7 downto 0)=KEY_RELEASED then  -- procesar la secuencia E0 F0 key
                isextend <= '1';
              else
                isextend <= '0';
              end if;
              case shiftreg(7 downto 0) is  -- detectar secuencias especiales: tecla soltada y tecla extendida
                when KEY_RELEASED => pressed    <= '0';
                when KEY_EXTENDED => isextend   <= '1';
                when others => null;
              end case;
              if isextend='0' then  -- teclas no extendidas
                case shiftreg(7 downto 0) is
                  when KEY_LSHIFT | 
                       KEY_RSHIFT   => isshift <= pressed;
                  when KEY_ALTI     => isalt <= pressed;
                                       joy(4) <= pressed; -- dato entregado por el joystick
                  when KEY_CTRLI    => keys(0)(0) <= pressed; -- Ctrl izquierdo: (CAPS SHIFT)
                                       isctrl <= pressed;
                                       joy(4) <= pressed; -- dato entregado por el joystick
                  when KEY_Z        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(0)(1) <= pressed; -- Z
                  when KEY_X        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(0)(2) <= pressed; -- X
                  when KEY_C        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(0)(3) <= pressed; -- C
                  when KEY_V        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(0)(4) <= pressed; -- V
                  when KEY_A        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(1)(0) <= pressed; -- A
                  when KEY_S        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(1)(1) <= pressed; -- S
                  when KEY_D        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(1)(2) <= pressed; -- D
                  when KEY_F        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(1)(3) <= pressed; -- F
                  when KEY_G        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(1)(4) <= pressed; -- G
                  when KEY_Q        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(2)(0) <= pressed; -- Q
                  when KEY_W        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(2)(1) <= pressed; -- W
                  when KEY_E        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(2)(2) <= pressed; -- E
                  when KEY_R        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(2)(3) <= pressed; -- R
                  when KEY_T        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(2)(4) <= pressed; -- T
                  when KEY_1        => if isshift='0' then
                                         keys(3)(0) <= pressed; -- 1
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(3)(0) <= pressed; -- !
                                       end if;
                  when KEY_2        => if isshift='0' then
                                         keys(3)(1) <= pressed; -- 2
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(5)(0) <= pressed; -- "
                                       end if;  
                  when KEY_3        => if isshift='0' then
                                         keys(3)(2) <= pressed; -- 3
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(3)(2) <= pressed; -- #
                                       end if;  
                  when KEY_4        => if isshift='0' then
                                         keys(3)(3) <= pressed; -- 4
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(3)(3) <= pressed; -- $
                                       end if;
                  when KEY_5        => if isshift='0' then
                                         keys(3)(4) <= pressed; -- 5
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(3)(4) <= pressed; -- $
                                       end if;
                  when KEY_0        => if isshift='0' then
                                         keys(4)(0) <= pressed; -- 0
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(6)(1) <= pressed; -- =
                                       end if;
                  when KEY_9        => if isshift='0' then
                                         keys(4)(1) <= pressed; -- 9
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(4)(1) <= pressed; -- )
                                       end if;
                  when KEY_8        => if isshift='0' then
                                         keys(4)(2) <= pressed; -- 8
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(4)(2) <= pressed; -- (
                                       end if;
                  when KEY_7        => if isshift='0' then
                                         keys(4)(3) <= pressed; -- 7
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(0)(4) <= pressed; -- /
                                       end if;
                  when KEY_6        => if isshift='0' then
                                         keys(4)(4) <= pressed; -- 6
                                       else
                                         keys(7)(1) <= pressed;
                                         keys(4)(4) <= pressed; -- &
                                       end if;
                  when KEY_P        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(5)(0) <= pressed; -- P
                  when KEY_O        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(5)(1) <= pressed; -- O
                  when KEY_I        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(5)(2) <= pressed; -- I
                  when KEY_U        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(5)(3) <= pressed; -- U
                  when KEY_Y        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(5)(4) <= pressed; -- Y
                  when KEY_ENTER    => keys(6)(0) <= pressed; -- ENTER
                  when KEY_L        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(6)(1) <= pressed; -- L
                  when KEY_K        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(6)(2) <= pressed; -- K
                  when KEY_J        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(6)(3) <= pressed; -- J
                  when KEY_H        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(6)(4) <= pressed; -- H
                  when KEY_SPACE    => keys(7)(0) <= pressed; -- SPACE
                  when KEY_M        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(7)(2) <= pressed; -- M
                  when KEY_N        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(7)(3) <= pressed; -- N
                  when KEY_B        => if isshift='1' then
                                         keys(0)(0) <= pressed;
                                       end if;
                                       keys(7)(4) <= pressed; -- B
                  when KEY_BKSP     => keys(0)(0) <= pressed; -- Backspace (Caps 0)
                                       keys(4)(0) <= pressed;
                                       if isctrl='1' and isalt='1' then
                                         mrst <= '0';
                                       end if;
                  when KEY_CPSLK    => keys(0)(0) <= pressed; -- Caps lock (Caps 2)
                                       keys(3)(1) <= pressed;
                  when KEY_ESC      => keys(0)(0) <= pressed; -- Break (Caps Space)
                                       keys(7)(0) <= pressed;
                  when KEY_F2       => keys(0)(0) <= pressed;
                                       keys(3)(0) <= pressed; -- EDIT
                  when KEY_BL       => keys(7)(1) <= pressed;
                                       keys(1)(2) <= pressed; -- usado con EXT, da \
                  when KEY_APOS     => keys(7)(1) <= pressed;
                                       if isshift='0' then 
                                         keys(4)(3) <= pressed; -- apostrofe '
                                       else
                                         keys(0)(3) <= pressed; -- tecla ?
                                       end if;
                  when KEY_TAB      => keys(0)(0) <= pressed;
                                       keys(7)(1) <= pressed; -- modo extendido
                  when KEY_CORCHA   => keys(7)(1) <= pressed;
                                       keys(6)(4) <= pressed; -- simbolo ^
                  when KEY_CORCHC   => keys(7)(1) <= pressed;
                                       if isshift='0' then
                                         keys(6)(2) <= pressed; -- simbolo +
                                       else
                                         keys(7)(4) <= pressed; -- simbolo *
                                       end if;
                  when KEY_LLAVA    => keys(7)(1) <= pressed;
                                       keys(1)(3) <= pressed; -- llave abierta, con EXT
                  when KEY_LLAVC    => keys(7)(1) <= pressed;
                                       keys(5)(0) <= pressed; -- copyright
                  when KEY_LT       => keys(7)(1) <= pressed;
                                       if isshift='0' then
                                         keys(2)(3) <= pressed; -- símbolo <
                                       else
                                         keys(2)(4) <= pressed; -- símbolo >
                                       end if;
                  when KEY_COMA     => keys(7)(1) <= pressed;
                                       if isshift='0' then
                                         keys(7)(3) <= pressed; -- símbolo ,
                                       else
                                         keys(5)(1) <= pressed; -- símbolo ;
                                       end if;
                  when KEY_PUNTO    => keys(7)(1) <= pressed;
                                       if isshift='0' then
                                         keys(7)(2) <= pressed; -- símbolo .
                                       else
                                         keys(0)(1) <= pressed; -- símbolo :
                                       end if;
                  when KEY_MENOS    => keys(7)(1) <= pressed;
                                       if isshift='0' then
                                         keys(6)(3) <= pressed; -- símbolo -                
                                       else
                                         keys(4)(0) <= pressed; -- tecla _ (guion bajo)
                                       end if;
                  when KEY_F5       => if isctrl='1' and isalt='1' then
                                         nmi <= '0';  -- NMI
                                       end if;
                  when KEY_KPPUNTO  => if isctrl='1' and isalt='1' then
                                         rst <= '0'; -- reset al hacer ctrl-alt-supr
                                       end if;
                  when KEY_KP4      => joy(1) <= pressed; -- dato entregado por el joystick: izquierda
                  when KEY_KP6      => joy(0) <= pressed; -- dato entregado por el joystick: derecha
                  when KEY_KP8      => joy(3) <= pressed; -- dato entregado por el joystick: arriba
                  when KEY_KP5      => joy(2) <= pressed; -- dato entregado por el joystick: abajo
                  when others=> null;
                end case;
              else -- process extended keys
                case shiftreg(7 downto 0) is
                  when KEY_CTRLD    => keys(7)(1) <= pressed; -- Ctrl derecho -> symbol shift
                                       isctrl <= pressed;
                                       joy(4) <= pressed; -- dato entregado por el joystick
                  when KEY_ALTGR    => keys(0)(0) <= pressed;
                                       keys(4)(1) <= pressed; -- Modo gráfico
                                       isalt <= '1';
                                       joy(4) <= pressed; -- dato entregado por el joystick
                  when KEY_LEFT     => keys(0)(0) <= pressed; -- Left (Caps 5)
                                       keys(3)(4) <= pressed;
                  when KEY_DOWN     => keys(0)(0) <= pressed; -- Down (Caps 6)
                                       keys(4)(4) <= pressed;
                  when KEY_UP       => keys(0)(0) <= pressed; -- Up (Caps 7)
                                       keys(4)(3) <= pressed;
                  when KEY_RIGHT    => keys(0)(0) <= pressed; -- Right (Caps 8)
                                       keys(4)(2) <= pressed;
                  when KEY_SUP      => if isctrl='1' and isalt='1' then
                                         rst <= '0'; -- reset al hacer ctrl-alt-supr
                                       end if;
                  when others => null;
                end case;
              end if;  
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
