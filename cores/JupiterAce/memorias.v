`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:47:33 03/21/2011 
// Design Name: 
// Module Name:    memorias 
// Project Name: 
// Target Device_ns: 
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

module ram1k (
	input wire clk,
    input wire ce,
	input wire [9:0] a,
	input wire [7:0] din,
	output reg [7:0] dout,
	input wire we
	);

    reg [7:0] mem[0:1023];
    always @(posedge clk) begin
        dout <= mem[a];
        if (we == 1'b1 && ce == 1'b1)
            mem[a] <= din;
    end
endmodule

module ram1k_dualport(
	input wire clk,
    input wire ce,
	input wire [9:0] a1,
    input wire [9:0] a2,
	input wire [7:0] din,
	output reg [7:0] dout1,
    output reg [7:0] dout2,
	input wire we
	);

    reg [7:0] mem[0:1023];
    always @(posedge clk) begin
        dout2 <= mem[a2];
        dout1 <= mem[a1];
        if (we == 1'b1 && ce == 1'b1)
            mem[a1] <= din;
    end
endmodule

module ram16k (
	input wire clk,
    input wire ce,
	input wire [13:0] a,
	input wire [7:0] din,
	output reg [7:0] dout,
	input wire we
	);

    reg [7:0] mem[0:16383];
    always @(posedge clk) begin
        dout <= mem[a];
        if (we == 1'b1 && ce == 1'b1)
            mem[a] <= din;
    end
endmodule

module ram32k (
	input wire clk,
    input wire ce,
	input wire [14:0] a,
	input wire [7:0] din,
	output reg [7:0] dout,
	input wire we
	);

    reg [7:0] mem[0:32767];
    always @(posedge clk) begin
        dout <= mem[a];
        if (we == 1'b1 && ce == 1'b1)
            mem[a] <= din;
    end
endmodule
