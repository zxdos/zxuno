`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 02:57:39 2018-02-19 by Miguel Angel Rodriguez Jodar
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

module board_capabilities (
    input wire clk,
    input wire poweron_rst_n,
    input wire in_boot_mode,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [2:0] fpga_model,
    input wire [7:0] din,
    output wire [7:0] dout,
    output wire oe,
    output wire [1:0] current_value
    );

`include "config.vh"
    
    assign oe = (zxuno_addr == MEMREPORT && zxuno_regrd == 1'b1);
    reg [1:0] memreport = 2'b00;  // initial value
    assign dout = {3'b000, fpga_model, memreport};
    
    assign current_value = memreport[1:0];

    always @(posedge clk) begin
        if (poweron_rst_n == 1'b0)
            memreport <= 2'b00;  // or after a hardware reset (not implemented yet)
        else if (zxuno_addr == MEMREPORT && zxuno_regwr == 1'b1 && in_boot_mode == 1'b1)
            memreport <= din[1:0];
    end
endmodule
