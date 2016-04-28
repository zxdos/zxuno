`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:02:16 02/16/2014
// Design Name:   ula
// Module Name:   C:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/ula_reloaded/tb_ula.v
// Project Name:  ula_reloaded
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ula
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_ula;

	// Inputs
	reg clk14;
	reg wssclk;
	reg rst_n;
	reg [15:0] a;
	reg mreq_n;
	reg iorq_n;
	reg rd_n;
	reg wr_n;
	reg [7:0] din;
	reg ear;
	reg [4:0] kbd;

	// Outputs
	wire cpuclk;
	wire int_n;
	wire [7:0] dout;
	wire [13:0] va;
	wire [7:0] vramdata;
	wire mic;
	wire spk;
	wire clkay;
	wire clkdac;
	wire clkkbd;
	wire [2:0] r;
	wire [2:0] g;
	wire [2:0] b;
	wire csync;
	wire y_n;

	// Instantiate the Unit Under Test (UUT)
	ula_radas uut (
		.clk14(clk14), 
		.wssclk(wssclk), 
		.rst_n(rst_n), 
		.a(a), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.cpuclk(cpuclk), 
		.int_n(int_n), 
		.din(din), 
		.dout(dout), 
		.va(va), 
		.vramdata(vramdata), 
		.ear(ear), 
		.kbd(kbd), 
		.mic(mic), 
		.spk(spk), 
        .issue2_keyboard(1'b0),
        .timming(1'b0),
        .disable_contention(1'b0),
		.clkay(clkay), 
		.clkdac(clkdac), 
		.clkkbd(clkkbd), 
		.r(r), 
		.g(g), 
		.b(b), 
		.csync(csync), 
		.y_n(y_n)
	);

   ram videoram (
      .a(va),
      .dout(vramdata)
      );

	initial begin
		// Initialize Inputs
		clk14 = 0;
		wssclk = 0;
		rst_n = 0;
		a = 16'h4000;
		mreq_n = 1;
		iorq_n = 1;
		rd_n = 1;
		wr_n = 1;
		din = 0;
		ear = 0;
		kbd = 5'b11111;

		// Wait 100 ns for global reset to finish
		#200; rst_n = 1'b1;
        
		// Add stimulus here

	end
   
   always begin
      clk14 = #35.714285714285714285714285714286  ~clk14;
   end
   
   always begin
      wssclk = #100 ~wssclk;
   end
      
endmodule

module ram (
   input wire [13:0] a,
   output wire [7:0] dout
   );
   
   reg [7:0] mem[0:16383];
   initial begin
      $readmemh ("pantalla_ulatest3.hex", mem);
   end
   
   assign dout = mem[a];
endmodule
