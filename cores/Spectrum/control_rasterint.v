`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:24:57 12/06/2015 
// Design Name: 
// Module Name:    control_rasterint 
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

module rasterint_ctrl (
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe_n,
    output wire rasterint_enable,
    output wire vretraceint_disable,
    output wire [8:0] raster_line,
    input wire raster_int_in_progress
    );

    parameter RASTERLINE = 8'h0C;
    parameter RASTERCTRL = 8'h0D;

    reg [7:0] rasterline_reg = 8'hFF;
    reg raster_enable = 1'b0;
    reg vretrace_disable = 1'b0;
    reg raster_8th_bit = 1'b1;      
    
    assign raster_line = {raster_8th_bit, rasterline_reg};
    assign rasterint_enable = raster_enable;
    assign vretraceint_disable = vretrace_disable;
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            raster_enable <= 1'b0;
            vretrace_disable <= 1'b0;
            raster_8th_bit <= 1'b1;
            rasterline_reg <= 8'hFF;
        end
        else begin
            if (zxuno_addr == RASTERLINE && zxuno_regwr == 1'b1)
                rasterline_reg <= din;
            if (zxuno_addr == RASTERCTRL && zxuno_regwr == 1'b1)
                {vretrace_disable, raster_enable, raster_8th_bit} <= din[2:0];
        end
    end
    
    always @* begin
        dout = 8'hFF;
        oe_n = 1'b1;
        if (zxuno_addr == RASTERLINE && zxuno_regrd == 1'b1) begin
            dout = rasterline_reg;
            oe_n = 1'b0;
        end
        if (zxuno_addr == RASTERCTRL && zxuno_regrd == 1'b1) begin
            dout = {raster_int_in_progress, 4'b0000, vretrace_disable, raster_enable, raster_8th_bit};
            oe_n = 1'b0;
        end
    end
endmodule
