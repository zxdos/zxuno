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
module scandoubler_ctrl (
    input wire clk,
    input wire [15:0] a,
    input wire kbd_change_video_output,
    input wire iorq_n,
    input wire wr_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output wire oe_n,
    output wire vga_enable,
    output wire scanlines_enable,
    output wire [2:0] freq_option,
    output wire [1:0] turbo_enable,
    output wire csync_option
    );

    parameter SCANDBLCTRL = 8'h0B;
    parameter PRISMSPEEDCTRL = 16'h8e3b;  // PRISM speed control: bits D0-D3. We use TURBO=1 if D0-D3>0
    
    assign oe_n = ~(zxuno_addr == SCANDBLCTRL && zxuno_regrd == 1'b1);
    
    assign vga_enable = scandblctrl[0];
    assign scanlines_enable = scandblctrl[1];
    assign freq_option = scandblctrl[4:2];
    assign turbo_enable = scandblctrl[7:6];
    assign csync_option = scandblctrl[5];
    
    reg [7:0] scandblctrl = 8'h00;  // initial value
    reg [1:0] kbd_change_video_edge_detect = 2'b00;

    always @(posedge clk) begin
        kbd_change_video_edge_detect <= {kbd_change_video_edge_detect[0], kbd_change_video_output};
        if (zxuno_addr == SCANDBLCTRL && zxuno_regwr == 1'b1)
            scandblctrl <= din;
        else if (iorq_n == 1'b0 && wr_n == 1'b0 && a == PRISMSPEEDCTRL)
            scandblctrl <= {din[1:0], scandblctrl[5:0]};
        else if (kbd_change_video_edge_detect == 2'b01) begin
            scandblctrl <= {scandblctrl[7:5], ((scandblctrl[0] == 1'b0)? 3'b111 : 3'b000), scandblctrl[1], ~scandblctrl[0]};
        end
        dout <= scandblctrl;
    end
endmodule
