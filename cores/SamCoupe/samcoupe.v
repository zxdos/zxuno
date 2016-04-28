`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    03:54:40 13/25/2015 
// Design Name:    SAM Coupé clone
// Module Name:    samcoupe
// Project Name:   SAM Coupé clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module samcoupe (
    input wire clk24,
    input wire clk12,
    input wire clk6,
    input wire clk8,
    input wire master_reset_n,
    // Video output
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b,
    output wire bright,
    output wire csync,
    // Audio output
    input wire ear,
    output wire audio_out_left,
    output wire audio_out_right,
    // PS/2 keyoard interface
    inout wire clkps2,
    inout wire dataps2,
    // SRAM interface
    output wire [18:0] sram_addr,
    inout wire [7:0] sram_data,
    output wire sram_we_n
    );
    
    // ROM memory
    wire [14:0] romaddr;
    wire [7:0] data_from_rom;
    
    // RAM memory
    wire [18:0] vramaddr, cpuramaddr;
    wire [7:0] data_from_ram;
    wire [7:0] data_to_asic;
    wire ram_we_n;
    wire asic_is_using_ram;
    
    // Keyboard
    wire [8:0] kbrows;
    wire [7:0] kbcolumns;
    wire kb_nmi_n;
    wire kb_rst_n;
    wire rdmsel;
    assign kbrows = {rdmsel, cpuaddr[15:8]};
    
    // CPU signals
    wire mreq_n, iorq_n, rd_n, wr_n, int_n, wait_n, rfsh_n;
    wire [15:0] cpuaddr;
    wire [7:0] data_from_cpu;
    wire [7:0] data_to_cpu;
    
    // ASIC signals
    wire [7:0] data_from_asic;
    wire asic_oe_n;
    wire rom_oe_n;
    
    // ROM signals
    assign romaddr = {cpuaddr[15], cpuaddr[13:0]};
    
    // RAM signals
    wire ram_oe_n;
    
    // Audio signals
    wire mic, beep;
    wire [7:0] saa_out_l, saa_out_r;
    
    // MUX from memory/devices to Z80 data bus
    assign data_to_cpu = (rom_oe_n == 1'b0)?  data_from_rom :
                         (ram_oe_n == 1'b0)?  data_from_ram :
                         (asic_oe_n == 1'b0)? data_from_asic :
                         8'hFF;

    tv80n el_z80 (
      .m1_n(),
      .mreq_n(mreq_n),
      .iorq_n(iorq_n),
      .rd_n(rd_n),
      .wr_n(wr_n),
      .rfsh_n(rfsh_n),
      .halt_n(),
      .busak_n(),
      .A(cpuaddr),
      .dout(data_from_cpu),

      .reset_n(kb_rst_n & master_reset_n),
      .clk(clk6),
      .wait_n(wait_n),
      .int_n(int_n),
      .nmi_n(kb_nmi_n),
      .busrq_n(1'b1),
      .di(data_to_cpu)
    );
    
    asic la_ula_del_sam (
        .clk(clk12),
        .rst_n(kb_rst_n & master_reset_n),
        // CPU interface
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .cpuaddr(cpuaddr),
        .data_from_cpu(data_from_cpu),
        .data_to_cpu(data_from_asic),
        .data_enable_n(asic_oe_n),
        .wait_n(wait_n),
        // RAM/ROM interface
        .vramaddr(vramaddr),
        .cpuramaddr(cpuramaddr),
        .data_from_ram(data_to_asic),
        .ramwr_n(ram_we_n),
        .romcs_n(rom_oe_n),
        .ramcs_n(ram_oe_n),
        .asic_is_using_ram(asic_is_using_ram),
        // audio I/O
        .ear(ear),
        .mic(mic),
        .beep(beep),
        // keyboard I/O
        .keyboard(kbcolumns),
        .rdmsel(rdmsel),
        // disk I/O
        .disc1_n(),
        .disc2_n(),
        // video output
        .r(r),
        .g(g),
        .b(b),
        .bright(bright),
        .csync(csync),
        .int_n(int_n)
    );
    
    rom rom_32k (
        .clk(clk12),
        .a(romaddr),
        .dout(data_from_rom)
    );
    
    ram_dual_port_turnos ram_512k (
        .clk(1'b0 /*clk24*/),
        .whichturn(asic_is_using_ram),
        .vramaddr(vramaddr),
        .cpuramaddr(cpuramaddr),
        .cpu_we_n(ram_we_n),
        .data_from_cpu(data_from_cpu),
        .data_to_asic(data_to_asic),
        .data_to_cpu(data_from_ram),
        // Actual interface with SRAM
        .sram_a(sram_addr),
        .sram_we_n(sram_we_n),
        .sram_d(sram_data)
    );
    
//    ram_dual_port ram_512k (
//        .clk(clk24),
//        .whichturn(asic_is_using_ram),
//        .vramaddr(vramaddr),
//        .cpuramaddr(cpuramaddr),
//        .mreq_n(ram_oe_n),
//        .rd_n(rd_n),
//        .wr_n(ram_we_n),
//        .rfsh_n(rfsh_n),
//        .data_from_cpu(data_from_cpu),
//        .data_to_asic(data_to_asic),
//        .data_to_cpu(data_from_ram),
//        // Actual interface with SRAM
//        .sram_a(sram_addr),
//        .sram_we_n(sram_we_n),
//        .sram_d(sram_data)
//    );

    ps2_keyb el_teclado (
        .clk(clk6),
        .clkps2(clkps2),
        .dataps2(dataps2),
        //---------------------------------
        .rows(kbrows),
        .cols(kbcolumns),
        .rst_out_n(kb_rst_n),
        .nmi_out_n(kb_nmi_n),
        .mrst_out_n(),
        .user_toggles(),
        //---------------------------------
        .zxuno_addr(8'h00),
        .zxuno_regrd(1'b0),
        .zxuno_regwr(1'b0),
        .regaddr_changed(1'b0),
        .din(data_from_cpu),
        .keymap_dout(),
        .oe_n_keymap(),
        .scancode_dout(),
        .oe_n_scancode(),
        .kbstatus_dout(),
        .oe_n_kbstatus()
    );
    
    saa1099 el_saa (
        .clk(clk8),  // 8 MHz
        .rst_n(kb_rst_n),
        .cs_n(~(cpuaddr[7:0] == 8'hFF && iorq_n == 1'b0)),
        .a0(cpuaddr[8]),  // 0=data, 1=address
        .wr_n(wr_n),
        .din(data_from_cpu),
        .out_l(saa_out_l),
        .out_r(saa_out_r)
    );
    
    mixer sam_audio_mixer (
        .clk(clk8),
        .rst_n(kb_rst_n),
        .ear(ear),
        .mic(mic),
        .spk(beep),
        .saa_left(saa_out_l),
        .saa_right(saa_out_r),
        .audio_left(audio_out_left),
        .audio_right(audio_out_right)
	);
    
endmodule
