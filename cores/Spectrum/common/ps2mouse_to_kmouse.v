`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 18:52:22 2015-06-30 by Miguel Angel Rodriguez Jodar
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

module ps2mouse_to_kmouse (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] kmouse_x,
    output reg [7:0] kmouse_y,
    output reg [7:0] kmouse_buttons
    );
    
    parameter FIRST_FRAME     = 2'd0,
              SECOND_FRAME    = 2'd1,
              THIRD_FRAME     = 2'd2,
              CALCULATE_NEWXY = 2'd3;
    
    initial begin
        kmouse_x = 8'h00;
        kmouse_y = 8'h00;
        kmouse_buttons = 8'hFF;
    end    
    
    reg [7:0] deltax, deltay;
    reg [1:0] state = FIRST_FRAME;
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            kmouse_x <= 8'h00;
            kmouse_y <= 8'h00;
            kmouse_buttons <= 8'hFF;
            state <= FIRST_FRAME;
        end
        else begin
            case (state)
                FIRST_FRAME: 
                    if (data_valid == 1'b1) begin
                        if (data[3] == 1'b1) begin
                            kmouse_buttons <= {5'b11111,~data[2],~data[0],~data[1]};
                            state <= SECOND_FRAME;                            
                        end
                    end
                SECOND_FRAME:
                    if (data_valid == 1'b1) begin
                        deltax <= data;
                        state <= THIRD_FRAME;
                    end
                THIRD_FRAME:
                    if (data_valid == 1'b1) begin
                        deltay <= data;
                        state <= CALCULATE_NEWXY;
                    end
                CALCULATE_NEWXY:
                    begin
                        kmouse_x <= kmouse_x + deltax;
                        kmouse_y <= kmouse_y + deltay;
                        state <= FIRST_FRAME;
                    end
            endcase
        end
    end
endmodule
