-- PS2_Ctrl.vhd
-- ------------------------------------------------
--   Simplified PS/2 Controller  (kbd, mouse...)
-- ------------------------------------------------
-- Only the Receive function is implemented !
-- (c) ALSE. http://www.alse-fr.com

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

-- --------------------------------------
    Entity PS2_Ctrl is
-- --------------------------------------
  generic (FilterSize : positive := 8);
  port( Clk       : in  std_logic;  -- System Clock
        Reset     : in  std_logic;  -- System Reset
        PS2_Clk   : in  std_logic;  -- Keyboard Clock Line
        PS2_Data  : in  std_logic;  -- Keyboard Data Line
        DoRead    : in  std_logic;  -- From outside when reading the scan code
        Scan_Err  : out std_logic;  -- To outside : Parity or Overflow error
        Scan_DAV  : out std_logic;  -- To outside when a scan code has arrived
        Scan_Code : out unsigned(7 downto 0) -- Eight bits Data Out
        );
end PS2_Ctrl;

-- --------------------------------------
    Architecture ALSE_RTL of PS2_Ctrl is
-- --------------------------------------
-- (c) ALSE. http://www.alse-fr.com
-- Author : Bert Cuzeau.
-- Fully synchronous solution, same Filter on PS2_Clk.
-- Still as compact as "Plain_wrong"...
-- Possible improvement : add TIMEOUT on PS2_Clk while shifting
-- Note: PS2_Data is resynchronized though this should not be
-- necessary (qualified by Fall_Clk and does not change at that time).
-- Note the tricks to correctly interpret 'H' as '1' in RTL simulation.

  signal PS2_Datr  : std_logic;

  subtype Filter_t is std_logic_vector(FilterSize-1 downto 0);
  signal Filter    : Filter_t;
  signal Fall_Clk  : std_logic;
  signal Bit_Cnt   : unsigned(3 downto 0);
  signal Parity    : std_logic;
  signal Scan_DAVi : std_logic;

  signal S_Reg     : unsigned(8 downto 0);

  signal PS2_Clk_f : std_logic;

  Type   State_t is (Idle, Shifting);
  signal State : State_t;

begin

Scan_DAV <= Scan_DAVi;

-- This filters digitally the raw clock signal coming from the keyboard :
--  * Eight consecutive PS2_Clk=1 makes the filtered_clock go high
--  * Eight consecutive PS2_Clk=0 makes the filtered_clock go low
-- Implies a (FilterSize+1) x Tsys_clock delay on Fall_Clk wrt Data
-- Also in charge of the re-synchronization of PS2_Data

process (Clk,Reset)
begin
  if Reset='1' then
    PS2_Datr  <= '0';
    PS2_Clk_f <= '0';
    Filter    <= (others=>'0');
    Fall_Clk  <= '0';
  elsif rising_edge (Clk) then
    PS2_Datr <= PS2_Data and PS2_Data; -- also turns 'H' into '1'
    Fall_Clk <= '0';
    Filter   <= (PS2_Clk and PS2_CLK) & Filter(Filter'high downto 1);
    if Filter = Filter_t'(others=>'1') then
      PS2_Clk_f <= '1';
    elsif Filter = Filter_t'(others=>'0') then
      PS2_Clk_f <= '0';
      if PS2_Clk_f = '1' then
        Fall_Clk <= '1';
      end if;
    end if;
  end if;
end process;


-- This simple State Machine reads in the Serial Data
-- coming from the PS/2 peripheral.

process(Clk,Reset)
begin

  if Reset='1' then
    State     <= Idle;
    Bit_Cnt   <= (others => '0');
    S_Reg     <= (others => '0');
    Scan_Code <= (others => '0');
    Parity    <= '0';
    Scan_Davi <= '0';
    Scan_Err  <= '0';

  elsif rising_edge (Clk) then

    if DoRead='1' then
      Scan_Davi <= '0'; -- note: this assgnmnt can be overriden
    end if;

    case State is

      when Idle =>
        Parity  <= '0';
        Bit_Cnt <= (others => '0');
        -- note that we dont need to clear the Shift Register
        if Fall_Clk='1' and PS2_Datr='0' then -- Start bit
          Scan_Err <= '0';
          State <= Shifting;
        end if;

      when Shifting =>
          if Bit_Cnt >= 9 then
            if Fall_Clk='1' then -- Stop Bit
              -- Error is (wrong Parity) or (Stop='0') or Overflow
              Scan_Err  <= (not Parity) or (not PS2_Datr) or Scan_DAVi;
              Scan_Davi <= '1';
              Scan_Code <= S_Reg(7 downto 0);
              State <= Idle;
            end if;
          elsif Fall_Clk='1' then
            Bit_Cnt  <= Bit_Cnt + 1;
            S_Reg <= PS2_Datr & S_Reg (S_Reg'high downto 1); -- Shift right
            Parity <= Parity xor PS2_Datr;
          end if;

      when others => -- never reached
        State <= Idle;

    end case;

    --Scan_Err <= '0'; -- to create an on-purpose error on Scan_Err !

  end if;

end process;

end ALSE_RTL;

