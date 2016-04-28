----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:42:09 02/09/2013 
-- Design Name: 
-- Module Name:    Top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top is
    port (

        -- Standard 6847 signals
        --
        -- expept DA which is now input only
        -- except nRP which re-purposed as a nWR
        
        CLK    : in    std_logic;
        DD     : inout std_logic_vector (7 downto 0);
        DA     : in    std_logic_vector (12 downto 0);
        CHB    : out   std_logic;
        OA     : out   std_logic;
        OB     : out   std_logic;
        nMS    : in    std_logic;
        CSS    : in    std_logic;
        nHS    : out   std_logic;
        nFS    : out   std_logic;
        nWR    : in    std_logic;       -- Was nRP
        AG     : in    std_logic;
        AS     : in    std_logic;
        INV    : in    std_logic;
        INTEXT : in    std_logic;
        GM     : in    std_logic_vector (2 downto 0);
        Y      : out   std_logic;

        -- 5 bit VGA Output

        R     : out std_logic_vector (0 downto 0);
        G     : out std_logic_vector (1 downto 0);
        B     : out std_logic_vector (0 downto 0);
        HSYNC : out std_logic;
        VSYNC : out std_logic;
        
        -- 1 bit AUDIO Output
        AUDIO : out std_logic;
        
        -- Other GODIL specific pins

        clock49 : in std_logic;
        nRST : in std_logic;

        nBXXX : in std_logic;

        -- Jumpers
        
        -- Enables VGA Signals on PL4
        nPL4 : in std_logic;
        
        -- Moves SID from 9FE0 to BDC0 
        nSIDD : in std_logic;
        
        -- Active low version of the SID Select Signal for disabling the external bus buffers
        -- nSIDSEL : out std_logic;
        
        -- PS/2 Mouse
        PS2_CLK : inout std_logic;
        PS2_DATA : inout std_logic;

        -- UART
        uart_TxD : out std_logic;
        uart_RxD : in  std_logic
        
        );
end Top;

