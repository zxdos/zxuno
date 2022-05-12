`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 01:22:53 2015-06-15 by Miguel Angel Rodriguez Jodar
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

`include "config.vh"
    
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
