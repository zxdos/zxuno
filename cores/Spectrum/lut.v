`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:40:28 02/17/2014 
// Design Name: 
// Module Name:    lut 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lut(
    input wire clk,
    input wire load,
    input wire [7:0] din,
    input wire [5:0] a1,
    input wire [5:0] a2,
    input wire [5:0] a3,
    output wire [7:0] do1,
    output wire [7:0] do2,
    output wire [7:0] do3
    );

   reg [7:0] lut[0:63];
   assign do1 = lut[a1];
   assign do2 = lut[a2];
   assign do3 = lut[a3];
   
   always @(posedge clk)
      if (load)
         lut[a3] <= din;

endmodule
