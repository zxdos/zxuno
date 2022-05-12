`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 18:22:21 2015-06-07 by Miguel Angel Rodriguez Jodar
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

module coreid (
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire regaddr_changed,
    output reg [7:0] dout,
    output wire oe
    );

`include "config.vh"

    reg [7:0] text[0:15];
    integer i;
    initial begin 
      for (i=0;i<16;i=i+1) begin :gencoreid
        text[i] = COREID_STRING[(16-i)*8-1 -:8];
      end
    end      
    
    reg [3:0] textindx = 4'h0;
    reg reading = 1'b0;
    assign oe = (zxuno_addr == IDSTRING && zxuno_regrd==1'b1);
    
    always @(posedge clk) begin
        if (rst_n == 1'b0 || (regaddr_changed==1'b1 && zxuno_addr==IDSTRING)) begin
            textindx <= 4'h0;
            reading <= 1'b0;
        end
        else if (oe==1'b1) begin
            reading <= 1'b1;
        end
        else if (reading == 1'b1 && oe==1'b0) begin
            reading <= 1'b0;
            textindx <= textindx + 1;
        end
        dout <= text[textindx];
    end
endmodule
