`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:37:59 02/11/2016 
// Design Name: 
// Module Name:    fifo_wrapper 
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
module reg_fifo(rst, 
                rd_clk, rd_en, dout, empty,                 
                wr_clk, wr_en, din, full, prog_full);
   
   // Eli Billauer, 12.4.06
   // This module is released to the public domain; Any use is allowed.

   parameter width = 8;
   
   input                 rst;
   input                 rd_clk;
   input                 rd_en;
   input                 wr_clk;
   input                 wr_en;
   input [(width-1):0]   din;
   output                empty;
   output                full;
   output                prog_full;
   output [(width-1):0]  dout;

   reg                   fifo_valid, middle_valid;
   reg [(width-1):0]     dout, middle_dout;

   wire [(width-1):0]    fifo_dout;
   wire                  fifo_empty, fifo_rd_en;
   wire                  will_update_middle, will_update_dout;

   // orig_fifo is just a normal (non-FWFT) synchronous or asynchronous FIFO
   fifo orig_fifo
      (
       .rst(rst),       
       .rd_clk(rd_clk),
       .rd_en(fifo_rd_en),
       .dout(fifo_dout),
       .empty(fifo_empty),
       .wr_clk(wr_clk),
       .wr_en(wr_en),
       .din(din),
       .full(full),
       .prog_full(prog_full)
       );

   assign will_update_middle = fifo_valid && (middle_valid == will_update_dout);
   assign will_update_dout = (middle_valid || fifo_valid) && rd_en;
   assign fifo_rd_en = (!fifo_empty) && !(middle_valid && fifo_valid);
   assign empty = !(fifo_valid || middle_valid);

   always @(posedge rd_clk)
      if (rst)
         begin
            fifo_valid <= 0;
            middle_valid <= 0;
            dout <= 0;
            middle_dout <= 0;
         end
      else
         begin
            if (will_update_middle)
               middle_dout <= fifo_dout;
            
            if (will_update_dout)
               dout <= middle_valid ? middle_dout : fifo_dout;
            
            if (fifo_rd_en)
               fifo_valid <= 1;
            else if (will_update_middle || will_update_dout)
               fifo_valid <= 0;
            
            if (will_update_middle)
               middle_valid <= 1;
            else if (will_update_dout)
               middle_valid <= 0;
         end 
endmodule
