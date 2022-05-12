`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 01:22:22 2020-02-09 by Miguel Angel Rodriguez Jodar
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

module clk_enables (
  input wire clk,
	input wire CPUContention,
  input wire [3:0] cpu_speed,
	output wire clk14en,
	output wire clk7en,
	output wire clk7en_n,
	output wire clk35en,
	output wire clk35en_n,
	output wire clk175en,
	output reg clkcpu_enable
  );

`include "config.vh"

// 28 MHz master clock
  reg [15:0] divclk = 16'h00000001;
  always @(posedge clk)
    divclk <= {divclk[14:0], divclk[15]};
  assign clk14en   = divclk[0] | divclk[2] | divclk[4] | divclk[6] | divclk[8] | divclk[10] | divclk[12] | divclk[14];
  assign clk7en    = divclk[0] | divclk[4] | divclk[8] | divclk[12];
  assign clk7en_n  = divclk[2] | divclk[6] | divclk[10] | divclk[14];
  assign clk35en   = divclk[0] | divclk[8];
  assign clk35en_n = divclk[7] | divclk[15];
  assign clk175en  = divclk[0];

// This is to support 56 MHz master clock. Didn't meet timing closure on UNO
//  reg [31:0] divclk = 32'h00000001;
//  always @(posedge clk)
//    divclk <= {divclk[30:0], divclk[31]};
//  assign clk28en   = divclk[0] | divclk[2] | divclk[4] | divclk[6] | divclk[8] | divclk[10] | divclk[12] | divclk[14] | divclk[16] | divclk[18] | divclk[20] | divclk[22] | divclk[24] | divclk[26] | divclk[28] | divclk[30];
//  assign clk14en   = divclk[0] | divclk[4] | divclk[8] | divclk[12] | divclk[16] | divclk[20] | divclk[24] | divclk[28];
//  assign clk7en    = divclk[0] | divclk[8] | divclk[16] | divclk[24];
//  assign clk7nen   = divclk[4] | divclk[12] | divclk[20] | divclk[28];
//  assign clk35en   = divclk[0] | divclk[16];
//  assign clk35en_n = divclk[15] | divclk[31];
//	assign clk175en  = divclk[0];

// This is to support 42 MHz master clock. Unfortunately, it looks ugly when VGA is used :(
//  reg [23:0] divclk = 24'h000001;
//  always @(posedge clk)
//    divclk <= {divclk[22:0], divclk[23]};
//  assign clk28en   = divclk[0] | divclk[1] | divclk[3] | divclk[4] | divclk[6] | divclk[7] | divclk[9] | divclk[10] | divclk[12] | divclk[13] | divclk[15] | divclk[16] | divclk[18] | divclk[19] | divclk[21] | divclk[22];
//  assign clk14en   = divclk[0] | divclk[3] | divclk[6] | divclk[9] | divclk[12] | divclk[15] | divclk[18] | divclk[21];
//  assign clk7en    = divclk[0] | divclk[6] | divclk[12] | divclk[18];
//  assign clk7nen   = divclk[3] | divclk[9] | divclk[15] | divclk[21];
//  assign clk35en   = divclk[0] | divclk[12];
//  assign clk35en_n = divclk[23] | divclk[11];
//  assign clk175en  = divclk[0];

`ifdef CPU_TURBO_OPTION  
  always @* begin
    casez (cpu_speed[2:0])
      3'b1?? : clkcpu_enable = 1'b1;
      3'b000 : clkcpu_enable = clk35en && !CPUContention;
      3'b001 : clkcpu_enable = clk7en;
      3'b010 : clkcpu_enable = clk14en;
      3'b011 : clkcpu_enable = 1'b1;
    endcase
  end
`else
  always @*
    clkcpu_enable = clk35en && !CPUContention;  
`endif
    
endmodule
