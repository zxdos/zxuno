`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 00:24:56 2016-05-08 by Miguel Angel Rodriguez Jodar
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

module control_enable_options(
    input wire clk,
    input wire rst_n,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe,
    output wire disable_ay,
    output wire disable_turboay,
    output wire disable_7ffd,
    output wire disable_1ffd,
    output wire disable_romsel7f,
    output wire disable_romsel1f,
    output wire enable_timexmmu,
    output wire disable_spisd,
    output wire disable_timexscr,
    output wire disable_ulaplus,
    output wire disable_radas,
    output wire disable_specdrum,
    output wire disable_mixer,
	 output wire joy_splitter
    );

`include "config.vh"
    
    reg [7:0] devoptions = 8'b00101000;  // initial value. Modo 128K
    reg [7:0] devopts2 = 8'h00;    // initial value
    assign disable_ay = devoptions[0];
`ifdef TURBOSUND_SUPPORT    
    assign disable_turboay = devoptions[1];
`else
    assign disable_turboay = 1'b1;
`endif    
    assign disable_7ffd = devoptions[2];
    assign disable_1ffd = devoptions[3];
    assign disable_romsel7f = devoptions[4];
    assign disable_romsel1f = devoptions[5];
`ifdef ULA_TIMEX_SUPPORT
    assign enable_timexmmu = devoptions[6];
`else
    assign enable_timexmmu = 1'b0;
`endif    
`ifdef DIVMMC_SUPPORT
    assign disable_spisd = devoptions[7];
`else
    assign disable_spisd = 1'b1;
`endif
`ifdef ULAPLUS_SUPPORT
    assign disable_ulaplus = devopts2[0];
`else
    assign disable_ulaplus = 1'b1;
`endif    
`ifdef ULA_TIMEX_SUPPORT
    assign disable_timexscr = devopts2[1];
`else
    assign disable_timexscr = 1'b1;
`endif
`ifdef ULA_RADASTAN_SUPPORT
    assign disable_radas = devopts2[2];
`else
    assign disable_radas = 1'b1;
`endif    
`ifdef SPECDRUM_COVOX_SUPPORT
    assign disable_specdrum = devopts2[3];
`else
    assign disable_specdrum = 1'b1;
`endif    
    assign disable_mixer = devopts2[4];
`ifdef JOYSPLITTER_SUPPORT
    assign joy_splitter = devopts2[5];
`else
    assign joy_splitter = 1'b0;
`endif
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            devoptions <= 8'h00;  // or after a hardware reset (not implemented yet)
            devopts2 <= 8'h00;
        end
        else if (zxuno_addr == DEVOPTIONS && zxuno_regwr == 1'b1)
            devoptions <= din;
        else if (zxuno_addr == DEVOPTS2 && zxuno_regwr == 1'b1)
            devopts2 <= din;
    end
    
    always @* begin
        oe = 1'b0;
        dout = 8'hFF;
        if (zxuno_regrd == 1'b1)            
            if (zxuno_addr == DEVOPTIONS) begin
                oe = 1'b1;
                dout = { disable_spisd, enable_timexmmu, devoptions[5:2], disable_turboay, devoptions[0] };
            end
            else if (zxuno_addr == DEVOPTS2) begin
                oe = 1'b1;
                dout = { devopts2[7:4], disable_specdrum, disable_radas, disable_timexscr, disable_ulaplus };
            end
        end
endmodule
