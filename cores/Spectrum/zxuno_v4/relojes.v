`timescale 1ps/1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module clock_generator
 (// Clock in ports
  input wire        CLK_IN1,
  input wire [2:0]  pll_option,
  // Clock out ports
  output wire       sysclk,
  output wire       mcolorclk
  );

  reg [2:0] pll_option_stored = 3'b000;
  reg [7:0] pulso_reconf = 8'h01; // force initial reset at boot
  always @(posedge sysclk) begin
    if (pll_option != pll_option_stored) begin
        pll_option_stored <= pll_option;
        pulso_reconf <= 8'h01;
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
      .CLK0OUT(sysclk),
      .CLK1OUT(mcolorclk),
      .CLK2OUT(),
      .CLK3OUT()
   );
endmodule
