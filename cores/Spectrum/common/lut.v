`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 03:40:28 2014-02-17 by Miguel Angel Rodriguez Jodar
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

module lut (
    input wire clk,
    input wire load,
    input wire [7:0] din,
    input wire [5:0] a1,
    input wire [5:0] a2,
    input wire [5:0] a3,
    output wire [7:0] do1,
    output wire [7:0] do2,
    output wire [7:0] do3
    );

    reg [7:0] lut[0:63];
    assign do1 = lut[a1];
    assign do2 = lut[a2];
    assign do3 = lut[a3];
   
    always @(posedge clk) begin
      if (load == 1'b1)
        lut[a3] <= din;
    end
endmodule
