`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    03:22:12 07/25/2015 
// Design Name:    SAM Coupé clone
// Module Name:    rom 
// Project Name:   SAM Coupé clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
(* rom_extract = "yes" *)
(* rom_style = "block" *)
module rom (
    input wire clk,
    input wire [14:0] a,
    output reg [7:0] dout
    );
    
    reg [7:0] mem[0:32767];
    //reg [7:0] mem[0:16383];
    initial begin        
`ifdef SYNTH
        $readmemh ("rom30.hex", mem);    
        //$readmemh ("48.hex", mem);
        //$readmemh ("128k_paul_farrow.hex", mem);
        //$readmemh ("test48kmcleod.hex", mem);
`else        
        mem[ 0] = 8'd33;
        mem[ 1] = 8'd14;
        mem[ 2] = 8'd0;
        mem[ 3] = 8'd17;
        mem[ 4] = 8'd0;
        mem[ 5] = 8'd128;
        mem[ 6] = 8'd1;
        mem[ 7] = 8'd6;
        mem[ 8] = 8'd0;
        mem[ 9] = 8'd237;
        mem[10] = 8'd176;
        mem[11] = 8'd195;
        mem[12] = 8'd0;
        mem[13] = 8'd128;
        mem[14] = 8'd175;
        mem[15] = 8'd211;
        mem[16] = 8'd254;
        mem[17] = 8'd195;
        mem[18] = 8'd0;
        mem[19] = 8'd128;
`endif
    end
    
    always @(posedge clk)
        dout <= mem[a];
endmodule
