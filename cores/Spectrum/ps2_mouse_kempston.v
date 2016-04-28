`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:14:21 06/30/2015 
// Design Name: 
// Module Name:    ps2_mouse_kempston 
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

module ps2_mouse_kempston (
    input wire clk,
    input wire rst_n,
    inout wire clkps2,
    inout wire dataps2,
    //---------------------------------
    input wire [15:0] a,
    input wire iorq_n,
    input wire rd_n,
    output wire [7:0] kmouse_dout,
    output wire oe_n_kmouse,
    //---------------------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output wire [7:0] mousedata_dout,
    output wire oe_n_mousedata,
    output reg [7:0] mousestatus_dout,
    output wire oe_n_mousestatus
    );

    parameter MOUSEDATA = 8'h09;
    parameter MOUSESTATUS = 8'h0A;

    assign oe_n_mousedata = ~(zxuno_addr == MOUSEDATA && zxuno_regrd == 1'b1);
    assign oe_n_mousestatus = ~(zxuno_addr == MOUSESTATUS && zxuno_regrd == 1'b1);

    wire [7:0] mousedata;
    wire [7:0] kmouse_x, kmouse_y, kmouse_buttons;
    wire ps2busy;
    wire ps2error;
    wire nuevo_evento;
    wire [1:0] state_out;
    assign mousedata_dout = mousedata;
    
    wire kmouse_x_req_n    = ~(!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b1 && a[9]==1'b1 && a[10]==1'b0);
    wire kmouse_y_req_n    = ~(!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b1 && a[9]==1'b1 && a[10]==1'b1);
    wire kmouse_butt_req_n = ~(!iorq_n && !rd_n && a[7:0]==8'hDF && a[8]==1'b0);
    assign kmouse_dout     = (kmouse_x_req_n==1'b0)? kmouse_x :
                             (kmouse_y_req_n==1'b0)? kmouse_y :
                             (kmouse_butt_req_n==1'b0)? kmouse_buttons :
                             8'hZZ;
    assign oe_n_kmouse = kmouse_x_req_n & kmouse_y_req_n & kmouse_butt_req_n;
    
    /*
    | BSY | x | x | x | ERR | RLS | EXT | PEN |
    */
    reg reading_mousestatus = 1'b0;
    always @(posedge clk) begin
        mousestatus_dout[7:1] <= {ps2busy, 3'b000, ps2error, 2'b00};
        if (nuevo_evento == 1'b1)
            mousestatus_dout[0] <= 1'b1;
        if (oe_n_mousestatus == 1'b0)
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
