`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core.
//    Creation date is 11:43:22 2015-06-16 by Miguel Angel Rodriguez Jodar
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

module pzx_player (
    input wire clk,
    input wire sram_access_allowed,
    input wire rst_n,
    //--------------------
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output wire [7:0] dout,
    output wire oe,
    //--------------------
    input wire in48kmode,
    input wire [1:0] cpu_speed,
    input wire [1:0] memory_register,
    input wire play_in,
    input wire stop_in,
	input wire rewindTo0Counter_in,
	input wire resetTo0Counter_in,
    input wire jump_in,
    output wire pulse_out,
    output wire playing,
    output reg speed_change_allowed,
    //--------------------
    output wire [20:0] sramaddr,
    output wire sramwe,
    input wire [7:0] sramdin,
    output wire [7:0] sramdout
    );

//    parameter INITSRAM_ADDR = 21'h032000;
//    parameter LENGTH_SRAM  = 21'h04E000;

// Para placas con 1MB de SRAM o más
//    parameter INITSRAM_ADDR = 21'h080000;
//    parameter ENDSRAM_ADDR  = 21'h080000;

`include "config.vh"

    parameter IDLE          = 6'd0,
              PROGRESS      = 6'd1,
              INCADD        = 6'd2,
              READTAG       = 6'd3,
              READLTAG1     = 6'd4,
              READLTAG2     = 6'd5,
              READLTAG3     = 6'd6,
              READLTAG4     = 6'd7,
              STOP1         = 6'd8,
              PULSE1        = 6'd9,
              PULSE2        = 6'd10,
              PULSE3        = 6'd11,
              PULSE4        = 6'd12,
              PULSE5        = 6'd13,
              PULSE6        = 6'd14,
              DOPULSE       = 6'd15,
              FULLSTOP1     = 6'd16,
              DATA1         = 6'd17,
              DATA2         = 6'd18,
              DATA3         = 6'd19,
              DATA4         = 6'd20,
              DATATAIL1     = 6'd21,
              DATATAIL2     = 6'd22,
              READNPULSE0   = 6'd23,
              READNPULSE1   = 6'd24,
              READDPULSE0_1 = 6'd25,
              READDPULSE0_2 = 6'd26,
              READDPULSE1_1 = 6'd27,
              READDPULSE1_2 = 6'd28,
              READDATA1     = 6'd29,
              OUTPUTBIT1    = 6'd30,
              OUTPUTBIT2    = 6'd31,
              DATADOTAIL    = 6'd32;

    parameter FULLSTOP      = 8'd0,
              STOP          = 8'd1,
              PULSE         = 8'd2,
              DATA          = 8'd3,
              BROWSE        = 8'd4;

    wire [20:0] initsram_addr = (memory_register == 2'b00)? 21'h032000 : 21'h080000;
    wire [20:0] length_sram = (memory_register == 2'b00)? 21'h04E000 :
                              (memory_register == 2'b01)? 21'h080000 :
                                                          21'h180000;
    reg [20:0] a = 21'h000000;
    reg [20:0] tag_address = 21'h000000;
    assign sramaddr = initsram_addr + a + ((a > 21'hDFFF && memory_register == 2'b00) ? 21'h18000 : 0);

    reg [20:0] counter0_address = 21'h000000;
    reg flagResetCounter0 = 1'b0;

    assign oe = (zxuno_addr == SRAMDATA && zxuno_regrd == 1'b1);
    assign sramwe = (zxuno_addr == SRAMDATA && zxuno_regwr == 1'b1);
    assign sramdout = din;
    assign dout = sramdin;

    reg [1:0] vdeckctrl = 2'b00;
    reg [1:0] vdeckprev = 2'b00;
    always @(posedge clk) begin
      if (rst_n == 1'b0) begin
        vdeckctrl <= 2'b00;
        vdeckprev <= 2'b00;
      end
      else begin
        if (zxuno_addr == VDECKCTRL && zxuno_regwr == 1'b1) begin
          vdeckprev <= vdeckctrl;
          vdeckctrl <= din[1:0];
        end
      end
    end
    wire soft_play_in = vdeckprev[0] & ~vdeckctrl[0];
    wire soft_stop_in = vdeckprev[1] & ~vdeckctrl[1];

    reg [1:0] edplay = 2'b00;
    reg [1:0] edstop = 2'b00;
    reg [1:0] edjump = 2'b00;
    reg [1:0] edrewind = 2'b00;
    reg [1:0] edresetcounter0 = 2'b00;
    wire play = (edplay == 2'b01) | soft_play_in;
    wire stop = (edstop == 2'b01) | soft_stop_in;
    wire jump = (edjump == 2'b01);
    wire rewindTo0Counter = (edrewind == 2'b01);
    wire resetTo0Counter = (edresetcounter0 == 2'b01);
    always @(posedge clk) begin
      edplay <= {edplay[0], play_in};
      edstop <= {edstop[0], stop_in};
      edjump <= {edjump[0], jump_in};
      edrewind <= {edrewind[0], rewindTo0Counter_in};
      edresetcounter0 <= {edresetcounter0[0], resetTo0Counter_in};
    end

    // Variables para la reproducción de audio
    reg play_enabled = 1'b0;
    reg [7:0] tag = 8'h00;
    reg [31:0] lblock = 32'h0;      // longitud en bytes del bloque actual
    reg [30:0] duration = 31'h0;
    reg [33:0] cduration = 34'h0;   // cuenta ciclos de 28MHz hasta alcanzar el valor de duration
    reg [15:0] pulsecounter = 16'h0;
    reg [15:0] pulse0[0:31];
    reg [15:0] pulse1[0:31];
    reg [4:0] indexpulse = 5'd0;
    reg [4:0] numberpulse0 = 5'd0;
    reg [4:0] numberpulse1 = 5'd0;
    reg [30:0] numberofbits = 31'h0;
    reg [15:0] durationextrapulse = 16'h0000;
    reg [7:0] databyte = 8'h00;
    reg [3:0] countbits = 4'd0;
    reg pulse = 1'b0;
    reg next_pulse = 1'b0;
    assign pulse_out = pulse;
    assign playing = play_enabled;
    wire [33:0] adj_duration = (cpu_speed == 2'b00)? {duration, 3'b000} :
                               (cpu_speed == 2'b01)? {1'b0, duration, 2'b00} :
                               (cpu_speed == 2'b10)? {2'b00, duration, 1'b0} :
                                                     {3'b000, duration};
    integer i;
    initial begin
        for (i=0;i<32;i=i+1) begin
            pulse0[i] = 8'h00;
            pulse1[i] = 8'h00;
        end
    end

    reg [5:0] state = IDLE;
    always @(posedge clk) begin
      if (rst_n == 1'b0 || stop) begin
          state <= IDLE;
          play_enabled <= 1'b0;
          a <= 21'h000000;
          if (rst_n == 1'b0) begin
            tag_address <= 21'h000000;
            counter0_address <= 21'h000000;
          end
      end
      else if (play) begin
          play_enabled <= ~play_enabled;
      end
      else if (jump) begin
          pulse <= 1'b0;
          a <= tag_address;
          state <= READTAG;
      end
      else if (rewindTo0Counter) begin
          pulse <= 1'b0;
          a <= counter0_address;
          state <= READTAG;
      end
      else if (resetTo0Counter) begin
          flagResetCounter0 <= 1'b1;
      end
      else if (a == length_sram) begin
        a <= 21'h000000;
      end
      else begin
          case (state)
          IDLE:
              begin
                  if ((zxuno_addr == SRAMDATA || zxuno_addr == SRAMADDRINC) && (zxuno_regrd == 1'b1 || zxuno_regwr == 1'b1))
                      state <= PROGRESS;
                  else if (zxuno_addr == SRAMADDR && zxuno_regwr == 1'b1) begin
                      a <= {a[12:0],din};
                      state <= PROGRESS;
                  end
                  else if (play_enabled == 1'b1) begin
                      pulse <= 1'b0;
                      a <= 21'h000000;
                      state <= READTAG;
                  end
              end
          PROGRESS:
              begin
                  if (zxuno_regrd == 1'b0 && zxuno_regwr == 1'b0) begin
                      if (zxuno_addr == SRAMADDRINC)
                          state <= INCADD;
                      else
                          state <= IDLE;
                  end
              end
          INCADD:
              begin
                  a <= a + 21'd1;
                  state <= IDLE;
              end
              //------------------------------------------
          READTAG:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  if (flagResetCounter0) begin
                      counter0_address <= a;
                      flagResetCounter0 <= 1'b0;
                  end
                  tag <= sramdin;
                  a <= a + 21'd1;
                  state <= READLTAG1;
              end
          READLTAG1:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  lblock[7:0] <= sramdin;  // LSB
                  a <= a + 21'd1;
                  state <= READLTAG2;
              end
          READLTAG2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  lblock[15:8] <= sramdin;
                  a <= a + 21'd1;
                  state <= READLTAG3;
              end
          READLTAG3:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  lblock[23:16] <= sramdin;
                  a <= a + 21'd1;
                  state <= READLTAG4;
              end
          READLTAG4:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  lblock[31:24] <= sramdin;  // Ya tenemos en lblock el tamaño del bloque
                  a <= a + 21'd1;
                  if (tag == STOP) begin
                      if (lblock[7:0] != 8'd1 || in48kmode == 1'b1)
                          state <= STOP1;
                      else
                          state <= READTAG;
                  end
                  else if (tag == PULSE) begin
                      next_pulse <= 1'b0;  // Valor inicial del pulso en este bloque
                      state <= PULSE1;
                  end
                  else if (tag == DATA)
                      state <= DATA1;
                  else if (tag == BROWSE) begin
                      state <= READTAG;
                      tag_address <= a + 21'd1;
                  end
                  else begin
                      state <= FULLSTOP1;
                      durationextrapulse <= 16'h6d60; // 1ms en ciclos de 28MHz
                  end
              end

          FULLSTOP1:
              if (play_enabled == 1'b1) begin
                  if (durationextrapulse != 16'h0000)
                    durationextrapulse <= durationextrapulse - 1;
                  else begin
                    play_enabled <= 1'b0;
                    //a <= 21'h000000;
                    state <= IDLE;
                  end
              end

          STOP1:
              if (play_enabled == 1'b1) begin
                  play_enabled <= 1'b0;  // se para la maquina de estados
                  state <= READTAG;
              end
          PULSE1:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  if (lblock !=32'h00000000) begin
                      cduration <= 34'h000000000;
                      duration[7:0] <= sramdin;
                      pulsecounter <= 16'h0001;
                      a <= a + 21'd1;
                      lblock <= lblock - 1;
                      state <= PULSE2;
                  end
                  else begin
                      state <= READTAG;
                  end
              end
          PULSE2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  duration[15:8] <= sramdin;
                  a <= a + 21'd1;
                  lblock <= lblock - 1;
                  state <= PULSE3;
              end
          PULSE3:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  if (duration[15:0]>16'h8000) begin
                      pulsecounter <= {1'b0,duration[14:0]};
                      duration[7:0] <= sramdin;
                      a <= a + 21'd1;
                      lblock <= lblock - 1;
                      state <= PULSE4;
                  end
                  else begin
                      state <= PULSE5;
                  end
              end
          PULSE4:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  duration[15:8] <= sramdin;
                  a <= a + 21'd1;
                  lblock <= lblock - 1;
                  state <= PULSE5;
              end
          PULSE5:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  if (duration[15] == 1'b1) begin
                      duration[23:16] <= duration[7:0];
                      duration[30:24] <= duration[14:8];
                      duration[7:0] <= sramdin;
                      a <= a + 21'd1;
                      lblock <= lblock - 1;
                      state <= PULSE6;
                  end
                  else begin
                      duration[30:16] <= 15'h0000;
                      state <= DOPULSE;
                  end
              end
          PULSE6:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  duration[15:8] <= sramdin;
                  a <= a + 21'd1;
                  lblock <= lblock - 1;
                  state <= DOPULSE;
              end
          DOPULSE:
              if (play_enabled == 1'b1) begin
                  if (duration==32'h00000000) begin  // caso especial de duration=0
                      next_pulse <= next_pulse ^ pulsecounter[0];
                      state <= PULSE1;
                  end
                  else if (cduration >= adj_duration) begin
                      next_pulse <= ~next_pulse;
                      cduration <= 34'h000000000;
                      if (pulsecounter == 16'h0001) begin // se ha acabado el tren de pulsos
                          state <= PULSE1;
                      end
                      else begin
                          pulsecounter <= pulsecounter - 1;
                      end
                  end
                  else begin
                      pulse <= next_pulse;
                      cduration <= cduration + 1;
                  end
              end
          DATA1:  // DATA1 a 4 para leer numero de bits en bloque
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  numberofbits[7:0] <= sramdin;
                  a <= a + 21'd1;
                  state <= DATA2;
              end
          DATA2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  numberofbits[15:8] <= sramdin;
                  a <= a + 21'd1;
                  state <= DATA3;
              end
          DATA3:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  numberofbits[23:16] <= sramdin;
                  a <= a + 21'd1;
                  state <= DATA4;
              end
          DATA4:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  {next_pulse,numberofbits[30:24]} <= sramdin;
                  a <= a + 21'd1;
                  state <= DATATAIL1;
              end
          DATATAIL1:  // DATATAIL1 y 2 leen la duración del pulso extra
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  durationextrapulse[7:0] <= sramdin;
                  a <= a + 21'd1;
                  state <= DATATAIL2;
              end
          DATATAIL2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  durationextrapulse[15:8] <= sramdin;
                  a <= a + 21'd1;
                  state <= READNPULSE0;
              end
          READNPULSE0: // Leer cantidad de pulsos para bit 0
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  numberpulse0 <= sramdin[4:0];
                  indexpulse <= 5'd0;
                  a <= a + 21'd1;
                  state <= READNPULSE1;
              end
          READNPULSE1:  // Leer cantidad de pulsos para bit 1
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  numberpulse1 <= sramdin[4:0];
                  a <= a + 21'd1;
                  state <= READDPULSE0_1;
              end
          READDPULSE0_1: // Leer secuencia de pulsos para 0
              if (play_enabled == 1'b1) begin
                  if (indexpulse == numberpulse0) begin
                      indexpulse <= 5'd0;
                      state <= READDPULSE1_1;
                  end
                  else begin
                      databyte <= sramdin;
                      a <= a + 21'd1;
                      state <= READDPULSE0_2;
                  end
              end
          READDPULSE0_2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  pulse0[indexpulse] <= {sramdin, databyte};
                  indexpulse <= indexpulse + 1;
                  a <= a + 21'd1;
                  state <= READDPULSE0_1;
              end
          READDPULSE1_1: // Leer secuencia de pulsos para 1
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  if (indexpulse == numberpulse1) begin
                      state <= READDATA1;
                  end
                  else begin
                      databyte <= sramdin;
                      a <= a + 21'd1;
                      state <= READDPULSE1_2;
                  end
              end
          READDPULSE1_2:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  pulse1[indexpulse] <= {sramdin,databyte};
                  indexpulse <= indexpulse + 1;
                  a <= a + 21'd1;
                  state <= READDPULSE1_1;
              end
          READDATA1:
              if (play_enabled == 1'b1 && sram_access_allowed == 1'b1) begin
                  databyte <= sramdin;
                  a <= a + 21'd1;
                  countbits <= 4'd8;
                  indexpulse <= 5'd0;
                  state <= OUTPUTBIT1;
              end
          OUTPUTBIT1:
              if (play_enabled == 1'b1) begin
                  if (numberofbits == 31'h0) begin
                      duration <= {15'h0000,durationextrapulse};
                      cduration <= 34'h0;
                      state <= DATADOTAIL;
                  end
                  else if (countbits == 0) begin
                      state <= READDATA1;
                  end
                  else if ((databyte[7] == 1'b0 && indexpulse >= numberpulse0) ||
                          (databyte[7] == 1'b1 && indexpulse >= numberpulse1)) begin
                      databyte <= {databyte[6:0],1'b0};
                      numberofbits <= numberofbits - 1;
                      countbits <= countbits - 1;
                      indexpulse <= 5'd0;
                  end
                  else begin
                      if (databyte[7] == 1'b0)
                          duration <= {15'h0000,pulse0[indexpulse]};
                      else
                          duration <= {15'h0000,pulse1[indexpulse]};
                      cduration <= 34'h0;
                      indexpulse <= indexpulse + 1;
                      state <= OUTPUTBIT2;
                  end
              end
          OUTPUTBIT2:
              if (play_enabled == 1'b1) begin
                  if (cduration >= adj_duration) begin
                      next_pulse <= ~next_pulse;
                      state <= OUTPUTBIT1;
                  end
                  else begin
                      pulse <= next_pulse;
                      cduration <= cduration + 1;
                  end
              end
          DATADOTAIL:
              if (play_enabled == 1'b1) begin
                  pulse <= next_pulse;
                  if (cduration >= adj_duration) begin
                      //??next_pulse <= ~next_pulse;
                      state <= READTAG;
                  end
                  else begin
                      cduration <= cduration + 1;
                  end
              end
          default:
              begin
                  state <= IDLE;
                  play_enabled <= 1'b0;
                  a <= 21'h000000;
              end
          endcase
      end
    end

    always @* begin
      if (play_enabled == 1'b0 || (state == DOPULSE && cduration >= adj_duration) || (state != DATADOTAIL && state != DOPULSE && state != OUTPUTBIT1 && state != OUTPUTBIT2))
        speed_change_allowed = 1'b1;
      else
        speed_change_allowed = 1'b0;
    end
endmodule
