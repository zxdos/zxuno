`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:55:59 06/28/2016 
// Design Name: 
// Module Name:    genframe 
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
module genframe (
   input wire clk,  // 10 MHz
   input wire mode, // 0: interlaced. 1: progressive
   output reg [2:0] r,
   output reg [2:0] g,
   output reg [2:0] b,
   output reg csync
   );
   
   reg [9:0] hc = 10'd0;
   reg [9:0] vc = 10'd0;
   reg intprog = 1'b0; // internal copy of mode

   // Counters (horizontal and vertical). 
   // Horizontal counts tenths of microseconds. Vertical counts lines.
   always @(posedge clk) begin
      if (hc != 10'd639) begin
         hc <= hc + 10'd1;
      end
      else begin
         hc <= 10'd0;
         if (intprog == 1'b0) begin
            if (vc != 624) begin
               vc <= vc + 10'd1;
            end
            else begin
               vc <= 10'd0;
               intprog <= mode;
            end
         end
         else begin
            if (vc != 311) begin
               vc <= vc + 10'd1;
            end
            else begin
               vc <= 10'd0;
               intprog <= mode;
            end
         end
      end
   end
   
   // Sync generation (info taken from http://martin.hinner.info/vga/pal.html )
   reg videoen;
   always @* begin
      csync = 1'b1;
      videoen = 1'b0;
      
      if (vc == 10'd0 || 
          vc == 10'd1 || 
          vc == 10'd313 || 
          vc == 10'd314) begin
         if ((hc >= 10'd0 && hc < 10'd300) || (hc >= 10'd320 && hc < 10'd620)) begin
            csync = 1'b0;
         end
      end
      else if (vc == 10'd2) begin
         if ((hc >= 10'd0 && hc < 10'd300) || (hc >= 10'd320 && hc < 10'd340)) begin
            csync = 1'b0;
         end
      end
      else if (vc == 10'd312) begin
         if ((hc >= 10'd0 && hc < 10'd20) || (hc >= 10'd320 && hc < 10'd620)) begin
            csync = 1'b0;
         end
      end
      else if (vc == 10'd3 || 
               vc == 10'd4 || 
               vc == 10'd310 || 
               vc == 10'd311 || 
               vc == 10'd315 || 
               vc == 10'd316 ||
               vc == 10'd622 ||
               vc == 10'd623 ||
               vc == 10'd624 ||
               (vc == 10'd309 && intprog == 1'b1)) begin
         if ((hc >= 10'd0 && hc < 10'd20) || (hc >= 10'd320 && hc < 10'd340)) begin
            csync = 1'b0;
         end
      end
      else begin // we are in one visible scanline
         if (hc >= 10'd0 && hc < 10'd40) begin
            csync = 1'b0;
         end
         else if (hc >= 10'd120) begin
            videoen = 1'b1;
         end
      end
   end

   // Color bars generation
   always @* begin
      r = 3'b000;
      g = 3'b000;
      b = 3'b000;
      if (videoen == 1'b1) begin
         if (hc >= 120+65*0 && hc < 120+65*1) begin
            r = 3'b111;
            g = 3'b111;
            b = 3'b111;
         end
         else if (hc >= 120+65*1 && hc < 120+65*2) begin
            r = 3'b111;
            g = 3'b111;
            b = 3'b000;
         end
         else if (hc >= 120+65*2 && hc < 120+65*3) begin
            r = 3'b000;
            g = 3'b111;
            b = 3'b111;
         end
         else if (hc >= 120+65*3 && hc < 120+65*4) begin
            r = 3'b000;
            g = 3'b111;
            b = 3'b000;
         end
         else if (hc >= 120+65*4 && hc < 120+65*5) begin
            r = 3'b111;
            g = 3'b000;
            b = 3'b111;
         end
         else if (hc >= 120+65*5 && hc < 120+65*6) begin
            r = 3'b111;
            g = 3'b000;
            b = 3'b000;
         end
         else if (hc >= 120+65*6 && hc < 120+65*7) begin
            r = 3'b000;
            g = 3'b000;
            b = 3'b111;
         end
         else if (hc >= 120+65*7 && hc < 120+65*8) begin
            r = 3'b000;
            g = 3'b000;
            b = 3'b000;
         end         
      end
   end
endmodule
