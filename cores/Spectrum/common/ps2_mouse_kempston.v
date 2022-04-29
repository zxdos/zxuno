`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 17:14:21 2015-06-30 by Miguel Angel Rodriguez Jodar
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

module ps2_mouse_kempston (
    input wire clk,
    input wire rst_n,
    inout wire clkps2,
    inout wire dataps2,
    //---------------------------------
    input wire [15:0] a,
    input wire iorq_n,
    input wire rd_n,
    output reg [7:0] kmouse_dout,
    output reg oe_kmouse,
    //---------------------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output wire [7:0] mousedata_dout,
    output wire oe_mousedata,
    output reg [7:0] mousestatus_dout,
    output wire oe_mousestatus
    );

`include "config.vh"

    assign oe_mousedata = (zxuno_addr == MOUSEDATA && zxuno_regrd == 1'b1);
    assign oe_mousestatus = (zxuno_addr == MOUSESTATUS && zxuno_regrd == 1'b1);

    wire [7:0] mousedata;
    wire [7:0] kmouse_x, kmouse_y, kmouse_buttons;
    wire ps2busy;
    wire ps2error;
    wire nuevo_evento;
    wire [1:0] state_out;
    assign mousedata_dout = mousedata;

    wire kmouse_x_req    = (!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b1 && a[9]==1'b1 && a[10]==1'b0 && a[11]==1'b1);
    wire kmouse_y_req    = (!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b1 && a[9]==1'b1 && a[10]==1'b1 && a[11]==1'b1);
    wire kmouse_butt_req = (!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b0 && a[9]==1'b1 && a[10]==1'b0 && a[11]==1'b1);

    always @* begin
      oe_kmouse = (kmouse_x_req | kmouse_y_req | kmouse_butt_req);
      case (1'b1)
        kmouse_x_req    : kmouse_dout = kmouse_x;
        kmouse_y_req    : kmouse_dout = kmouse_y;
        kmouse_butt_req : kmouse_dout = kmouse_buttons;
        default         : kmouse_dout = 8'hFF;
      endcase
    end

    /*
    | BSY | 0 | 0 | 0 | ERR | 0 | 0 | DATA_AVL |
    */
    reg reading_mousestatus = 1'b0;
    always @(posedge clk) begin
        mousestatus_dout[7:1] <= {ps2busy, 3'b000, ps2error, 2'b00};
        if (nuevo_evento == 1'b1)
            mousestatus_dout[0] <= 1'b1;
        if (oe_mousestatus == 1'b1)
            reading_mousestatus <= 1'b1;
        else if (reading_mousestatus == 1'b1) begin
            mousestatus_dout[0] <= 1'b0;
            reading_mousestatus <= 1'b0;
        end
    end

    ps2_port lectura_de_raton (
        .clk(clk),
        .enable_rcv(~ps2busy),
        .kb_or_mouse(1'b1),
        .ps2clk_ext(clkps2),

        .ps2data_ext(dataps2),
        .kb_interrupt(nuevo_evento),
        .scancode(mousedata),
        .released(),
        .extended()
    );

    ps2mouse_to_kmouse traductor_raton (
        .clk(clk),
        .rst_n(rst_n),
        .data(mousedata),
        .data_valid(nuevo_evento),
        .kmouse_x(kmouse_x),
        .kmouse_y(kmouse_y),
        .kmouse_buttons(kmouse_buttons)
    );

    ps2_host_to_kb escritura_a_raton (
        .clk(clk),
        .ps2clk_ext(clkps2),
        .ps2data_ext(dataps2),
        .data(din),
        .dataload(zxuno_addr == MOUSEDATA && zxuno_regwr== 1'b1),
        .ps2busy(ps2busy),
        .ps2error(ps2error)
    );
endmodule
