`timescale 1ps/1ps
`default_nettype none

/* Change parameters using this online C code: http://goo.gl/Os0cKi */

module clock_generator
 (// Clock in ports
  input wire        CLK_IN1,
  input wire        CPUContention,
  input wire [2:0]  pll_option,
  input wire [1:0]  turbo_enable,
  // Clock out ports
  output wire       CLK_OUT1,
  output wire       CLK_OUT2,
  output wire       CLK_OUT3,
  output wire       CLK_OUT4,
  output wire       cpuclk,
  output wire       cpuclkplain
  );

  wire clkin1_buffered;
  IBUFG BUFG_IN (
      .O(clkin1_buffered),
      .I(CLK_IN1)
  );

  reg [2:0] pll_option_stored = 3'b000;
  reg [7:0] pulso_reconf = 8'h01; // force initial reset at boot
  always @(posedge clkin1_buffered) begin
    if (pll_option != pll_option_stored) begin
        pll_option_stored <= pll_option;
        pulso_reconf <= 8'b00000001;
    end
    else begin
        pulso_reconf <= {pulso_reconf[6:0],1'b0};
    end
  end

  pll_top reconfiguracion_pll
   (
      // SSTEP is the input to start a reconfiguration.  It should only be
      // pulsed for one clock cycle.
      .SSTEP(pulso_reconf[7]),
      // STATE determines which state the PLL_ADV will be reconfigured to.  A
      // value of 0 correlates to state 1, and a value of 1 correlates to state
      // 2.
      .STATE(pll_option_stored),
      // RST will reset the entire reference design including the PLL_ADV
      .RST(1'b0),
      // CLKIN is the input clock that feeds the PLL_ADV CLKIN as well as the
      // clock for the PLL_DRP module
      .CLKIN(clkin1_buffered),
      // SRDY pulses for one clock cycle after the PLL_ADV is locked and the
      // PLL_DRP module is ready to start another re-configuration
      .SRDY(),

      // These are the clock outputs from the PLL_ADV.
      .CLK0OUT(CLK_OUT1),
      .CLK1OUT(CLK_OUT2),
      .CLK2OUT(CLK_OUT3),
      .CLK3OUT(CLK_OUT4)
   );

  wire cpuclk_selected, cpuclk_3_2, cpuclk_1_0;

//  BUFGMUX speed_3_and_2 (  // 28MHz and 14MHz for CPU
//    .O(cpuclk_3_2),
//    .I0(CLK_OUT2),
//    .I1(CLK_OUT1),
//    .S(turbo_enable[0])
//    );
//
//  BUFGMUX speed_1_and_0 (  // 7MHz and 3.5MHz for CPU
//    .O(cpuclk_1_0),
//    .I0(CLK_OUT4),
//    .I1(CLK_OUT3),
//    .S(turbo_enable[0])
//    );
//
//  BUFGMUX cpuclk_selector (
//    .O(cpuclk_selected),
//    .I0(cpuclk_1_0),
//    .I1(/*cpuclk_3_2*/CLK_OUT2),
//    .S(turbo_enable[1])
//    );
//
//  BUFGMUX aplicar_contienda (
//        .O(cpuclk),
//        .I0(cpuclk_selected),     // when no contention, clock is this one
//        .I1(1'b1),       // during contention, clock is pulled up
//        .S(CPUContention)  // contention signal
//        );

  reg [2:0] clkdivider = 3'b000;
  always @(posedge CLK_OUT1)
    clkdivider <= clkdivider + 3'd1;

  BUFGMUX speed_3_and_2 (  // 28MHz and 14MHz for CPU
    .O(cpuclk_3_2),
    .I0(clkdivider[0]),
    .I1(CLK_OUT1),
    .S(turbo_enable[0])
    );

  BUFGMUX speed_1_and_0 (  // 7MHz and 3.5MHz for CPU
    .O(cpuclk_1_0),
    .I0(clkdivider[2]),
    .I1(clkdivider[1]),
    .S(turbo_enable[0])
    );

  BUFGMUX cpuclk_selector (
    .O(cpuclk_selected),
    .I0(cpuclk_1_0),
    .I1(/*cpuclk_3_2*/clkdivider[0]),
    .S(turbo_enable[1])
    );

  BUFGMUX aplicar_contienda (
    .O(cpuclk),
    .I0(cpuclk_selected),     // when no contention, clock is this one
    .I1(1'b1),       // during contention, clock is pulled up
    .S(CPUContention)  // contention signal
    );

  assign cpuclkplain = cpuclk_selected;
endmodule
