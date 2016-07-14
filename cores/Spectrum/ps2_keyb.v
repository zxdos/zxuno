`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:18:53 06/03/2015 
// Design Name: 
// Module Name:    ps2_keyb 
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
module ps2_keyb(
    input wire clk,
    inout wire clkps2,
    inout wire dataps2,
    //---------------------------------
    input wire [7:0] rows,
    output wire [4:0] cols,
    output wire [4:0] joy,
    output wire rst_out_n,
    output wire nmi_out_n,
    output wire mrst_out_n,
    output wire [4:0] user_toggles,
    output reg video_output_change,    
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
    wire no_hay_teclas_pulsadas;
    wire extended;
    wire released;
    assign scancode_dout = kbcode;    
    
    /*
    | BSY | x | x | x | ERR | RLS | EXT | PEN |
    */
    reg reading_kbstatus = 1'b0;
    initial video_output_change = 1'b0;
    always @(posedge clk) begin
        kbstatus_dout[7:1] <= {ps2busy, 3'b000, kberror, released, extended};
        if (nueva_tecla == 1'b1) begin
            kbstatus_dout[0] <= 1'b1;
            if (kbcode == 8'h7E && released == 1'b0 && extended == 1'b0)  // SCRLock to change between RGB and VGA 60Hz
               video_output_change <= 1'b1;
            else
               video_output_change <= 1'b0;
        end
        if (oe_n_kbstatus == 1'b0)
            reading_kbstatus <= 1'b1;
        else if (reading_kbstatus == 1'b1) begin
            kbstatus_dout[0] <= 1'b0;
            reading_kbstatus <= 1'b0;
        end
        if (video_output_change == 1'b1)
            video_output_change <= 1'b0;
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

    keyboard_pressed_status teclado_limpio (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla),
        .scancode(kbcode),
        .extended(extended),
        .released(released),
        .kbclean(no_hay_teclas_pulsadas)
    );

    scancode_to_speccy traductor (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla),
        .scan(kbcode),
        .extended(extended),
        .released(released),
        .kbclean(no_hay_teclas_pulsadas),
        .sp_row(rows),
        .sp_col(cols),
        .joyup(joy[3]),
        .joydown(joy[2]),
        .joyleft(joy[1]),
        .joyright(joy[0]),
        .joyfire(joy[4]),
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
