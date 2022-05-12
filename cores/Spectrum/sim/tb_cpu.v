`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:33:22 07/15/2020
// Design Name:   tv80n_wrapper
// Module Name:   D:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/team/zxdosplus/exp27/sim/tb_cpu.v
// Project Name:  zxdos_lx25
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: tv80n_wrapper
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_cpu;

	// Inputs
	reg reset_n;
	reg clk;
	reg clk_enable;
	reg wait_n;
	reg int_n;
	reg nmi_n;
	reg busrq_n;
	reg [7:0] di;

	// Outputs
	wire m1_n;
	wire mreq_n;
	wire iorq_n;
	wire rd_n;
	wire wr_n;
	wire rfsh_n;
	wire halt_n;
	wire busak_n;
	wire [15:0] A;
	wire [7:0] dout;

	// Instantiate the Unit Under Test (UUT)
	tv80n_wrapper uut (
		.m1_n(m1_n), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.rfsh_n(rfsh_n), 
		.halt_n(halt_n), 
		.busak_n(busak_n), 
		.A(A), 
		.dout(dout), 
		.reset_n(reset_n), 
		.clk(clk), 
		.clk_enable(clk_enable), 
		.wait_n(wait_n), 
		.int_n(int_n), 
		.nmi_n(nmi_n), 
		.busrq_n(busrq_n), 
		.di(di)
	);

  reg [7:0] mem[0:15];
  initial begin
    mem[ 0] = 8'h21;
    mem[ 1] = 8'h0F;
    mem[ 2] = 8'h00;
    mem[ 3] = 8'h36;
    mem[ 4] = 8'h00;
    mem[ 5] = 8'h34;
    mem[ 6] = 8'd211;
    mem[ 7] = 8'hFE;
    mem[ 8] = 8'h18;
    mem[ 9] = 8'd251;
    mem[10] = 8'h00;
    mem[11] = 8'h00;
    mem[12] = 8'h00;
    mem[13] = 8'h00;
    mem[14] = 8'h00;
    mem[15] = 8'h00;
  end  
  
  always @* begin
    if (mreq_n == 1'b0 && rd_n == 1'b0)
      di = #10 mem[A];
    if (mreq_n == 1'b0 && wr_n == 1'b0)
      mem[A] = #5 dout;
  end
  
	initial begin
		// Initialize Inputs
		reset_n = 0;
		clk = 0;
		clk_enable = 1;
		wait_n = 1;
		int_n = 1;
		nmi_n = 1;
		busrq_n = 1;
		
		repeat (3)
      @(posedge clk);
    reset_n = 1;    
    
		// Add stimulus here
    repeat (256)
      @(posedge clk);
    $finish;
	end
      
  always begin
    clk = #(1000/56) ~clk;
  end          
endmodule

