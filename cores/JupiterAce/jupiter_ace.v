`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:18:12 11/07/2015 
// Design Name: 
// Module Name:    jupiter_ace 
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
module jupiter_ace (
    input wire clk50mhz,
    input wire clkps2,
    input wire dataps2,
    input wire ear,
    output wire audio_out_left,
    output wire audio_out_right,
    inout wire [2:0] r,
    inout wire [2:0] g,
    inout wire [2:0] b,
    inout wire hsync,
    inout wire vsync,
    output wire [2:0] dr,
    output wire [2:0] dg,
    output wire [2:0] db,
    output wire dhsync,
    output wire dvsync,
    output wire stdn,
    output wire stdnb,
    ///// SRAM pins (just to get the current video output setting) ////////////
    output wire [20:0] sram_addr,
    input wire [7:0] sram_data,
    output wire sram_we_n
    );
    
    wire clkram; // 26.666666MHz to clock internal RAM/ROM
    wire clk65;  // 6.5MHz main frequency Jupiter ACE
    wire clkcpu; // CPU CLK
	 wire clkvga; // Twice the original pixel clock
    
    wire kbd_reset;
    wire kbd_mreset;
    wire [7:0] kbd_rows;
    wire [4:0] kbd_columns;
    wire video; // 1-bit video signal (black/white)
    
    // Trivial conversion from B/W video to RGB for the scandoubler
	 wire pal_hsync, pal_vsync; // inputs to the scandoubler
    wire [2:0] ri = {video,video,1'b0};
    wire [2:0] gi = {video,video,1'b0};
    wire [2:0] bi = {video,video,1'b0};
    
    assign dr = r;
    assign dg = g;
    assign db = b;
    assign dhsync = hsync;
    assign dvsync = vsync;

    // Trivial conversion for audio
    wire mic,spk;
    assign audio_out_left = spk;
    assign audio_out_right = mic;
    
    // Select PAL
    assign stdn = 1'b0;  // PAL selection for AD724
    assign stdnb = 1'b1;  // 4.43MHz crystal selected

    // Initial video output settings
    reg [7:0] scandblr_reg; // same layout as in the Spectrum core, SCANDBLR_CTRL
    
    // Power-on RESET (8 clocks)
    reg [7:0] poweron_reset = 8'h00;
    assign sram_addr = 21'h008FD5;  // magic place where the scandoubler settings have been stored
    assign sram_we_n = 1'b1;
    always @(posedge clk65) begin
        if (poweron_reset == 1'b0)
           scandblr_reg <= sram_data;
        poweron_reset <= {poweron_reset[6:0],1'b1};
    end
    
    cuatro_relojes system_clocks_pll (
        .CLK_IN1(clk50mhz),
        .CLK_OUT1(clkram),  // for driving RAM and ROM = 26 MHz
        .CLK_OUT2(clkvga),  // VGA clock: 2 x video clock
        .CLK_OUT3(clk65),   // video clock = 6.5 MHz
        .CLK_OUT4(clkcpu)   // CPU clock = 3.25 MHz
    );
    
    fpga_ace the_core (
        .clkram(clkram),
        .clk65(clk65),
        .clkcpu(clkcpu),
        .reset(kbd_reset & poweron_reset[7]),
        .ear(ear),
        .filas(kbd_rows),
        .columnas(kbd_columns),
        .video(video),
        .hsync(pal_hsync),
		  .vsync(pal_vsync),
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
        .kbd_nmi(),
        .kbd_mreset(kbd_mreset)        
    );
	 
	vga_scandoubler #(.CLKVIDEO(6500)) salida_vga (
		.clkvideo(clk65),
		.clkvga(clkvga),
      .enable_scandoubling(scandblr_reg[0]),
      .disable_scaneffect(~scandblr_reg[1]),
		.ri(ri),
		.gi(gi),
		.bi(bi),
		.hsync_ext_n(pal_hsync),
		.vsync_ext_n(pal_vsync),
		.ro(r),
		.go(g),
		.bo(b),
		.hsync(hsync),
		.vsync(vsync)
   );	 
   
   multiboot return_to_main_core (
      .clk_icap(clkvga),
      .mrst_n(kbd_mreset)
   );

endmodule
