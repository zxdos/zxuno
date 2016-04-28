`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:12:52 02/09/2014 
// Design Name: 
// Module Name:    rom 
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
module rom (
    input wire clk,
    input wire [13:0] a,
    output reg [7:0] dout
    );

   reg [7:0] mem[0:127];
   integer i;
   initial begin  // usa $readmemb/$readmemh dependiendo del formato del fichero que contenga la ROM
      for (i=0;i<128;i=i+1) begin
        mem[i] = 8'h00;
      end
      $readmemh ("bootloader_hex.txt", mem, 0);
   end
   
   always @(posedge clk) begin
     dout <= mem[a[6:0]];
   end
endmodule
