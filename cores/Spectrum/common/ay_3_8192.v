`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 01:07:32 2020-02-22 by Miguel Angel Rodriguez Jodar
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

module ay_3_8192 (
  input wire clk,
  input wire clken,
  input wire rst_n,
  input wire a8,
  input wire bdir,
  input wire bc1,
  input wire bc2,
  input wire [7:0] din,
  output reg [7:0] dout,
  output reg oe_n,
  output reg [7:0] channel_a,
  output reg [7:0] channel_b,
  output reg [7:0] channel_c,
  input wire [7:0] port_a_din,
  output wire [7:0] port_a_dout,
  output wire port_a_oe_n
  );
  
  reg [11:0] period_a, period_b, period_c;
  reg [4:0] noise_period;
  reg [7:0] enable_chan;
    wire input_enable_b_n = enable_chan[7];
    wire input_enable_a_n = enable_chan[6];
    assign port_a_oe_n    = ~enable_chan[6];  // signal that data at PORT_A is valid because it is configured as an output port   
    wire enable_noise_c_n = enable_chan[5];
    wire enable_noise_b_n = enable_chan[4];
    wire enable_noise_a_n = enable_chan[3];
    wire enable_tone_c_n  = enable_chan[2];
    wire enable_tone_b_n  = enable_chan[1];
    wire enable_tone_a_n  = enable_chan[0];
  reg ampmode_a, ampmode_b, ampmode_c;
  reg [3:0] amp_a, amp_b, amp_c;
  reg [15:0] envelope_period;
  reg [3:0] envelope_shape;
    wire cont   = envelope_shape[3];
    wire attack = envelope_shape[2];
    wire altern = envelope_shape[1];
    wire hold   = envelope_shape[0];
  reg [7:0] reg_port_a, reg_port_b;
  assign port_a_dout = reg_port_a;
  reg [7:0] regaddr;

  initial begin
    regaddr         = 4'h0;
    period_a        = 12'h000;
    period_b        = 12'h000;
    period_c        = 12'h000;
    noise_period    = 5'b00000;
    enable_chan     = 8'hFF;
    ampmode_a       = 1'b0;
    ampmode_b       = 1'b0;
    ampmode_c       = 1'b0;
    amp_a           = 4'b0000;
    amp_b           = 4'b0000;
    amp_c           = 4'b0000;
    envelope_period = 16'h0000;
    envelope_shape  = 4'b0000;
    reg_port_a      = 8'h00;
    reg_port_b      = 8'h00;
  end
  
  ////////////// CPU interface /////////////////////////////////////////
  
  // CPU writes
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      regaddr         <= 4'h0;
      period_a        <= 12'h000;
      period_b        <= 12'h000;
      period_c        <= 12'h000;
      noise_period    <= 5'b00000;
      enable_chan     <= 8'hFF;
      ampmode_a       <= 1'b0;
      ampmode_b       <= 1'b0;
      ampmode_c       <= 1'b0;
      amp_a           <= 4'b0000;
      amp_b           <= 4'b0000;
      amp_c           <= 4'b0000;
      envelope_period <= 16'h0000;
      envelope_shape  <= 4'b0000;
      reg_port_a      <= 8'h00;
      reg_port_b      <= 8'h00;
    end
    else begin  
      if (a8 == 1'b1) begin
        case ({bdir,bc2,bc1})
          3'b001,
          3'b100,
          3'b111: regaddr <= din;  // latch PSG register address (all of it, including bits that are not used in register selection)
          3'b110: 
            begin // write to currently addressed PSG register
              if (regaddr[7:4] == 4'b0000) begin
                case (regaddr[3:0])
                  4'd0 : period_a[7:0]         <= din;
                  4'd1 : period_a[11:8]        <= din[3:0];
                  4'd2 : period_b[7:0]         <= din;
                  4'd3 : period_b[11:8]        <= din[3:0];
                  4'd4 : period_c[7:0]         <= din;
                  4'd5 : period_c[11:8]        <= din[3:0];
                  4'd6 : noise_period          <= din[4:0];
                  4'd7 : enable_chan           <= din;
                  4'd8 : {ampmode_a,amp_a}     <= din[4:0];
                  4'd9 : {ampmode_b,amp_b}     <= din[4:0];
                  4'd10: {ampmode_c,amp_c}     <= din[4:0];
                  4'd11: envelope_period[7:0]  <= din;
                  4'd12: envelope_period[15:8] <= din;
                  4'd13: envelope_shape        <= din[3:0];
                  4'd14: reg_port_a            <= din;
                  4'd15: reg_port_b            <= din;
                endcase
              end
            end
        endcase
      end
    end
  end
  
  reg reset_envelope;
  always @* begin
    if (a8 == 1'b1 && {bdir,bc2,bc1} == 3'b110 && regaddr == 8'd13)
      reset_envelope = 1'b1;
    else
      reset_envelope = 1'b0;
  end
  
  // CPU reads
  always @* begin
    dout = 8'hFF;
    oe_n = 1'b1;
    if (a8 == 1'b1) begin
      if ({bdir,bc2,bc1} == 3'b011) begin
        if (regaddr[7:4] == 4'b0000) begin
          oe_n = 1'b0;
          case (regaddr[3:0])
            4'd0 : dout = period_a[7:0];
            4'd1 : dout = {4'b0000, period_a[11:8]};
            4'd2 : dout = period_b[7:0];
            4'd3 : dout = {4'b0000, period_b[11:8]};
            4'd4 : dout = period_c[7:0];
            4'd5 : dout = {4'b0000, period_c[11:8]};
            4'd6 : dout = {3'b000, noise_period};
            4'd7 : dout = enable_chan;
            4'd8 : dout = {3'b000, ampmode_a, amp_a};
            4'd9 : dout = {3'b000, ampmode_b, amp_b};
            4'd10: dout = {3'b000, ampmode_c, amp_c};
            4'd11: dout = envelope_period[7:0];
            4'd12: dout = envelope_period[15:8];
            4'd13: dout = {4'b0000, envelope_shape};
            4'd14: dout = (input_enable_a_n == 1'b0)? port_a_din : reg_port_a;
            4'd15: dout = (input_enable_b_n == 1'b0)? 8'hFF : reg_port_b;  // PORT_B is not available at AY-3-8912, so input always read $FF
            default: dout = 8'hFF;
          endcase
        end
      end
    end
  end
  
  ////////////// Tone and noise generation /////////////////////////////////////////
  
  reg [15:0] divprescaler = 16'h0001; 
  wire clken_presc = divprescaler[0] | divprescaler[8];
  wire clken_presc_env = divprescaler[0];
  // Prescaler for note, noise and envelope generator.
  always @(posedge clk) begin
    if (rst_n == 1'b0)
      divprescaler <= 16'h0001;
    else if (clken == 1'b1)
      divprescaler <= {divprescaler[14:0], divprescaler[15]};
  end
  
  reg tone_a = 1'b0, tone_b = 1'b0, tone_c = 1'b0, tone_noise = 1'b0;
  reg [11:0] counter_tone_a, counter_tone_b, counter_tone_c;
  reg [4:0] counter_noise;
  reg [16:0] noise_shiftreg = 17'h00001;
  
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      tone_a <= 1'b0;
      tone_b <= 1'b0;
      tone_c <= 1'b0;
      tone_noise <= 1'b0;
      counter_tone_a <= 12'h001;
      counter_tone_b <= 12'h001;
      counter_tone_c <= 12'h001;
      counter_noise <= 5'b00001;
      noise_shiftreg <= 17'h00001;
    end
    else begin
      if (clken == 1'b1 && clken_presc == 1'b1) begin
        // Tone generator A 
        if (counter_tone_a >= period_a) begin
          tone_a <= ~tone_a;
          counter_tone_a <= 12'h001;
        end
        else begin
          counter_tone_a <= counter_tone_a + 12'h001;
        end
        // Tone generator B
        if (counter_tone_b >= period_b) begin
          tone_b <= ~tone_b;
          counter_tone_b <= 12'h001;
        end
        else begin
          counter_tone_b <= counter_tone_b + 12'h001;
        end
        // Tone generator C
        if (counter_tone_c >= period_c) begin
          tone_c <= ~tone_c;
          counter_tone_c <= 12'h001;
        end
        else begin
          counter_tone_c <= counter_tone_c + 12'h001;
        end
        // Noise generator
        if (counter_noise >= noise_period) begin
          counter_noise <= 5'b00001;
          /* MAME DRIVER: The Random Number Generator of the 8910 is a 17-bit shift */
          /* register. The input to the shift register is bit0 XOR bit3 */
          /* (bit0 is the output). This was verified on AY-3-8910 and YM2149 chips. */
          noise_shiftreg <= {noise_shiftreg[0] ^ noise_shiftreg[3], noise_shiftreg[16:1]};
          tone_noise <= tone_noise ^ noise_shiftreg[0];  // el bit 0 del shitreg se usa para toglear el bit de ruido final
        end
        else begin
          counter_noise <= counter_noise + 5'b00001;
        end
      end // del if que guarda que sólo se hagan cosas cuando toca    
    end  // del no reset
  end  // del always @(posedge.....)

  ////////////// Channel mixer /////////////////////////////////////////

  // al parecer, cuando se deshabilita el tono o el ruido, la señal se queda a 1, así puede seguir operando la envolvente
  // Por eso el datasheet insiste en que para deshabilitar de verdad un canal, hay que poner su volumen a 0
  wire tone_noise_a = (tone_a | enable_tone_a_n) & (tone_noise | enable_noise_a_n);
  wire tone_noise_b = (tone_b | enable_tone_b_n) & (tone_noise | enable_noise_b_n);
  wire tone_noise_c = (tone_c | enable_tone_c_n) & (tone_noise | enable_noise_c_n);
  
  ////////////// Envelope generator /////////////////////////////////////////
  
  reg [3:0] envelope;
  // envelope shapes
  // C AtAlH
  // 0 0 x x  \___
  //
  // 0 1 x x  /___
  //
  // 1 0 0 0  \\\\
  //
  // 1 0 0 1  \___
  //
  // 1 0 1 0  \/\/
  //           ___
  // 1 0 1 1  \
  //
  // 1 1 0 0  ////
  //           ___
  // 1 1 0 1  /
  //
  // 1 1 1 0  /\/\
  //
  // 1 1 1 1  /___
  
  // Sequence counter for envelope generation
  reg [4:0] envelope_sample_seq = 5'h00;
  reg env_shape_first_period = 1'b1;
  reg [15:0] counter_envelope = 16'h0001;
  always @(posedge clk) begin
    if (rst_n == 1'b0 || reset_envelope == 1'b1) begin
      envelope_sample_seq <= 5'h00;
      env_shape_first_period <= 1'b1;
      counter_envelope <= 16'h0001;
    end
    else begin
      if (clken == 1'b1 && clken_presc_env == 1'b1) begin
        if (counter_envelope >= envelope_period) begin
          counter_envelope <= 16'h0001;
          if (envelope_sample_seq == 5'b0_1111)
            env_shape_first_period <= 1'b0;
          envelope_sample_seq <= envelope_sample_seq + 5'h01;
        end
        else
          counter_envelope <= counter_envelope + 16'd1;
      end
    end
  end

  // Comb part of FSM for envelope generation  
  always @* begin
    envelope = 4'b1111;
    if (env_shape_first_period == 1'b1) begin   // primer ciclo de la envolvente
      if (attack == 1'b1)                       // en el primer ciclo sólo se tiene en cuenta attack
        envelope = envelope_sample_seq[3:0];
      else
        envelope = ~envelope_sample_seq[3:0];
    end
    else begin                                  // segundo y siguientes ciclos de la envolvente
      if (cont == 1'b0)                         // CONTINUE = 0. dos primeras envolventes del datasheet. Tras el primer periodo, se quedan a 0
        envelope = 4'b0000;
      else begin                                
        if (hold == 1'b1) begin                 // CONTINUE = 1, HOLD = 1. Se queda la envolvente con 0 o 15 según los valores de attack y alternate
          case ({attack,altern})
            2'b00, 2'b11: envelope = 4'b0000;
            2'b01, 2'b10: envelope = 4'b1111;
          endcase
        end
        else begin                              // CONTINUE = 1, HOLD = 0. Las 4 formas de onda que se repiten en el tiempo
          case ({attack,altern})
            2'b00: envelope = ~envelope_sample_seq[3:0];
            2'b01: 
              if (envelope_sample_seq[4] == 1'b0)
                envelope = ~envelope_sample_seq[3:0];
              else
                envelope = envelope_sample_seq[3:0];
            2'b10: envelope = envelope_sample_seq[3:0];
            2'b11:
              if (envelope_sample_seq[4] == 1'b0)
                envelope = envelope_sample_seq[3:0];
              else
                envelope = ~envelope_sample_seq[3:0];
          endcase
        end
      end
    end
  end
  
  ////////////// Amp control /////////////////////////////////////////
  
  reg [3:0] linear_chan_a, linear_chan_b, linear_chan_c;
  always @(posedge clk) begin
    if (clken == 1'b1) begin
      linear_chan_a <= ((ampmode_a == 1'b0)? amp_a : envelope) & {4{tone_noise_a}};
      linear_chan_b <= ((ampmode_b == 1'b0)? amp_b : envelope) & {4{tone_noise_b}};
      linear_chan_c <= ((ampmode_c == 1'b0)? amp_c : envelope) & {4{tone_noise_c}};
    end
  end
  
  ////////////// DAC /////////////////////////////////////////
  
  reg [7:0] lin2log[0:15];
  initial begin  // valores tomados de medidas hechas en el proyecto MAME
    lin2log[0]  = 8'd0;
    lin2log[1]  = 8'd3;
    lin2log[2]  = 8'd4;
    lin2log[3]  = 8'd6;
    lin2log[4]  = 8'd9;
    lin2log[5]  = 8'd13;
    lin2log[6]  = 8'd18;
    lin2log[7]  = 8'd29;
    lin2log[8]  = 8'd34;
    lin2log[9]  = 8'd55;
    lin2log[10] = 8'd77;
    lin2log[11] = 8'd98;
    lin2log[12] = 8'd130;
    lin2log[13] = 8'd166;
    lin2log[14] = 8'd208;
    lin2log[15] = 8'd255;
  end
  
//  initial begin  // lin2log[i] = 255*(16^(i/15)-1)/15
//    lin2log[0]  = 8'd0;
//    lin2log[1]  = 8'd3;
//    lin2log[2]  = 8'd8;
//    lin2log[3]  = 8'd13;
//    lin2log[4]  = 8'd19;
//    lin2log[5]  = 8'd26;
//    lin2log[6]  = 8'd35;
//    lin2log[7]  = 8'd45;
//    lin2log[8]  = 8'd58;
//    lin2log[9]  = 8'd73;
//    lin2log[10] = 8'd91;
//    lin2log[11] = 8'd113;
//    lin2log[12] = 8'd139;
//    lin2log[13] = 8'd171;
//    lin2log[14] = 8'd209;
//    lin2log[15] = 8'd255;
//  end

  always @(posedge clk) begin
    if (clken == 1'b1) begin
      channel_a <= lin2log[linear_chan_a];
      channel_b <= lin2log[linear_chan_b];
      channel_c <= lin2log[linear_chan_c];
    end
  end

//  always @(posedge clk) begin
//    if (clken == 1'b1) begin
//      channel_a <= {linear_chan_a, linear_chan_a};
//      channel_b <= {linear_chan_b, linear_chan_b};
//      channel_c <= {linear_chan_c, linear_chan_c};
//    end
//  end 
endmodule
