`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:16:16 02/06/2014 
// Design Name: 
// Module Name:    zxuno 
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
module zxuno(
    input wire clk,
    input wire wssclk,
    output wire [2:0] r,
    output wire [2:0] g,
    output wire [2:0] b,
    output wire csync
    );

   wire [8:0] h;
   wire [8:0] v;
   reg [2:0] rojo;
   reg [2:0] verde;
   reg [2:0] azul;

   always @* begin
      if (h>=0 && h<256 && v>=0 && v<192) begin
         if (v>=0 && v<64) begin
            rojo = h[7:5];
            verde = 3'b000;
            azul = 3'b000;
         end
         else if (v>=64 && v<128) begin
            rojo = 3'b000;
            verde = h[7:5];
            azul = 3'b000;
         end
         else begin
            rojo = 3'b000;
            verde = 3'b000;
            azul = h[7:5];
         end
      end
      else begin
         rojo = 3'b100;
         verde = 3'b100;
         azul = 3'b100;
      end
   end

   pal_sync_generator_progressive syncs (
    .clk(clk),
	 .wssclk(wssclk),
	 .ri(rojo),
	 .gi(verde),
	 .bi(azul),
	 .hcnt(h),
	 .vcnt(v),
    .ro(r),
    .go(g),
    .bo(b),
    .csync(csync)
    );

endmodule
