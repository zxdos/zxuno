// file: pll.v
// 
// (c) Copyright 2008 - 2010 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//
//----------------------------------------------------------------------------
// Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
// Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// CLK_OUT1    28.218      0.000       N/A      341.754        N/A
//
//----------------------------------------------------------------------------
// Input Clock   Input Freq (MHz)   Input Jitter (UI)
//----------------------------------------------------------------------------
// primary              50            0.010

`timescale 1ps/1ps

(* CORE_GENERATION_INFO = "pll,clk_wiz_v1_8,{component_name=pll,use_phase_alignment=false,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=true,feedback_source=FDBK_AUTO,primtype_sel=DCM_CLKGEN,num_out_clk=1,clkin1_period=20.000,clkin2_period=20.000,use_power_down=false,use_reset=false,use_locked=false,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=AUTO,manual_override=true}" *)
module pll
 (// Clock in ports
  input wire        CLK_IN1,
  // Clock out ports
  output wire       CLK_OUT1,
  // Dynamic reconfiguration ports
  input wire        PROGCLK,
  input wire        PROGDATA,
  input wire        PROGEN,
  output wire       PROGDONE
 );

  // Input buffering
  //------------------------------------
  wire clkin1;
  IBUFG clkin1_buf
   (.O (clkin1),
    .I (CLK_IN1));


  // Clocking primitive
  //------------------------------------
  // Instantiation of the DCM primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire        locked_int;
  wire [2:1]  status_int;
  wire        clkfx;
  wire        clkfx180_unused;
  wire        clkfxdv_unused;

  DCM_CLKGEN
  #(.CLKFXDV_DIVIDE        (2),
    .CLKFX_DIVIDE          (102),
    .CLKFX_MULTIPLY        (57),
    .SPREAD_SPECTRUM       ("NONE"),
    .STARTUP_WAIT          ("FALSE"),
    .CLKIN_PERIOD          (20.000),
    .CLKFX_MD_MAX          (0.000))
   dcm_clkgen_inst
    // Input clock
   (.CLKIN                 (clkin1),
    // Output clocks
    .CLKFX                 (clkfx),
    .CLKFX180              (clkfx180_unused),
    .CLKFXDV               (clkfxdv_unused),
    // Ports for dynamic reconfiguration
    .PROGCLK               (PROGCLK),
    .PROGDATA              (PROGDATA),
    .PROGEN                (PROGEN),
    .PROGDONE              (PROGDONE),
    // Other control and status signals
    .FREEZEDCM             (1'b0),
    .LOCKED                (locked_int),
    .STATUS                (status_int),
    .RST                   (1'b0));


  // Output buffering
  //-----------------------------------


  BUFG clkout1_buf
   (.O   (CLK_OUT1),
    .I   (clkfx));




endmodule
