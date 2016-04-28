`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    15:18:53 03/06/2015 
// Design Name:    SAM Coupé clone
// Module Name:    ps2_keyb
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
module ps2_keyb(
    input wire clk,
    inout wire clkps2,
    inout wire dataps2,
    //---------------------------------
    input wire [8:0] rows,
    output wire [7:0] cols,
    output wire rst_out_n,
    output wire nmi_out_n,
    output wire mrst_out_n,
    output wire [1:0] user_toggles,
    //---------------------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire regaddr_changed,
    input wire [7:0] din,
    output wire [7:0] keymap_dout,
    output wire oe_n_keymap,
    output wire [7:0] scancode_dout,
    output wire oe_n_scancode,
    output reg [7:0] kbstatus_dout,
    output wire oe_n_kbstatus
    );

    parameter SCANCODE = 8'h04;
    parameter KBSTATUS = 8'h05;
    parameter KEYMAP = 8'h07;

    wire master_reset, user_reset, user_nmi;
    assign mrst_out_n = ~master_reset;
    assign rst_out_n = ~user_reset;
    assign nmi_out_n = ~user_nmi;
    
    assign oe_n_keymap = ~(zxuno_addr == KEYMAP && zxuno_regrd == 1'b1);
    assign oe_n_scancode = ~(zxuno_addr == SCANCODE && zxuno_regrd == 1'b1);
    assign oe_n_kbstatus = ~(zxuno_addr == KBSTATUS && zxuno_regrd == 1'b1);

    wire [7:0] kbcode;
    wire ps2busy;
    wire kberror;
    wire nueva_tecla;
    wire extended;
    wire released;
    assign scancode_dout = kbcode;    
    
    /*
    | BSY | x | x | x | ERR | RLS | EXT | PEN |
    */
    reg reading_kbstatus = 1'b0;
    always @(posedge clk) begin
        kbstatus_dout[7:1] <= {ps2busy, 3'b000, kberror, released, extended};
        if (nueva_tecla == 1'b1)
            kbstatus_dout[0] <= 1'b1;
        if (oe_n_kbstatus == 1'b0)
            reading_kbstatus <= 1'b1;
        else if (reading_kbstatus == 1'b1) begin
            kbstatus_dout[0] <= 1'b0;
            reading_kbstatus <= 1'b0;
        end
    end        

    ps2_port lectura_de_teclado (
        .clk(clk),
        .enable_rcv(~ps2busy),
        .kb_or_mouse(1'b0),
        .ps2clk_ext(clkps2),
        .ps2data_ext(dataps2),
        .kb_interrupt(nueva_tecla),
        .scancode(kbcode),
        .released(released),
        .extended(extended)
    );

    scancode_to_sam traductor (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla),
        .scan(kbcode),
        .extended(extended),
        .released(released),
        .sam_row(rows),
        .sam_col(cols),
        .master_reset(master_reset),
        .user_reset(user_reset),
        .user_nmi(user_nmi),
        .user_toggles(user_toggles),
        .din(din),
        .dout(keymap_dout),
        .cpuwrite(zxuno_addr == KEYMAP && zxuno_regwr == 1'b1),
        .cpuread(zxuno_addr == KEYMAP && zxuno_regrd == 1'b1),
        .rewind(regaddr_changed == 1'b1 && zxuno_addr == KEYMAP)
        );

    ps2_host_to_kb escritura_a_teclado (
        .clk(clk),
        .ps2clk_ext(clkps2),
        .ps2data_ext(dataps2),
        .data(din),
        .dataload(zxuno_addr == SCANCODE && zxuno_regwr== 1'b1),
        .ps2busy(ps2busy),
        .ps2error(kberror)
    );
endmodule
