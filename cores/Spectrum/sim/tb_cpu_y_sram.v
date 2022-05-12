`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:45:50 08/21/2020
// Design Name:   new_memory
// Module Name:   Y:/cores/spectrum_v2_spartan6/exp27/sim/tb_cpu_y_sram.v
// Project Name:  zxdos_lx16
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: new_memory
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_cpu_y_sram;

	// Inputs
	reg clk;
	reg rst_n;
	wire [15:0] cpuaddr;
	reg [7:0] cpudin;
	wire mreq_n;
	wire iorq_n;
	wire rd_n;
	wire wr_n;
	wire m1_n;
  wire busak_n;
	wire rfsh_n;
  wire halt_n;

	// Outputs
	wire [7:0] cpudout, memdout;
	wire mem_oe;
	wire [20:0] sram_addr;
	wire sram_we_n;

	// Bidirs
	wire [7:0] sram_data;

	// Instantiate the Unit Under Test (UUT)
	tv80n_wrapper cpu (
		.m1_n(m1_n), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.rfsh_n(rfsh_n), 
		.halt_n(halt_n), 
		.busak_n(busak_n), 
		.A(cpuaddr), 
		.dout(cpudout), 
		.reset_n(rst_n), 
		.clk(clk), 
		.clk_enable(1'b1), 
		.wait_n(1'b1), 
		.int_n(1'b1), 
		.nmi_n(1'b1), 
		.busrq_n(1'b1), 
		.di(cpudin)
	);

	new_memory mem (
		.clk(clk), 
		.mrst_n(rst_n), 
		.rst_n(rst_n), 
		.a(cpuaddr), 
		.din(cpudout), 
		.dout(memdout), 
		.oe(mem_oe), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.m1_n(m1_n), 
		.rfsh_n(rfsh_n), 
		.busak_n(busak_n), 
		.enable_nmi_n(), 
		.page_configrom_active(1'b0), 
		.vramaddr(14'h0000), 
		.vramdout(), 
		.doc_ext_option(1'b0), 
		.issue2_keyboard_enabled(), 
		.timing_mode(), 
		.disable_contention(), 
		.access_to_screen(), 
		.ioreqbank(), 
		.inhibit_rom(1'b0), 
		.din_external(8'hFF), 
		.addr(8'h00), 
		.ior(1'b0), 
		.iow(1'b0), 
		.in_boot_mode(), 
		.disable_7ffd(1'b0), 
		.disable_1ffd(1'b0), 
		.disable_romsel7f(1'b0), 
		.disable_romsel1f(1'b0), 
		.enable_timexmmu(1'b0), 
		.pzx_addr(21'h000000), 
		.enable_pzx(), 
		.in48kmode(), 
		.data_from_pzx(8'h00), 
		.data_to_pzx(), 
		.write_data_pzx(1'b0), 
		.sram_addr(sram_addr), 
		.sram_data(sram_data), 
		.sram_we_n(sram_we_n)
	);

  always @* begin
    if (mem_oe == 1'b1)
      cpudin = memdout;
    else
      cpudin = 8'hFF;
  end

	initial begin
		// Initialize Inputs
		clk = 0;
    rst_n = 0;
    
    repeat (4) @(posedge clk);
    rst_n = 1;

    @(negedge halt_n);
	end
    
  always begin
    clk = #5 ~clk;
  end
      
endmodule

