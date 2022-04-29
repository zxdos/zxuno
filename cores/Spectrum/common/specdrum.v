`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 23:58:32 2017-02-03 by Miguel Angel Rodriguez Jodar
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

module specdrum (
   input wire clk,
   input wire rst_n,
   input wire [15:0] a,
   input wire iorq_n,
   input wire wr_n,
   input wire [7:0] d,
   output reg [7:0] specdrum_out
   );

   always @(posedge clk) begin
      if (rst_n == 1'b0)
        specdrum_out <= 8'h00;
      else if (iorq_n == 1'b0 && (a[7:0] == 8'hDF || a[7:0] == 8'hFB) && wr_n == 1'b0)
        specdrum_out <= d;
   end
endmodule