architecture BEHAVIORAL of Top is

    -- clock32 is the main clock
    signal clock32 : std_logic;
    
    -- clock25 is a full speed VGA clock
    signal clock25 : std_logic;
    
    -- clock15 is just used between two DCMs
    signal clock15 : std_logic;
    
    -- Reset signal (active high)
    signal reset : std_logic;
    
    -- Reset signal to 6847 (active high), not currently used
    signal reset_vid : std_logic;

    -- pipelined versions of the address/data/write signals
    signal nWR1 : std_logic;
    signal nWR2 : std_logic;
    signal nMS1 : std_logic;
    signal nMS2 : std_logic;
    signal nWRMS1 : std_logic;
    signal nWRMS2 : std_logic;
    signal nBXXX1 : std_logic;
    signal nBXXX2 : std_logic;
    signal DA1  : std_logic_vector (12 downto 0);
    signal DA2  : std_logic_vector (12 downto 0);
    signal DD1  : std_logic_vector (7 downto 0);
    signal DD2  : std_logic_vector (7 downto 0);
    signal DD3  : std_logic_vector (7 downto 0);

    
    signal ram_we : std_logic;
    signal addr   : std_logic_vector (12 downto 0);
    signal din    : std_logic_vector (7 downto 0);

    -- Dout back to the Atom, that is either VRAM or SID
    signal dout  : std_logic_vector (7 downto 0);

    -- SID sigmals
    signal sid_cs : std_logic;
    signal sid_we : std_logic;
    signal sid_audio : std_logic;

    -- UART sigmals
    signal uart_cs       : std_logic;
    signal uart_we       : std_logic;
    
    -- Atom extension register signals
    signal reg_cs : std_logic;
    signal reg_we : std_logic;

    signal final_red     : std_logic;
    signal final_green1  : std_logic;
    signal final_green0  : std_logic;
    signal final_blue    : std_logic;
    signal final_vsync   : std_logic;
    signal final_hsync   : std_logic;
    signal final_char_a  : std_logic_vector (10 downto 0);
    
    component DCM0
        port(
            CLKIN_IN  : in  std_logic;
            CLK0_OUT  : out std_logic;
            CLK0_OUT1 : out std_logic;
            CLK2X_OUT : out std_logic
            );
    end component;

    component DCMSID0
        port(
            CLKIN_IN  : in  std_logic;
            CLK0_OUT  : out std_logic;
            CLK0_OUT1 : out std_logic;
            CLK2X_OUT : out std_logic
            );
    end component;

    component DCMSID1
        port(
            CLKIN_IN  : in  std_logic;
            CLK0_OUT  : out std_logic;
            CLK0_OUT1 : out std_logic;
            CLK2X_OUT : out std_logic
            );
    end component;

    component AtomGodilVideo
        generic (
           CImplGraphicsExt : boolean;
           CImplSoftChar    : boolean;
           CImplSID         : boolean;
           CImplVGA80x40    : boolean;
           CImplHWScrolling : boolean;
           CImplMouse       : boolean;
           CImplUart        : boolean;
           CImplDoubleVideo : boolean;
           MainClockSpeed   : integer;
           DefaultBaud      : integer
        );
        port (
            -- clock_vga is a full speed VGA clock (25MHz ish)      
            clock_vga      : in    std_logic;
    
            -- clock_main is the main clock    
            clock_main      : in    std_logic;
        
            -- A fixed 32MHz clock for the SID
            clock_sid_32MHz  : in    std_logic;
    
            -- As fast a clock as possible for the SID DAC
            clock_sid_dac  : in    std_logic;
    
            -- Reset signal (active high)
            reset        : in    std_logic;
    
            -- Reset signal to 6847 (active high), not currently used
            reset_vid    : in    std_logic;
            
            -- Main Address / Data Bus
            din          : in    std_logic_vector (7 downto 0);
            dout         : out   std_logic_vector (7 downto 0);
            addr         : in    std_logic_vector (12 downto 0);
    
            -- 6847 Control Signals
            CSS          : in    std_logic;
            AG           : in    std_logic;
            GM           : in    std_logic_vector (2 downto 0);
            nFS          : out   std_logic;
    
            -- RAM signals
            ram_we       : in    std_logic;
    
            -- SID signals
            reg_cs       : in    std_logic;
            reg_we       : in    std_logic;
    
            -- SID signals
            sid_cs       : in    std_logic;
            sid_we       : in    std_logic;
            sid_audio    : out   std_logic;
            
            -- PS/2 Mouse
            PS2_CLK      : inout std_logic;
            PS2_DATA     : inout std_logic;

            -- UART signals
            uart_cs      : in    std_logic;
            uart_we      : in    std_logic;
            uart_RxD     : in    std_logic;
            uart_TxD     : out   std_logic;     
            uart_escape  : out   std_logic;
            uart_break   : out   std_logic;  
            
            -- VGA Signals
            final_red    : out   std_logic;
            final_green1 : out   std_logic;
            final_green0 : out   std_logic;
            final_blue   : out   std_logic;
            final_vsync  : out   std_logic;
            final_hsync  : out   std_logic
    
            );
    end component;


