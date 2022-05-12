`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 01:22:53 2017-06-20 by Miguel Angel Rodriguez Jodar
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

module control_ad724 (
    input wire clk,
    input wire poweron_rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output wire [7:0] dout,
    output wire oe,
    output wire ad724_xtal,
    output wire ad724_mode,
    output wire ad724_enable_gencolorclk
    );

`include "config.vh"
    
    assign oe = (zxuno_addr == CTRLAD724 && zxuno_regrd == 1'b1);    
    assign dout = ad724;
    
    reg [7:0] ad724 = 8'h00;  // initial value
    assign ad724_xtal = ~ad724[0];
    assign ad724_mode = ad724[0];
    assign ad724_enable_gencolorclk = ad724[1];
    
    always @(posedge clk) begin
        if (poweron_rst_n == 1'b0)
            ad724 <= 8'h00;  // or after a hardware reset (not implemented yet)
        else if (zxuno_addr == CTRLAD724 && zxuno_regwr == 1'b1)
            ad724 <= din;
    end
endmodule
