`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 08:50:32 2019-07-31 by Miguel Angel Rodriguez Jodar
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

module i2s_decoder (
  input wire clk,
  input wire sck,
  input wire ws,
  input wire sd,
  output reg [15:0] left_out,
  output reg [15:0] right_out
  );
  
  reg [1:0] sck_synch = 2'b00, ws_synch = 2'b00, sd_synch = 2'b00;
  wire scks = sck_synch[1], wss = ws_synch[1], sds = sd_synch[1];
  reg scks_prev = 1'b0, wss_prev = 1'b0;
  reg [17:0] sreg = 17'b0_0000_0000_0000_0001;
  
  always @(posedge clk) begin
    // sincronizar señales de entrada
    sck_synch[1] <= sck_synch[0];
    sck_synch[0] <= sck;
    ws_synch[1] <= ws_synch[0];
    ws_synch[0] <= ws;
    sd_synch[1] <= sd_synch[0];
    sd_synch[0] <= sd;
    
    scks_prev <= scks;
    if (scks_prev == 1'b0 && scks == 1'b1) begin  // flanco positivo de SCK
      wss_prev <= wss;
      if (wss_prev != wss) begin // ha ocurrido flanco en WS ?
        if (wss_prev == 1'b0)
          left_out <= sreg[15:0];
        else
          right_out <= sreg[15:0];
        sreg <= 17'b0_0000_0000_0000_0001;
      end      
      else begin
        if (sreg[16] == 1'b0) begin
          sreg <= {sreg[15:0], sds};
        end
      end
    end
  end
endmodule
