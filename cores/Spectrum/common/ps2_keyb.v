`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 15:18:53 2015-06-03 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module ps2_keyb(
    input wire clk,
    inout wire clkps2,
    inout wire dataps2,
    //---------------------------------
    input wire [7:0] rows,
    output wire [4:0] cols,
    output wire [5:0] joy,
    output wire rst_out_n,
    output wire nmi_out_n,
    output wire mrst_out_n,
    output wire [13:0] user_fnt,  // 14 funciones especiales. Usaremos FF, STOP, PREVTRACK, PLAY, F1 F3 F4 F6 F7 F8 F9 F11 F12 y CTRL-F8
    output wire video_output_change,
    //---------------------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire regaddr_changed,
    input wire [7:0] din,
    output wire [7:0] keymap_dout,
    output wire oe_keymap,
    output wire [7:0] scancode_dout,
    output wire oe_scancode,
    output reg [7:0] kbstatus_dout,
    output wire oe_kbstatus,
	 output wire [1:0] monochrome_switcher
    );

`include "config.vh"

    wire master_reset, user_reset, user_nmi;
    assign mrst_out_n = ~master_reset;
    assign rst_out_n = ~user_reset;
    assign nmi_out_n = ~user_nmi;

    assign oe_keymap = (zxuno_addr == KEYMAP && zxuno_regrd == 1'b1);
    assign oe_scancode = (zxuno_addr == SCANCODE && zxuno_regrd == 1'b1);
    assign oe_kbstatus = (zxuno_addr == KBSTATUS && zxuno_regrd == 1'b1);

    wire [7:0] kbcode;
    wire ps2busy;
    wire kberror;
    wire nueva_tecla;
    wire no_hay_teclas_pulsadas;
    wire extended;
    wire released;
    wire shift_pressed, ctrl_pressed, alt_pressed;
    assign scancode_dout = kbcode;

    /*
    | BSY | x | x | x | ERR | RLS | EXT | PEN |
    */
    reg reading_kbstatus = 1'b0;
    always @(posedge clk) begin
      kbstatus_dout[7:1] <= {ps2busy, 3'b000, kberror, released, extended};
      if (nueva_tecla == 1'b1) begin
          kbstatus_dout[0] <= 1'b1;
      end
      if (oe_kbstatus == 1'b1)
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

    kb_special_functions funciones_especiales (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla),
        .scancode(kbcode),
        .extended(extended),
        .released(released),
        .shift_pressed(shift_pressed),
        .ctrl_pressed(ctrl_pressed),
        .alt_pressed(alt_pressed),
        .joyup(joy[3]),
        .joydown(joy[2]),
        .joyleft(joy[1]),
        .joyright(joy[0]),
        .joyfire(joy[4]),
        .joyfire2(joy[5]),
        .video_output_change(video_output_change),
        .master_reset(master_reset),
        .user_reset(user_reset),
        .user_nmi(user_nmi),
        .user_fnt(user_fnt),
        .monochrome_switcher(monochrome_switcher)

    );

    keyboard_pressed_status teclado_limpio (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla & ~kbcode[7]),
        .scancode(kbcode[6:0]),
        .extended(extended),
        .released(released),
        .kbclean(no_hay_teclas_pulsadas)
    );

    scancode_to_speccy traductor (
        .clk(clk),
        .rst(1'b0),
        .scan_received(nueva_tecla & ~kbcode[7]),
        .scan(kbcode[6:0]),
        .extended(extended),
        .released(released),
        .shift_pressed(shift_pressed),
        .ctrl_pressed(ctrl_pressed),
        .alt_pressed(alt_pressed),
        .kbclean(no_hay_teclas_pulsadas),
        .sp_row(rows),
        .sp_col(cols),
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
