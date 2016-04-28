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

module ram1k(
	input wire clk,
	input wire [9:0] a,
	input wire [7:0] din,
	output wire [7:0] dout,
	input wire ce_n,
	input wire oe_n,
	input wire we_n
	);

	reg [7:0] dato;
	reg [7:0] mem[0:1023];
    wire ce = ~ce_n;
    wire we = ~we_n;
	
	assign dout = (oe_n | ce_n)? 8'bzzzzzzzz : dato;
	
	always @(posedge clk) begin
        if (ce == 1'b1) begin
            if (we == 1'b0)
                dato <= mem[a];
            else 
                mem[a] <= din;	
        end
    end
endmodule

module ram16k(
	input wire clk,
	input wire [13:0] a,
	input wire [7:0] din,
	output wire [7:0] dout,
	input wire ce_n,
	input wire oe_n,
	input wire we_n
	);

	reg [7:0] dato;
	reg [7:0] mem[0:16383];
    wire ce = ~ce_n;
    wire we = ~we_n;
	
	assign dout = (oe_n | ce_n)? 8'bzzzzzzzz : dato;
	
	always @(posedge clk) begin
        if (ce == 1'b1) begin
            if (we == 1'b0)
                dato <= mem[a];
            else 
                mem[a] <= din;	
        end
    end
endmodule
