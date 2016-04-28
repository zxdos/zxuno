`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:22:53 06/15/2015 
// Design Name: 
// Module Name:    scratch_register 
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
module scratch_register(
    input wire clk,
    input wire poweron_rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output wire oe_n
    );

    parameter SCRATCH = 8'hFE;
    
    assign oe_n = ~(zxuno_addr == SCRATCH && zxuno_regrd == 1'b1);
    reg [7:0] scratch = 8'h00;  // initial value
    always @(posedge clk) begin
        if (poweron_rst_n == 1'b0)
            scratch <= 8'h00;  // or after a hardware reset (not implemented yet)
        else if (zxuno_addr == SCRATCH && zxuno_regwr == 1'b1)
            scratch <= din;
        dout <= scratch;
    end
endmodule
