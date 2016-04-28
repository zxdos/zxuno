`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:33:13 04/27/2014 
// Design Name: 
// Module Name:    turbosound 
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
module turbosound (
    input wire clk7,
    input wire clkay,
    input wire reset_n,
    input wire bdir,
    input wire bc1,
    input wire [7:0] din,
    output wire [7:0] dout,
    output wire oe_n,
    output wire [7:0] audio_out_ay1,
    output wire [7:0] audio_out_ay2
    );

	reg ay_select = 1'b1;
	always @(posedge clk7 or negedge reset_n) begin
		if (reset_n==1'b0)
			ay_select <= 1'b1;
		else if (bdir && bc1 && din[7:1]==7'b1111111)
			ay_select <= din[0];
	end

	wire oe_n_ay1, oe_n_ay2;
	wire [7:0] dout_ay1, dout_ay2;
	assign dout = (ay_select)? dout_ay1 : dout_ay2;
	assign oe_n = (ay_select)? oe_n_ay1 : oe_n_ay2;

YM2149 ay1 (
  .I_DA(din),
  .O_DA(dout_ay1),
  .O_DA_OE_L(oe_n_ay1),
  .I_A9_L(1'b0),
  .I_A8(ay_select),
  .I_BDIR(bdir),
  .I_BC2(1'b1),
  .I_BC1(bc1),
  .I_SEL_L(1'b0),
  .O_AUDIO(audio_out_ay1),
  .I_IOA(8'h00),
  .O_IOA(),
  .O_IOA_OE_L(),
  .I_IOB(8'h00),
  .O_IOB(),
  .O_IOB_OE_L(),
  .ENA(1'b1),
  .RESET_L(reset_n),
  .CLK(clkay)
  );

YM2149 ay2 (
  .I_DA(din),
  .O_DA(dout_ay2),
  .O_DA_OE_L(oe_n_ay2),
  .I_A9_L(1'b0),
  .I_A8(~ay_select),
  .I_BDIR(bdir),
  .I_BC2(1'b1),
  .I_BC1(bc1),
  .I_SEL_L(1'b0),
  .O_AUDIO(audio_out_ay2),
  .I_IOA(8'h00),
  .O_IOA(),
  .O_IOA_OE_L(),
  .I_IOB(8'h00),
  .O_IOB(),
  .O_IOB_OE_L(),
  .ENA(1'b1),
  .RESET_L(reset_n),
  .CLK(clkay)
  );

endmodule
