-------------------------------------------------------------------------------
--
-- Apple ][ Timing logic
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
--
-- Taken more-or-less verbatim from the schematics in the
-- Apple ][ reference manual
--
-- This takes a 14.31818 MHz master clock and divides it down to generate
-- the various lower-frequency signals (e.g., 7M, phase 0, colorburst)
-- as well as horizontal and vertical blanking and sync signals for the video
-- and the video addresses.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timing_generator is
  
  port (
    CLK_14M        : in  std_logic;           -- 14.31818 MHz master clock
    CLK_7M         : buffer std_logic := '0';
    Q3	           : buffer std_logic := '0'; -- 2 MHz signal in phase with PHI0
    RAS_N          : buffer std_logic := '0';
    CAS_N          : buffer std_logic := '0';
    AX             : buffer std_logic := '0';
    PHI0           : buffer std_logic := '0'; -- 1.0 MHz processor clock
    PRE_PHI0       : buffer std_logic := '0'; -- One 14M cycle before
    COLOR_REF      : buffer std_logic := '0'; -- 3.579545 MHz colorburst

    TEXT_MODE      : in std_logic;
    PAGE2          : in std_logic;
    HIRES          : in std_logic;

    VIDEO_ADDRESS  : out unsigned(15 downto 0);
    H0             : out std_logic;
    VA             : out std_logic;      -- Character row address
    VB             : out std_logic;
    VC             : out std_logic;
    V2             : out std_logic;
    V4             : out std_logic;
    HBL		   : buffer std_logic;      -- Horizontal blanking
    VBL		   : buffer std_logic;      -- Vertical blanking
    BLANK          : out std_logic;         -- Composite blanking
    LDPS_N         : out std_logic;
    LD194          : out std_logic
  );

end timing_generator;

architecture rtl of timing_generator is

  signal H : unsigned(6 downto 0) := "0000000";
  signal V : unsigned(8 downto 0) := "011111010";
  signal COLOR_DELAY_N : std_logic;
  
begin

  -- To generate the once-a-line hiccup: D1 pin 6
  COLOR_DELAY_N <=
    not (not COLOR_REF and (not AX and not CAS_N) and PHI0 and not H(6));

  -- The DRAM signal generator
  C2_74S195: process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if Q3 = '1' then -- shift
        (Q3, CAS_N, AX, RAS_N) <=
          unsigned'(CAS_N, AX, RAS_N, '0');
      else               -- load
        (Q3, CAS_N, AX, RAS_N) <=
          unsigned'(RAS_N, AX, COLOR_DELAY_N, AX);
      end if;
    end if;
  end process;

  -- The main clock signal generator
  B1_74S175 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      COLOR_REF <= CLK_7M xor COLOR_REF;
      CLK_7M <= not CLK_7M;
      PHI0 <= PRE_PHI0;
      if AX = '1' then
        PRE_PHI0 <= not (Q3 xor PHI0);  -- B1 pin 10
      end if;
    end if;
  end process;

  LDPS_N <= not (PHI0 and not AX and not CAS_N);
  LD194 <= not (PHI0 and not AX and not CAS_N and not CLK_7M);

  -- Four four-bit presettable binary counters
  -- Seven-bit horizontal counter counts 0, 40, 41, ..., 7F (65 states)
  -- Nine-bit vertical counter counts $FA .. $1FF  (262 states)
  D11D12D13D14_74LS161 : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      -- True the cycle before the rising edge of LDPS_N: emulates
      -- the effects of using LDPS_N as the clock for the video counters
      if (PHI0 and not AX and ((Q3 and RAS_N) or
                              (not Q3 and COLOR_DELAY_N))) = '1' then
        if H(6) = '0' then H <= "1000000";
        else
          H <= H + 1;
          if H = "1111111" then
            V <= V + 1;
            if V = "111111111" then V <= "011111010"; end if;
          end if;
        end if;
      end if;
    end if;
    
  end process;

  H0 <= H(0);
  VA <= V(0);
  VB <= V(1);
  VC <= V(2);
  V2 <= V(5);
  V4 <= V(7);

  HBL <= not (H(5) or (H(3) and H(4)));
  VBL <= V(6) and V(7);

  BLANK <= HBL or VBL;

  -- V_SYNC <= VBL and V(5) and not V(4) and not V(3) and
  --           not V(2) and (H(4) or H(3) or H(5));
  -- H_SYNC <= HBL and H(3) and not H(2);

  -- SYNC <= not (V_SYNC or H_SYNC);
  -- COLOR_BURST <= HBL and H(2) and H(3) and (COLOR_REF or TEXT_MODE);

  -- Video address calculation
  VIDEO_ADDRESS(2 downto 0) <= H(2 downto 0);
  VIDEO_ADDRESS(6 downto 3) <= (not H(5) &     V(6) & H(4) & H(3)) +
                               (    V(7) & not H(5) & V(7) &  '1') +
                               (                     "000" & V(6));
  VIDEO_ADDRESS(9 downto 7) <= V(5 downto 3);
  VIDEO_ADDRESS(14 downto 10) <=
    (             "00" & HBL & PAGE2 & not PAGE2) when HIRES = '0' else
    (PAGE2 & not PAGE2 &  V(2 downto 0));

  VIDEO_ADDRESS(15) <= '0'; 
  
end rtl;
