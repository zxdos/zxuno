`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:22:21 06/07/2015 
// Design Name: 
// Module Name:    coreid 
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
module coreid (
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire regaddr_changed,
    output wire [7:0] dout,
    output wire oe_n
    );

    reg [7:0] text[0:15];
    integer i;
    initial begin
      for (i=0;i<16;i=i+1)
        text[i] = 8'h00;              
      text[ 0] = "T";
      text[ 1] = "2";
      text[ 2] = "0";
      text[ 3] = "-";
      text[ 4] = "0";
      text[ 5] = "7";
      text[ 6] = "1";
      text[ 7] = "2";
      text[ 8] = "2";
      text[ 9] = "0";
      text[10] = "1";
      text[11] = "5";
    end      
    
    reg [3:0] textindx = 4'h0;
    reg reading = 1'b0;
    assign oe_n = !(zxuno_addr == 8'hFF && zxuno_regrd==1'b1);
    assign dout = (oe_n==1'b0)? text[textindx] : 8'hZZ;
    
    always @(posedge clk) begin
        if (rst_n == 1'b0 || (regaddr_changed==1'b1 && zxuno_addr==8'hFF)) begin
            textindx <= 4'h0;
            reading <= 1'b0;
        end
        else if (oe_n==1'b0) begin
            reading <= 1'b1;
        end
        else if (reading == 1'b1 && oe_n==1'b1) begin
            reading <= 1'b0;
            textindx <= textindx + 1;
        end
    end
endmodule
