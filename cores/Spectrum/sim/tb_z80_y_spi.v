`timescale 1ns / 1ns
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:51:04 08/06/2020
// Design Name:   tv80n_wrapper
// Module Name:   D:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/team/cores/exp27/zxdos_lx16/tb_z80_y_spi.v
// Project Name:  zxdos_lx16
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

module tb_z80_y_spi;

	// Inputs
	reg reset_n;
	reg sysclk;
	reg [7:0] cpudin;

	// Outputs
	wire m1_n;
	wire mreq_n;
	wire iorq_n;
	wire rd_n;
	wire wr_n;
	wire rfsh_n;
	wire halt_n;
	wire busak_n;
	wire [15:0] cpuaddr;
	wire [7:0] cpudout;

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
		.reset_n(reset_n), 
		.clk(sysclk), 
		.clk_enable(wait_spi_n), 
		.wait_n(1'b1), 
		.int_n(1'b1), 
		.nmi_n(1'b1), 
		.busrq_n(1'b1), 
		.di(cpudin)
	);

  wire [7:0] spi_dout;
  reg [7:0] memory_dout;
  wire oe_spi, oe_romyram;

  wire [7:0] zxuno_addr_to_cpu;  // al bus de datos de entrada del Z80
  wire [7:0] zxuno_addr;   // direccion de registro actual
  wire regaddr_changed;    // indica que se ha escrito un nuevo valor en el registro de direcciones
  wire oe_zxunoaddr;     // el dato en el bus de entrada del Z80 es válido
  wire zxuno_regrd;     // Acceso de lectura en el puerto de datos de ZX-Uno
  wire zxuno_regwr;     // Acceso de escritura en el puerto de datos del ZX-Uno

  wire flash_cs_n, flash_clk, flash_di;
  wire flash_do;
  wire sd_cs_n, sd_clk, sd_mosi;
  reg sd_miso;
  wire wait_spi_n;

  always @* begin
    case (1'b1)
      oe_zxunoaddr   : cpudin = zxuno_addr_to_cpu;
      oe_spi         : cpudin = spi_dout;
      oe_romyram     : cpudin = memory_dout;
      default        : cpudin = 8'hFF;
    endcase
  end        

  zxunoregs addr_reg_zxuno (
    .clk(sysclk),
    .rst_n(reset_n),
    .a(cpuaddr),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .din(cpudout),
    .dout(zxuno_addr_to_cpu),
    .oe(oe_zxunoaddr),
    .addr(zxuno_addr),
    .read_from_reg(zxuno_regrd),
    .write_to_reg(zxuno_regwr),
    .regaddr_changed(regaddr_changed)
  );

  flash_and_sd cacharros_con_spi (
    .clk(sysclk),
    .a(cpuaddr),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .addr(zxuno_addr),
    .ior(zxuno_regrd),
    .iow(zxuno_regwr),
    .din(cpudout),
    .dout(spi_dout),
    .oe(oe_spi),
    .wait_n(wait_spi_n),
  
    .in_boot_mode(1'b1),
    .flash_cs_n(flash_cs_n),
    .flash_clk(flash_clk),
    .flash_di(flash_di),
    .flash_do(flash_do),
    .disable_spisd(1'b0),
    .sd_cs_n(sd_cs_n),
    .sd_clk(sd_clk),
    .sd_mosi(sd_mosi),
    .sd_miso(sd_miso)
  );

	initial begin
		// Initialize Inputs
		reset_n = 0;
		sysclk = 0;

    repeat (4)
      @(posedge sysclk);
      
    reset_n = 1;
    
    @(negedge halt_n);
    $finish;

	end
  
  //////////////////////////////////////////
  reg [7:0] spimem[0:3];
  reg [1:0] indxspi = 2'b00;
  reg [7:0] regspi;
  assign flash_do = regspi[7];
  reg data_from_mosi;
  initial begin
    spimem[0] = 8'b10101010;
    spimem[1] = 8'b11100111;
    spimem[2] = 8'b00110011;
    spimem[3] = 8'b00001111;
  end
  always begin
    regspi = spimem[indxspi];
    if (flash_cs_n == 1'b0) begin
      repeat(8) begin
        @(posedge flash_clk);
        data_from_mosi = flash_di;
        @(negedge flash_clk);
        regspi = {regspi[6:0], data_from_mosi};
      end
      indxspi = indxspi + 2'b01;
    end
    else
      @(posedge sysclk);
  end
  ///////////////////////////////////////////
  
  ///////////////////////////////////////////
  assign oe_romyram = (mreq_n == 1'b0 && rd_n == 1'b0);
  reg [7:0] rom[0:255];
  initial $readmemh ("testspi.hex", rom);
  reg [7:0] ram[0:255];
  always @* begin
    if (cpuaddr >= 256 && mreq_n == 1'b0 && wr_n == 1'b0)
      ram[cpuaddr[7:0]] = cpudout;
    memory_dout = (cpuaddr < 256)? rom[cpuaddr[7:0]] : ram[cpuaddr[7:0]];
  end
  ///////////////////////////////////////////

  always begin
    sysclk = #5 ~sysclk;
  end    
endmodule

