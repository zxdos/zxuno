-- file: relojes.vhd
-- 
-- (c) Copyright 2008 - 2011 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
--
------------------------------------------------------------------------------
-- "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
-- "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
------------------------------------------------------------------------------
-- CLK_OUT1_____8.871______0.000______50.0______383.911____221.370
-- CLK_OUT2_____4.435______0.000______50.0______438.870____221.370
-- CLK_OUT3____50.000______0.000______50.0______270.849____221.370
--
------------------------------------------------------------------------------
-- "Input Clock   Freq (MHz)    Input Jitter (UI)"
------------------------------------------------------------------------------
-- __primary__________50.000____________0.010

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity relojes is
port
 (-- Clock in ports
  I_CLK_REF      : in     std_logic;
  I_RESET_L      : in     std_logic;  

  O_CLK_REF      : out    std_logic;
  -- Clock out ports
  O_ENA          : out    std_logic;
  O_CLK          : out    std_logic;
  
  O_RESET_L      : out   std_logic
 );
end relojes;

architecture xilinx of relojes is
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of xilinx : architecture is "relojes,clk_wiz_v3_6,{component_name=relojes,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=PLL_BASE,num_out_clk=3,clkin1_period=20.000,clkin2_period=20.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=AUTO,manual_override=false}";
  -- Input clock buffering / unused connectors
  signal clkin1      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal clkout0          : std_logic;
  signal clkout1          : std_logic;
  signal clkout2_unused   : std_logic;
  signal clkout3_unused   : std_logic;
  signal clkout4_unused   : std_logic;
  signal clkout5_unused   : std_logic;
  
  signal clk              : std_logic;
  signal delay_count      : std_logic_vector(7 downto 0) := (others => '0');
  signal div_cnt          : std_logic_vector(1 downto 0);
  -- Unused status signals

begin


  -- Input buffering
  --------------------------------------
  clkin1_buf : IBUFG
  port map
   (O => clkin1,
    I => I_CLK_REF);


  -- Clocking primitive
  --------------------------------------
  -- Instantiation of the PLL primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  pll_base_inst : PLL_BASE
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "SYSTEM_SYNCHRONOUS",
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT        => 11,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 62, --67 ntsc?
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT1_DIVIDE       => 36,
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
--    CLKOUT2_DIVIDE       => 11,
--    CLKOUT2_PHASE        => 0.000,
--    CLKOUT2_DUTY_CYCLE   => 0.500,
    CLKIN_PERIOD         => 20.000,
    REF_JITTER           => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfbout,
    CLKOUT0             => clkout0,
    CLKOUT1             => clkout1,
    CLKOUT2             => clkout2_unused,
    CLKOUT3             => clkout3_unused,
    CLKOUT4             => clkout4_unused,
    CLKOUT5             => clkout5_unused,
    -- Status and control signals
--    LOCKED              => LOCKED,
    RST                 => not I_RESET_L,
    -- Input clock control
    CLKFBIN             => clkfbout_buf,
    CLKIN               => clkin1);

  -- Output buffering
  -------------------------------------
  clkf_buf : BUFG
  port map
   (O => clkfbout_buf,
    I => clkfbout);


  clkout1_buf : BUFG
  port map
   (O   => clk,
    I   => clkout0);

  clkout2_buf : BUFG
  port map
   (O   => O_CLK_REF,
    I   => clkout1);

--  clkout3_buf : BUFG
--  port map
--   (O   => O_CLK_REF,
--    I   => clkout2);

---

  O_CLK     <= clk;

  p_delay : process(I_RESET_L, clk)
  begin
    if (I_RESET_L = '0') then
      delay_count <= x"00"; 
      O_RESET_L <= '0';
    elsif rising_edge(clk) then
      if (delay_count(7 downto 0) = (x"FF")) then
        delay_count <= (x"FF");
        O_RESET_L <= '1';
      else
        delay_count <= delay_count + "1";
        O_RESET_L <= '0';
      end if;
    end if;
  end process;

  p_clk_div : process(I_RESET_L, clk)
  begin
    if (I_RESET_L = '0') then
      div_cnt <= (others => '0');
    elsif rising_edge(clk) then
      div_cnt <= div_cnt + "1";
    end if;
  end process;

  p_assign_ena : process(div_cnt)
  begin
    O_ENA    <= div_cnt(0);
  end process;


end xilinx;

