`timescale 1ns / 1ps

`include "chip_6502_nodes.inc"

module Pool_tb;

    // Inputs
    reg CLK_50MHZ;
    reg BTN_SOUTH;
    reg [3:0] SW;

    // Instantiate the Unit Under Test (UUT)
    Pool uut (
        .CLK_50MHZ(CLK_50MHZ),
        .AD_CONV(),
        .AMP_CS(),
        .BTN_SOUTH(BTN_SOUTH),
        .DAC_CLR(),
        .DAC_CS(),
        .FPGA_INIT_B(),
        .LED(),
        .SF_CE0(),
        .SF_OE(),
        .SF_WE(),
        .SPI_MOSI(),
        .SPI_SCK(),
        .SPI_SS_B(),
        .SW(SW)
    );

    initial begin
        // Initialize Inputs
        CLK_50MHZ = 0;
        BTN_SOUTH = 0;
        SW = 4'd1;
    end

   always #10 CLK_50MHZ <= ~CLK_50MHZ;

    wire [7:0] db = {
        uut.chip_6502.ni[`NODE_db7],uut.chip_6502.ni[`NODE_db6],uut.chip_6502.ni[`NODE_db5],uut.chip_6502.ni[`NODE_db4],
        uut.chip_6502.ni[`NODE_db3],uut.chip_6502.ni[`NODE_db2],uut.chip_6502.ni[`NODE_db1],uut.chip_6502.ni[`NODE_db0]
    };

    wire [15:0] ab = {
        uut.chip_6502.ni[`NODE_ab15], uut.chip_6502.ni[`NODE_ab14], uut.chip_6502.ni[`NODE_ab13], uut.chip_6502.ni[`NODE_ab12],
        uut.chip_6502.ni[`NODE_ab11], uut.chip_6502.ni[`NODE_ab10], uut.chip_6502.ni[`NODE_ab9],  uut.chip_6502.ni[`NODE_ab8],
        uut.chip_6502.ni[`NODE_ab7],  uut.chip_6502.ni[`NODE_ab6],  uut.chip_6502.ni[`NODE_ab5],  uut.chip_6502.ni[`NODE_ab4],
        uut.chip_6502.ni[`NODE_ab3],  uut.chip_6502.ni[`NODE_ab2],  uut.chip_6502.ni[`NODE_ab1],  uut.chip_6502.ni[`NODE_ab0]
    };

    wire rw   = uut.chip_6502.ni[`NODE_rw];
    wire sync = uut.chip_6502.ni[`NODE_sync];
    wire phi1 = uut.chip_6502.ni[`NODE_cp1];
    wire phi2 = uut.chip_6502.ni[`NODE_cp2];

    wire [15:0] pc = {
        uut.chip_6502.ni[`NODE_pch7],
        uut.chip_6502.ni[`NODE_pch6],
        uut.chip_6502.ni[`NODE_pch5],
        uut.chip_6502.ni[`NODE_pch4],
        uut.chip_6502.ni[`NODE_pch3],
        uut.chip_6502.ni[`NODE_pch2],
        uut.chip_6502.ni[`NODE_pch1],
        uut.chip_6502.ni[`NODE_pch0],
        uut.chip_6502.ni[`NODE_pcl7],
        uut.chip_6502.ni[`NODE_pcl6],
        uut.chip_6502.ni[`NODE_pcl5],
        uut.chip_6502.ni[`NODE_pcl4],
        uut.chip_6502.ni[`NODE_pcl3],
        uut.chip_6502.ni[`NODE_pcl2],
        uut.chip_6502.ni[`NODE_pcl1],
        uut.chip_6502.ni[`NODE_pcl0]
    };

    wire idl[7:0] = {
        uut.chip_6502.ni[`NODE_idl7],
        uut.chip_6502.ni[`NODE_idl6],
        uut.chip_6502.ni[`NODE_idl5],
        uut.chip_6502.ni[`NODE_idl4],
        uut.chip_6502.ni[`NODE_idl3],
        uut.chip_6502.ni[`NODE_idl2],
        uut.chip_6502.ni[`NODE_idl1],
        uut.chip_6502.ni[`NODE_idl0]
    };

    wire sb[7:0] = {
        uut.chip_6502.ni[`NODE_sb7],
        uut.chip_6502.ni[`NODE_sb6],
        uut.chip_6502.ni[`NODE_sb5],
        uut.chip_6502.ni[`NODE_sb4],
        uut.chip_6502.ni[`NODE_sb3],
        uut.chip_6502.ni[`NODE_sb2],
        uut.chip_6502.ni[`NODE_sb1],
        uut.chip_6502.ni[`NODE_sb0]
    };

    wire idb[7:0] = {
        uut.chip_6502.ni[`NODE_idb7],
        uut.chip_6502.ni[`NODE_idb6],
        uut.chip_6502.ni[`NODE_idb5],
        uut.chip_6502.ni[`NODE_idb4],
        uut.chip_6502.ni[`NODE_idb3],
        uut.chip_6502.ni[`NODE_idb2],
        uut.chip_6502.ni[`NODE_idb1],
        uut.chip_6502.ni[`NODE_idb0]
    };

    wire adl[7:0] = {
        uut.chip_6502.ni[`NODE_adl7],
        uut.chip_6502.ni[`NODE_adl6],
        uut.chip_6502.ni[`NODE_adl5],
        uut.chip_6502.ni[`NODE_adl4],
        uut.chip_6502.ni[`NODE_adl3],
        uut.chip_6502.ni[`NODE_adl2],
        uut.chip_6502.ni[`NODE_adl1],
        uut.chip_6502.ni[`NODE_adl0]
    };

    wire adh[7:0] = {
        uut.chip_6502.ni[`NODE_adh7],
        uut.chip_6502.ni[`NODE_adh6],
        uut.chip_6502.ni[`NODE_adh5],
        uut.chip_6502.ni[`NODE_adh4],
        uut.chip_6502.ni[`NODE_adh3],
        uut.chip_6502.ni[`NODE_adh2],
        uut.chip_6502.ni[`NODE_adh1],
        uut.chip_6502.ni[`NODE_adh0]
    };
