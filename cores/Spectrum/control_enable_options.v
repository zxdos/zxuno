`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:24:56 05/08/2016 
// Design Name: 
// Module Name:    control_enable_options 
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
module control_enable_options(
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output wire oe_n,
    output wire disable_ay,
    output wire disable_turboay,
    output wire disable_7ffd,
    output wire disable_1ffd,
    output wire disable_romsel7f,
    output wire disable_romsel1f,
    output wire enable_timexmmu,
    output wire disable_spisd
    );

    parameter DEVOPTIONS = 8'h0E;
    
    assign oe_n = ~(zxuno_addr == DEVOPTIONS && zxuno_regrd == 1'b1);
    reg [7:0] devoptions = 8'h00;  // initial value
    assign disable_ay = devoptions[0];
    assign disable_turboay = devoptions[1];
    assign disable_7ffd = devoptions[2];
    assign disable_1ffd = devoptions[3];
    assign disable_romsel7f = devoptions[4];
    assign disable_romsel1f = devoptions[5];
    assign enable_timexmmu = devoptions[6];
    assign disable_spisd = devoptions[7];
    always @(posedge clk) begin
        if (rst_n == 1'b0)
            devoptions <= 8'h00;  // or after a hardware reset (not implemented yet)
        else if (zxuno_addr == DEVOPTIONS && zxuno_regwr == 1'b1)
            devoptions <= din;
        dout <= devoptions;
    end
endmodule
