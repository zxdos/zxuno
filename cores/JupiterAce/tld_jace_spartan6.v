`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:18:12 11/07/2015 
// Design Name: 
// Module Name:    tld_jace_spartan6 
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
module tld_jace_spartan6 (
    input wire clk50mhz,
    input wire clkps2,
    input wire dataps2,
    input wire ear,
    output wire audio_out_left,
    output wire audio_out_right,
    output wire [2:0] r,
    output wire [2:0] g,
    output wire [2:0] b,
    output wire csync,
    output wire stdn,
    output wire stdnb
    );
    
    wire clkram; // 50MHz (maybe less if needed) to clock internal RAM/ROM
    wire clk65;  // 6.5MHz main frequency Jupiter ACE
    
    wire kbd_reset;
    wire [7:0] kbd_rows;
    wire [4:0] kbd_columns;
    wire video; // 1-bit video signal (black/white)
    
    // Trivial conversion from B/W video to RGB
    assign r = {video,video,1'b0};
    assign g = {video,video,1'b0};
    assign b = {video,video,1'b0};
    
    // Trivial conversion for audio
    wire mic,spk;
    assign audio_out_left = spk;
    assign audio_out_right = mic;
    
    // Select PAL
    assign stdn = 1'b0;  // PAL selection for AD724
    assign stdnb = 1'b1;  // 4.43MHz crystal selected
    
    // Power-on RESET (8 clocks)
    reg [7:0] poweron_reset = 8'h00;
    always @(posedge clk65)
        poweron_reset <= {poweron_reset[6:0],1'b1};
    
	dcmclock reloj_maestro(
	  .CLKIN_IN(clk50mhz), 
      .CLKDV_OUT(clk65), 
      .CLKIN_IBUFG_OUT(clkram), 
      .CLK0_OUT(), 
      .LOCKED_OUT()
	  );
    
    jupiter_ace the_core (
        .clkram(clkram),
        .clk65(clk65),
        .reset(kbd_reset & poweron_reset[7]),
        .ear(!ear),
        .filas(kbd_rows),
        .columnas(kbd_columns),
        .video(video),
        .sync(csync),
        .mic(mic),
        .spk(spk)
	);

    keyboard_for_ace the_keyboard (
        .clk(clk65),
        .clkps2(clkps2),
        .dataps2(dataps2),
        .rows(kbd_rows),
        .columns(kbd_columns),
        .kbd_reset(kbd_reset),
        .kbd_nmi()
    );


endmodule