/*
    wire abl[7:0] = {
        uut.chip_6502.ni[`NODE_abl7],
        uut.chip_6502.ni[`NODE_abl6],
        uut.chip_6502.ni[`NODE_abl5],
        uut.chip_6502.ni[`NODE_abl4],
        uut.chip_6502.ni[`NODE_abl3],
        uut.chip_6502.ni[`NODE_abl2],
        uut.chip_6502.ni[`NODE_abl1],
        uut.chip_6502.ni[`NODE_abl0]
    };

    wire abh[7:0] = {
        uut.chip_6502.ni[`NODE_abh7],
        uut.chip_6502.ni[`NODE_abh6],
        uut.chip_6502.ni[`NODE_abh5],
        uut.chip_6502.ni[`NODE_abh4],
        uut.chip_6502.ni[`NODE_abh3],
        uut.chip_6502.ni[`NODE_abh2],
        uut.chip_6502.ni[`NODE_abh1],
        uut.chip_6502.ni[`NODE_abh0]
    };
*/
    wire s[7:0] = {
        uut.chip_6502.ni[`NODE_s7],
        uut.chip_6502.ni[`NODE_s6],
        uut.chip_6502.ni[`NODE_s5],
        uut.chip_6502.ni[`NODE_s4],
        uut.chip_6502.ni[`NODE_s3],
        uut.chip_6502.ni[`NODE_s2],
        uut.chip_6502.ni[`NODE_s1],
        uut.chip_6502.ni[`NODE_s0]
    };

    wire a[7:0] = {
        uut.chip_6502.ni[`NODE_a7],
        uut.chip_6502.ni[`NODE_a6],
        uut.chip_6502.ni[`NODE_a5],
        uut.chip_6502.ni[`NODE_a4],
        uut.chip_6502.ni[`NODE_a3],
        uut.chip_6502.ni[`NODE_a2],
        uut.chip_6502.ni[`NODE_a1],
        uut.chip_6502.ni[`NODE_a0]
    };

    wire x[7:0] = {
        uut.chip_6502.ni[`NODE_x7],
        uut.chip_6502.ni[`NODE_x6],
        uut.chip_6502.ni[`NODE_x5],
        uut.chip_6502.ni[`NODE_x4],
        uut.chip_6502.ni[`NODE_x3],
        uut.chip_6502.ni[`NODE_x2],
        uut.chip_6502.ni[`NODE_x1],
        uut.chip_6502.ni[`NODE_x0]
    };

    wire y[7:0] = {
        uut.chip_6502.ni[`NODE_y7],
        uut.chip_6502.ni[`NODE_y6],
        uut.chip_6502.ni[`NODE_y5],
        uut.chip_6502.ni[`NODE_y4],
        uut.chip_6502.ni[`NODE_y3],
        uut.chip_6502.ni[`NODE_y2],
        uut.chip_6502.ni[`NODE_y1],
        uut.chip_6502.ni[`NODE_y0]
    };

    wire ir[7:0] = {
        uut.chip_6502.ni[`NODE_ir7],
        uut.chip_6502.ni[`NODE_ir6],
        uut.chip_6502.ni[`NODE_ir5],
        uut.chip_6502.ni[`NODE_ir4],
        uut.chip_6502.ni[`NODE_ir3],
        uut.chip_6502.ni[`NODE_ir2],
        uut.chip_6502.ni[`NODE_ir1],
        uut.chip_6502.ni[`NODE_ir0]
    };

    wire T[5:0] = {
        uut.chip_6502.ni[`NODE_t5],
        uut.chip_6502.ni[`NODE_t4],
        uut.chip_6502.ni[`NODE_t3],
        uut.chip_6502.ni[`NODE_t2],
        uut.chip_6502.ni[`NODE_clock2],
        uut.chip_6502.ni[`NODE_clock1]
    };

    wire alu[7:0] = {
        uut.chip_6502.ni[`NODE_alu7],
        uut.chip_6502.ni[`NODE_alu6],
        uut.chip_6502.ni[`NODE_alu5],
        uut.chip_6502.ni[`NODE_alu4],
        uut.chip_6502.ni[`NODE_alu3],
        uut.chip_6502.ni[`NODE_alu2],
        uut.chip_6502.ni[`NODE_alu1],
        uut.chip_6502.ni[`NODE_alu0]
    };

    wire alua[7:0] = {
        uut.chip_6502.ni[`NODE_alua7],
        uut.chip_6502.ni[`NODE_alua6],
        uut.chip_6502.ni[`NODE_alua5],
        uut.chip_6502.ni[`NODE_alua4],
        uut.chip_6502.ni[`NODE_alua3],
        uut.chip_6502.ni[`NODE_alua2],
        uut.chip_6502.ni[`NODE_alua1],
        uut.chip_6502.ni[`NODE_alua0]
    };

    wire alub[7:0] = {
        uut.chip_6502.ni[`NODE_alub7],
        uut.chip_6502.ni[`NODE_alub6],
        uut.chip_6502.ni[`NODE_alub5],
        uut.chip_6502.ni[`NODE_alub4],
        uut.chip_6502.ni[`NODE_alub3],
        uut.chip_6502.ni[`NODE_alub2],
        uut.chip_6502.ni[`NODE_alub1],
        uut.chip_6502.ni[`NODE_alub0]
    };

endmodule

