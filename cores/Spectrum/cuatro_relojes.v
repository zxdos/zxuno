`timescale 1ps/1ps
`default_nettype none

/* Change parameters using this online C code: http://goo.gl/Os0cKi */

module clock_generator
 (// Clock in ports
  input wire        CLK_IN1,
  input wire        CPUContention,
  input wire [2:0]  pll_option,
  input wire        turbo_enable,
  // Clock out ports
  output wire       CLK_OUT1,
  output wire       CLK_OUT2,
  output wire       CLK_OUT3,
  output wire       CLK_OUT4,
  output wire       cpuclk
  );
  
  wire cpuclk_selected;
  
  reg [2:0] pll_option_stored = 3'b000;
  reg [7:0] pulso_reconf = 8'h01; // force initial reset at boot
  always @(posedge CLK_IN1) begin
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
      .CLKIN(CLK_IN1),
      // SRDY pulses for one clock cycle after the PLL_ADV is locked and the 
      // PLL_DRP module is ready to start another re-configuration
      .SRDY(),
      
      // These are the clock outputs from the PLL_ADV.
      .CLK0OUT(CLK_OUT1),
      .CLK1OUT(CLK_OUT2),
      .CLK2OUT(CLK_OUT3),
      .CLK3OUT(CLK_OUT4)
   );

  BUFGMUX cpuclk_selector (
    .O(cpuclk_selected),
    .I0(CLK_OUT4),
    .I1(CLK_OUT3),
    .S(turbo_enable)
    );
  
  BUFGMUX selector_reloj_cpu (
        .O(cpuclk),
        .I0(cpuclk_selected),     // when no contention, clock is this one
        .I1(1'b1),       // during contention, clock is pulled up
        .S(CPUContention)  // contention signal
        );
    

endmodule
