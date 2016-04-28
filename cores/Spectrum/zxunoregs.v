`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:37:21 03/01/2014 
// Design Name: 
// Module Name:    zxunoregs 
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
module zxunoregs (
   input wire clk,
   input wire rst_n,
   input wire [15:0] a,
   input wire iorq_n,
   input wire rd_n,
   input wire wr_n,
   input wire [7:0] din,
   output reg [7:0] dout,
   output reg oe_n,
   output wire [7:0] addr,
   output wire read_from_reg,
   output wire write_to_reg,
   output wire regaddr_changed
   );
   
   parameter
      IOADDR = 16'hFC3B,
      IODATA = 16'hFD3B;

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
      else if (!iorq_n && a==IOADDR && !wr_n) begin
         raddr <= din;
         rregaddr_changed <= 1'b1;
      end
      else
         rregaddr_changed <= 1'b0;
   end
    
   always @* begin
      if (!iorq_n && a==IOADDR && !rd_n) begin
         dout = raddr;
         oe_n = 1'b0;
      end
      else begin
         dout = 8'hZZ;
         oe_n = 1'b1;
      end
   end
   
   assign read_from_reg = (a==IODATA && !iorq_n && !rd_n);
   assign write_to_reg = (a==IODATA && !iorq_n && !wr_n);
   
/* Some mappings:   

Addr  |   Dir  |  Description
------+--------+----------------------------------------------
$00   |   R/W  | Master configuration: LOCK 0 0 TIMMING ISSUE2 DISNMI ENDIV ENBOOT  . ENDIV=1 enables DIVMMC . ENBOOT=1 boot ROM in use
$01   |   R/W  | Master memory mapper: 0 0 0 B4 B2 B2 B1 B0    . B4-B0: 16K bank to map onto $C000-$FFFF. 
      |        |                                                        System RAM (128K) uses banks 0-7
      |        |                                                        System ROM (64K) is located from bank 8 to bank 11.
      |        |                                                        DIVMMC ROM (ESXDOS) is located at bank 12 (16KB, only 8KB are used).
      |        |                                                        DIVMMC RAM is located at banks 13-14 (32KB)
$02   |   R/W  | Flash SPI port
$03   |   R/W  | Flash SPI CS pin
$04   |   R/W  | R: returns the last scancode issued by the keyboard. W: sends command to the keyboard (not yet impl.)

*/
endmodule