begin

    reset <= not nRST;
    reset_vid <= '0';

    -- Currently set at 49.152 * 8 / 31 = 12.684MHz
    -- half VGA should be 25.175 / 2 = 12. 5875
    -- we could get closer with to cascaded multipliers
    Inst_DCM0 : DCM0
        port map (
            CLKIN_IN  => clock49,
            CLK0_OUT  => clock25,
            CLK0_OUT1 => open,
            CLK2X_OUT => open
            );

    Inst_DCMSID0 : DCMSID0
        port map (
            CLKIN_IN  => clock49,
            CLK0_OUT  => clock15,
            CLK0_OUT1 => open,
            CLK2X_OUT => open
            );
            
    Inst_DCMSID1 : DCMSID1
        port map (
            CLKIN_IN  => clock15,
            CLK0_OUT  => clock32,
            CLK0_OUT1 => open,
            CLK2X_OUT => open
            );
            
    Inst_AtomGodilVideo : AtomGodilVideo
        generic map (
           CImplGraphicsExt => true,
           CImplSoftChar    => true,
           CImplSID         => true,
           CImplVGA80x40    => true,
           CImplHWScrolling => true,
           CImplMouse       => true,
           CImplUart        => true,
           CImplDoubleVideo => true,
           MainClockSpeed   => 32000000,
           DefaultBaud      => 115200          
        )
      
        port map (
            clock_vga => clock25,
            clock_main => clock32,
            clock_sid_32Mhz => clock32,
            clock_sid_dac => clock49,
            reset => reset,
            reset_vid => reset_vid,
            din => din,
            dout => dout,
            addr => addr,
            CSS => CSS,
            AG => AG,
            GM => GM,
            nFS => nFS,
            ram_we => ram_we,
            reg_cs => reg_cs,
            reg_we => reg_we,
            sid_cs => sid_cs,
            sid_we => sid_we,
            sid_audio => sid_audio,
            PS2_CLK => PS2_CLK,
            PS2_DATA => PS2_DATA,
            uart_cs => uart_cs,
            uart_we => uart_we,
            uart_RxD => uart_RxD,
            uart_TxD => uart_TxD,
            uart_escape => open,
            uart_break => open,
            final_red => final_red,
            final_green1 => final_green1,
            final_green0 => final_green0,
            final_blue => final_blue,
            final_vsync => final_vsync,
            final_hsync => final_hsync
            );

    
    -- Pipelined version of address/data/write signals
    process (clock32)
    begin
        if rising_edge(clock32) then
            nBXXX2 <= nBXXX1;
            nBXXX1 <= nBXXX;
            nMS2 <= nMS1;
            nMS1 <= nMS;
            nWRMS2 <= nWRMS1;
            nWRMS1 <= nWR or nMS;
            nWR2 <= nWR1;
            nWR1 <= nWR;
            DD3  <= DD2;
            DD2  <= DD1;
            DD1  <= DD;
            DA2  <= DA1;
            DA1  <= DA;
        end if;
    end process;

    -- Signals driving the VRAM
    -- Write just before the rising edge of nWR
    ram_we <= '1' when (nWRMS1 = '1' and nWRMS2 = '0' and nBXXX2 = '1') else '0';
    din    <= DD3;
    addr   <= DA2;
    
    -- Signals driving the internal registers
    -- When nSIDD=0 the registers are mapped to BDE0-BDFF
    -- When nSIDD=1 the registers are mapped to 9FE0-9FFF
    reg_cs <= '1' when (nSIDD = '1' and nMS2 = '0' and DA2(12 downto 5) =  "11111111") or
                       (nSIDD = '0' and nBXXX2 = '0' and DA2(11 downto 5) = "1101111") 
                  else '0';

    reg_we <= '1' when (nSIDD = '1' and nWRMS1 = '1' and nWRMS2 = '0') or
                       (nSIDD = '0' and nWR1 = '1' and nWR2 = '0')
                  else '0';
    
    -- Signals driving the SID
    -- When nSIDD=0 the SID is mapped to BDC0-BDDF
    -- When nSIDD=1 the SID is mapped to 9FC0-9FDF
    sid_cs <= '1' when (nSIDD = '1' and nMS2 = '0' and DA2(12 downto 5) =  "11111110") or
                       (nSIDD = '0' and nBXXX2 = '0' and DA2(11 downto 5) = "1101110") 
                  else '0';

    sid_we <= '1' when (nSIDD = '1' and nWRMS1 = '1' and nWRMS2 = '0') or
                       (nSIDD = '0' and nWR1 = '1' and nWR2 = '0')
                  else '0';


    -- Signals driving the UART
    -- When nSIDD=0 the UART is mapped to BDB0-BDBF
    -- When nSIDD=1 the UART is mapped to 9FB0-9FBF
    uart_cs <= '1' when (nSIDD = '1' and nMS2 = '0' and DA2(12 downto 4) =  "111111011") or
                        (nSIDD = '0' and nBXXX2 = '0' and DA2(11 downto 4) = "11011011") 
                   else '0';

    uart_we <= '1' when (nSIDD = '1' and nWRMS1 = '1' and nWRMS2 = '0') or
                        (nSIDD = '0' and nWR1 = '1' and nWR2 = '0')
                   else '0';
    
    AUDIO <= sid_audio;

    -- Output the SID Select Signal so it can be used to disable the bus buffers
    -- TODO: this looks incorrect
    -- nSIDSEL <= not sid_cs;
    
    -- Tri-state data back to the Atom
    DD    <= dout when (nMS = '0' and nWR = '1') else (others => 'Z');
    
    -- 1/1/1 Bit RGB Video to PL4 Connectors
    OA  <= final_red    when nPL4 = '0' else '0';
    CHB <= final_green1 when nPL4 = '0' else '0';
    OB  <= final_blue   when nPL4 = '0' else '0';
    nHS <= final_hsync  when nPL4 = '0' else '0';
    Y   <= final_vsync  when nPL4 = '0' else '0';
    
    -- 1/2/1 Bit RGB Video to GODIL Test Connector
    R(0)  <= final_red;
    G(1)  <= final_green1;
    G(0)  <= final_green0;
    B(0)  <= final_blue;
    VSYNC <= final_vsync;
    HSYNC <= final_hsync;
    
        
end BEHAVIORAL;

