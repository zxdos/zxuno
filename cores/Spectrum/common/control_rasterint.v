`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 19:24:57 2015-06-12 by Miguel Angel Rodriguez Jodar
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

module rasterint_ctrl (
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe,
    output wire rasterint_enable,
    output wire vretraceint_disable,
    output wire [8:0] raster_line,
    input wire raster_int_in_progress
    );

`include "config.vh"

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
        oe = 1'b0;
        if (zxuno_addr == RASTERLINE && zxuno_regrd == 1'b1) begin
            dout = rasterline_reg;
            oe = 1'b1;
        end
        if (zxuno_addr == RASTERCTRL && zxuno_regrd == 1'b1) begin
            dout = {raster_int_in_progress, 4'b0000, vretrace_disable, raster_enable, raster_8th_bit};
            oe = 1'b1;
        end
    end
endmodule
