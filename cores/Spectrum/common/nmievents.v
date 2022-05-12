`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 03:05:03 2015-06-28 by Miguel Angel Rodriguez Jodar
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

module nmievents (
    input wire clk,
    input wire rst_n,
    //------------------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    //------------------------------
    input wire [4:0] userevents,
    //------------------------------
    input wire [15:0] a,
    input wire m1_n,
    input wire mreq_n,
    input wire rd_n,
    output wire [7:0] dout,
    output wire oe_n,
    output reg nmiout_n,
    output reg page_configrom_active
    );
    
`include "config.vh"

    parameter IDLE          = 1'd0,
              ABOUT_TO_EXIT = 1'd1;
    
    initial page_configrom_active = 1'b0;
    initial nmiout_n = 1'b1;
        
    reg state = IDLE;        
    reg [7:0] nmieventreg = 8'h00;
    assign dout = nmieventreg;
    assign oe_n = ~(zxuno_addr == NMIEVENT && zxuno_regrd == 1'b1);    
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            nmieventreg <= 8'h00;
            page_configrom_active <= 1'b0;
            state <= IDLE;
        end
        else begin            
            if (userevents != 5'b00000 && page_configrom_active == 1'b0) begin
                nmieventreg <= {3'b000, userevents};
                nmiout_n <= 1'b0;
                page_configrom_active <= 1'b1;
                state <= IDLE;
            end
            if (mreq_n == 1'b0 && m1_n == 1'b0 && a == 16'h0066 && page_configrom_active == 1'b1)  // ya estamos en NMI
                nmiout_n <= 1'b1;  // asi que desactivo la señal
            
            case (state)
                IDLE: 
                  begin
                    if (mreq_n == 1'b0 && m1_n == 1'b0 && rd_n == 1'b0 && a==16'h006A && page_configrom_active == 1'b1)
                        state <= ABOUT_TO_EXIT;
                  end
                ABOUT_TO_EXIT: 
                  begin
                    if (m1_n == 1'b1) begin
                        page_configrom_active <= 1'b0;
                        nmieventreg <= 8'h00;
                        state <= IDLE;
                    end
                  end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
