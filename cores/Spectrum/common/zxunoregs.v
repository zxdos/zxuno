`timescale 1ns / 1ns
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 23:37:21 2014-03-01 by Miguel Angel Rodriguez Jodar
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

module zxunoregs (
   input wire clk,
   input wire rst_n,
   input wire [15:0] a,
   input wire iorq_n,
   input wire rd_n,
   input wire wr_n,
   input wire [7:0] din,
   output reg [7:0] dout,
   output reg oe,
   output wire [7:0] addr,
   output wire read_from_reg,
   output wire write_to_reg,
   output wire regaddr_changed
   );
   
`include "config.vh"

// Manages register addr ($00 - $FF)   
   reg [7:0] raddr = 8'h00;
   assign addr = raddr;
   reg rregaddr_changed = 1'b0;
   assign regaddr_changed = rregaddr_changed;
   
   always @(posedge clk) begin
      if (!rst_n) begin
         raddr <= 8'h00;
         rregaddr_changed <= 1'b1;
      end
      else begin
        if (!iorq_n && a==IOADDR && !wr_n) begin
           raddr <= din;
           rregaddr_changed <= 1'b1;
        end
        else
           rregaddr_changed <= 1'b0;
      end
   end
    
   always @* begin
      dout = raddr;
      if (iorq_n == 1'b0 && a==IOADDR && rd_n == 1'b0)
         oe = 1'b1;
      else
         oe = 1'b0;
   end
   
   assign read_from_reg = (a==IODATA && iorq_n == 1'b0 && rd_n == 1'b0);
   assign write_to_reg = (a==IODATA && iorq_n == 1'b0 && wr_n == 1'b0);   
endmodule
