`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:09:00 17/01/2021 
// Design Name: 
// Module Name:    monochrome
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File modified by Fernando Mosquera
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module monochrome (
  input wire [1:0] monochrome_selection,
  input wire [5:0] ri,
  input wire [5:0] gi,
  input wire [5:0] bi,
  output reg [5:0] ro,
  output reg [5:0] go,
  output reg [5:0] bo  
  );
  
  // Escala monocromatica especifica para la paleta original 
  // de Spectrum. 
  wire [9:0] r_in, g_in, b_in;
  wire [9:0] y_out;
  
  assign r_in = {ri,ri[5:3],1'b0};
  assign g_in = {gi,gi[5:3],1'b0};
  assign b_in = {bi,bi[5:3],1'b0};
	
  // Equivale a la formula y=0.299r+0.587g+0.114b; 
  assign y_out = (r_in>>2)+(r_in>>5)+(g_in>>1)+(g_in>>4)+(b_in>>4)+(b_in>>4);
		
  always @(*)
	 begin
		case (monochrome_selection)
			2'b00  : begin    // color
							ro	= ri; 
							go = gi;
							bo = bi;
						end
			2'b01  : begin   // gray
							ro = y_out[9:4];
				         go = y_out[9:4];
							bo = y_out[9:4];
						end
			2'b10  : begin  // orange
							ro = y_out[9:4];
				         go = {2'b00,y_out[9:6]};
							bo = {4'b0000,y_out[9:8]};
						end
			2'b11  : begin //green 
							ro = 6'b000000;
				         go = y_out[9:4];
							bo = 6'b000000;
						end
		endcase
	end 

endmodule