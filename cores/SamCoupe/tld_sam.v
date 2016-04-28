`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:39:25 07/25/2015 
// Design Name: 
// Module Name:    tld_sam 
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
module tld_sam (
    input wire clk50mhz,
    // Audio I/O
    input wire ear,
    output wire audio_out_left,
    output wire audio_out_right,
    // Video output
    output wire [2:0] r,
    output wire [2:0] g,
    output wire [2:0] b,
    output wire csync,
    output wire stdn,
    output wire stdnb,
    // SRAM interface
    output wire [18:0] sram_addr,
    inout wire [7:0] sram_data,
    output wire sram_we_n,
    // PS/2 keyoard interface
    inout wire clkps2,
    inout wire dataps2
    );

    // Interface with RAM
    wire [18:0] ramaddr;
    wire [7:0] data_from_ram;
    wire [7:0] data_to_ram;
    wire ram_we_n;
    
    // Audio and video
    wire [1:0] sam_r, sam_g, sam_b;
    wire sam_bright;
    
    assign r = {sam_r, sam_bright};
    assign g = {sam_g, sam_bright};
    assign b = {sam_b, sam_bright};

    assign stdn = 1'b0;  // fijar norma PAL
	assign stdnb = 1'b1; // y conectamos reloj PAL
    
    wire clk24, clk12, clk6;

    relojes los_relojes (
        .CLK_IN1            (clk50mhz),      // IN
        // Clock out ports
        .CLK_OUT1           (clk24),      // OUT
        .CLK_OUT2           (clk12),       // OUT
        .CLK_OUT3           (clk6)        // OUT
    );

    samcoupe maquina (
        .clk24(clk24),
        .clk12(clk12),
        .clk6(clk6),
        .master_reset_n(1'b1),  // esta señal es sólo para simulación
        // Video output
        .r(sam_r),
        .g(sam_g),
        .b(sam_b),
        .bright(sam_bright),
        .csync(csync),
        // Audio output
        .ear(~ear),
        .audio_out_left(audio_out_left),
        .audio_out_right(audio_out_right),
        // PS/2 keyboard
        .clkps2(clkps2),
        .dataps2(dataps2),
        // SRAM external interface
        .sram_addr(sram_addr),
        .sram_data(sram_data),
        .sram_we_n(sram_we_n)
    );        
endmodule
