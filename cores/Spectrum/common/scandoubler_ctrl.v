`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 01:22:53 2015-06-15 by Miguel Angel Rodriguez Jodar
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

module scandoubler_ctrl (
  input wire clk,
  input wire [15:0] a,
  input wire kbd_change_video_output,
  input wire kbd_turbo_boost,
  input wire turbo_boost_allowed,
  input wire iorq_n,
  input wire rd_n,
  input wire wr_n,
  input wire [7:0] zxuno_addr,
  input wire zxuno_regrd,
  input wire zxuno_regwr,
  input wire [7:0] din,
  output reg [7:0] dout,
  output reg oe,
  output wire vga_enable,
  output wire scanlines_enable,
  output wire [2:0] freq_option,
  output reg [3:0] cpu_speed,
  output wire csync_option
  );

`include "config.vh"
    
  reg [3:0] cpu_speed_reg = 4'b0000;
  
  reg [7:0] scandblctrl = INITIAL_VIDEO_VALUE;
  reg kbd_change_video_edge_detect = 1'b0;
  reg kbd_turbo_boost_edge_detect = 1'b0;
  reg ff_toggle_turbo = 1'b0;

`ifdef VGA_OUTPUT_OPTION
  assign vga_enable = scandblctrl[0];
  assign scanlines_enable = scandblctrl[1];
`else
  assign vga_enable = 1'b0;
  assign scanlines_enable = 1'b0;
`endif  
  assign freq_option = scandblctrl[4:2];
  assign csync_option = scandblctrl[5];
  
  always @* begin
    oe = 1'b0;
    dout = 8'hFF;

    if (ff_toggle_turbo == 1'b1)
      cpu_speed = 4'b0011;
    else
      cpu_speed = cpu_speed_reg;
    
    if (zxuno_addr == SCANDBLCTRL && zxuno_regrd == 1'b1) begin
      oe = 1'b1;
      if (ff_toggle_turbo == 1'b1)
        dout = {2'b11, scandblctrl[5:0]};
      else
        dout = scandblctrl;
    end
    else if (iorq_n == 1'b0 && rd_n == 1'b0 && a == PRISMSPEEDCTRL) begin
      oe = 1'b1;
      if (ff_toggle_turbo == 1'b1)
        dout = 8'b00000011;
      else
        dout = {4'b0000, cpu_speed_reg};
    end
  end
  
  always @(posedge clk) begin    
    kbd_change_video_edge_detect <= kbd_change_video_output;
    if (turbo_boost_allowed == 1'b1) begin
      kbd_turbo_boost_edge_detect <= kbd_turbo_boost;
      if (kbd_turbo_boost_edge_detect == 1'b0 && kbd_turbo_boost == 1'b1)
        ff_toggle_turbo <= 1'b1;
      else if (kbd_turbo_boost_edge_detect == 1'b1 && kbd_turbo_boost == 1'b0)
        ff_toggle_turbo <= 1'b0;
    end
      
    if (zxuno_addr == SCANDBLCTRL && zxuno_regwr == 1'b1) begin
      scandblctrl <= din;
      cpu_speed_reg <= {4'b00, din[7:6]};
    end
    else if (iorq_n == 1'b0 && wr_n == 1'b0 && a == PRISMSPEEDCTRL && din[7:4] == 4'b0000) begin
      scandblctrl <= {din[1:0], scandblctrl[5:0]};
      cpu_speed_reg <= din[3:0];
    end
    else if (kbd_change_video_edge_detect == 1'b0 && kbd_change_video_output == 1'b1)
      scandblctrl <= {scandblctrl[7:5], ((scandblctrl[0] == 1'b0)? 3'b111 : 3'b000), scandblctrl[1], ~scandblctrl[0]};
  end
endmodule
