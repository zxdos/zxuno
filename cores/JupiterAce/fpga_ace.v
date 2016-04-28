`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:06:40 03/19/2011 
// Design Name: 
// Module Name:    jace_en_fpga 
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
    input wire clkram,
	input wire clk65,
    input wire clkcpu,
	input wire reset,
	input wire ear,
	output wire [7:0] filas,
	input wire [4:0] columnas,
	output wire video,
	output wire sync,
    output wire mic,
    output wire spk
	);
	
	// Los buses del Z80
	wire [7:0] DinZ80;
	wire [7:0] DoutZ80;
	wire [15:0] AZ80;
	
	wire iorq_n, mreq_n, int_n, rd_n, wr_n, wait_n;
    wire rom_enable, sram_enable, cram_enable, uram_enable, xram_enable, eram_enable, data_from_jace_oe;
    wire [7:0] dout_rom, dout_sram, dout_cram, dout_uram, dout_xram, dout_eram, data_from_jace;
    wire [7:0] sram_data, cram_data;
    wire [9:0] sram_addr, cram_addr;

	// Copia del bus de direcciones para las filas del teclado
    assign filas = AZ80[15:8];

    // Multiplexor para asignar un valor al bus de datos de entrada del Z80
    assign DinZ80 = (rom_enable == 1'b1)?        dout_rom :
                    (sram_enable == 1'b1)?       dout_sram :
                    (cram_enable == 1'b1)?       dout_cram :
                    (uram_enable == 1'b1)?       dout_uram :
                    (xram_enable == 1'b1)?       dout_xram :
                    (eram_enable == 1'b1)?       dout_eram :
                    (data_from_jace_oe == 1'b1)? data_from_jace :
                                                 sram_data | cram_data;  // By default, this is what the data bus sees

	// Memoria del equipo
	ram1k_dualport sram (
       .clk(clkram),
       .ce(sram_enable),
       .a1(AZ80[9:0]),
	   .a2(sram_addr),
	   .din(DoutZ80),
	   .dout1(dout_sram),
       .dout2(sram_data),
	   .we(~wr_n)
		);
		
	ram1k_dualport cram (
       .clk(clkram),
       .ce(cram_enable),
       .a1(AZ80[9:0]),
	   .a2(cram_addr),
	   .din(DoutZ80),
	   .dout1(dout_cram),
       .dout2(cram_data),
	   .we(~wr_n)
		);
		
	ram1k uram(
		.clk(clkram),
        .ce(uram_enable),
        .a(AZ80[9:0]),
        .din(DoutZ80),
        .dout(dout_uram),
        .we(~wr_n)
		);
		
	ram16k xram(
		.clk(clkram),
        .ce(xram_enable),
        .a(AZ80[13:0]),
        .din(DoutZ80),
        .dout(dout_xram),
        .we(~wr_n)
		);

	ram32k eram(
		.clk(clkram),
        .ce(eram_enable),
        .a(AZ80[14:0]),
        .din(DoutZ80),
        .dout(dout_eram),
        .we(~wr_n)
		);

	/* La ROM */
	rom the_rom(
	   .clk(clkram),
	   .a(AZ80[12:0]),
	   .dout(dout_rom)
		);
	
	/* La CPU */
	tv80n cpu(
		// Outputs
		.m1_n(), .mreq_n(mreq_n), .iorq_n(iorq_n), .rd_n(rd_n), .wr_n(wr_n), .rfsh_n(), .halt_n(), .busak_n(), .A(AZ80), .do(DoutZ80),
		// Inputs
		.di(DinZ80), .reset_n(reset), .clk(clkcpu), .wait_n(wait_n), .int_n(int_n), .nmi_n(1'b1), .busrq_n(1'b1)
        );
        
    jace_logic todo_lo_demas (
        .clk(clk65),
        // CPU interface
        .cpu_addr(AZ80),
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .data_from_cpu(DoutZ80),
        .data_to_cpu(data_from_jace),
        .data_to_cpu_oe(data_from_jace_oe),
        .wait_n(wait_n),
        .int_n(int_n),
        // CPU-RAM interface
        .rom_enable(rom_enable),
        .sram_enable(sram_enable),
        .cram_enable(cram_enable),
        .uram_enable(uram_enable),
        .xram_enable(xram_enable),
        .eram_enable(eram_enable),
        // Screen RAM and Char RAM interface
        .screen_addr(sram_addr),
        .screen_data(sram_data),
        .char_addr(cram_addr),
        .char_data(cram_data),
        // Devices
        .kbdcols(columnas),
        .ear(ear),
        .spk(spk),
        .mic(mic),
        .video(video),
        .csync(sync)
    );
endmodule

