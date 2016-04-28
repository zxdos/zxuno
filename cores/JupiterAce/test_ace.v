`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   04:39:37 03/24/2011
// Design Name:   jace_en_fpga
// Module Name:   C:/proyectos_xilinx/fpga_ace/test_ace.v
// Project Name:  fpga_ace
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: jace_en_fpga
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_ace;

	// Inputs
	reg clk50mhz;
	reg reset;
	reg ear;

	// Outputs
	wire spk;
	wire mic;
	wire video;
	wire sync;

	// Instantiate the Unit Under Test (UUT)
	jace_en_fpga uut (
		.clk50mhz(clk50mhz), 
		.reset(reset), 
		.ear(ear), 
		.spk(spk), 
		.mic(mic), 
		.video(video), 
		.sync(sync)
	);

	initial begin
		// Initialize Inputs
		clk50mhz = 0;
		reset = 1;
		ear = 0;

		// Wait 100 ns for global reset to finish
		#1000;
      reset = 0;  
		// Add stimulus here
	end

   always
		#77 clk50mhz = !clk50mhz;
      
endmodule

