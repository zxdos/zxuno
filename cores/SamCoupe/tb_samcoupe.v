`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:16:07 08/01/2015
// Design Name:   samcoupe
// Module Name:   C:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/sam_coupe_spartan6/test1/tb_samcoupe.v
// Project Name:  samcoupe
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: samcoupe
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_samcoupe;

	// Inputs
	reg clk24;
	reg clk12;
	reg clk6;
	reg ear;
	reg clkps2;
	reg dataps2;
    reg rst_n;

	// Outputs
	wire [1:0] r;
	wire [1:0] g;
	wire [1:0] b;
	wire bright;
	wire csync;
	wire audio_out_left;
	wire audio_out_right;
	wire [18:0] sram_addr;
	wire sram_we_n;

	// Bidirs
	wire [7:0] sram_data;

	// Instantiate the Unit Under Test (UUT)
	samcoupe uut (
		.clk24(clk24), 
		.clk12(clk12), 
		.clk6(clk6), 
        .master_reset_n(rst_n),
		.r(r), 
		.g(g), 
		.b(b), 
		.bright(bright), 
		.csync(csync), 
		.ear(ear), 
		.audio_out_left(audio_out_left), 
		.audio_out_right(audio_out_right), 
		.clkps2(clkps2), 
		.dataps2(dataps2), 
		.sram_addr(sram_addr), 
		.sram_data(sram_data), 
		.sram_we_n(sram_we_n)
	);
    
    sram_sim memoria (
        .a(sram_addr[15:0]),
        .d(sram_data),
        .we_n(sram_we_n)
        );

	initial begin
		// Initialize Inputs
		clk24 = 1;
		clk12 = 1;
		clk6 = 1;
		ear = 0;
		clkps2 = 1;
		dataps2 = 1;
        rst_n = 0;

		// Add stimulus here
        #100;
        rst_n = 1;

	end
    
    always begin
        clk24 = #(1000/48.0) ~clk24;
    end
    always begin
        clk12 = #(1000/24.0) ~clk12;
    end
    always begin
        clk6 = #(1000/12.0) ~clk6;
    end      
endmodule

module sram_sim (
    input wire [15:0] a,
    inout wire [7:0] d,
    input wire we_n
    );
    
    reg [7:0] m[0:65535];
    reg [7:0] dout;
    
    integer i;
    initial begin
        for (i=0;i<65536;i=i+1)
            m[i] = {i[15:14],i[5:0]};
    end
    
    assign d = (we_n == 1'b0)? 8'hZZ : dout;    
    always @* begin
        if (we_n == 1'b0) begin        
            #35;
            m[a] = d;
        end
    end
    
    always @* begin
        if (we_n == 1'b1) begin
            #45;
            dout = m[a];
        end
    end
endmodule
