`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 03:02:46 2017-02-13 by Miguel Angel Rodriguez Jodar
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

module dma (
  input wire clk,
  input wire rst_n,
  input wire [7:0] zxuno_addr,
  input wire regaddr_changed,
  input wire zxuno_regrd,
  input wire zxuno_regwr,
  input wire [7:0] din,
  output reg [7:0] dout,
  output reg oe,
  //---- DMA bus -----
  input wire m1_n,
  output reg busrq_n,
  input wire busak_n,
  output reg [15:0] dma_a,
  input wire [7:0] dma_din,
  output reg [7:0] dma_dout,
  output reg dma_mreq_n,
  output reg dma_iorq_n,
  output reg dma_rd_n,
  output reg dma_wr_n   
  );

`include "config.vh"

  localparam
    NODMA      = 3'd0,
    DOBURST    = 3'd1,
    DOTIMED    = 3'd2,
    DOTIMED_2  = 3'd3,
    DOTRANSFER = 3'd4,
    TRANSFER_2 = 3'd5,
    TRANSFER_3 = 3'd6;

  reg [2:0] iocnt = 3'b000;
  reg [1:0] mode = 2'b00;  // 00: apagado, 01: burst sin reinicio, 10: timed, sin reinicio, 11: timed, con reinicio    
  reg [1:0] srcdst = 2'b00; // 00: memoria a memoria, 01: memoria a I/O, 10: I/O a memoria, 11: I/O a I/O
  reg select_addr_to_reach = 1'b0;   // 0: el bit 7 de DMASTAT obedece a la direccion fuente, 1: obedece a la dirección destino
  reg [15:0] src = 16'h0000, dst = 16'h0000;
  reg [15:0] srcidx = 16'h0000, dstidx = 16'h0000;
  reg [15:0] preescaler = 16'h0000;
  reg [15:0] cntpreescaler = 16'h0000;
  reg [15:0] transferlength = 16'h0000;
  reg [15:0] cnttransfers = 16'h0000;
  reg [15:0] addrtoreach = 16'h0000;
  reg [2:0] state = NODMA;
  reg [2:0] returnstate = NODMA;
  reg [7:0] data;
  reg data_received = 1'b0;
  reg addr_is_reached = 1'b0;
  reg hilo = 1'b0;  // flipflop para determinar qué cacho de dato se va a dar en una lectura
  reg read_in_progress = 1'b0;
  initial busrq_n = 1'b1;
  initial dma_mreq_n = 1'b1;
  initial dma_iorq_n = 1'b1;
  initial dma_rd_n = 1'b1;
  initial dma_wr_n = 1'b1;

  // CPU reads DMA registers
  always @* begin
    oe = 1'b0;
    dout = 8'hFF;
    if (zxuno_addr == DMACTRL && zxuno_regrd == 1'b1) begin
      dout = {3'b000, select_addr_to_reach, srcdst, mode};
      oe = 1'b1;
    end
    else if (zxuno_addr == DMASTAT && zxuno_regrd == 1'b1) begin
      dout = {addr_is_reached,7'b0000000};
      oe = 1'b1;
    end
    else if (zxuno_addr == DMASRC && zxuno_regrd == 1'b1) begin
      dout = (hilo)? src[15:8]:src[7:0];
      oe = 1'b1;
    end
    else if (zxuno_addr == DMADST && zxuno_regrd == 1'b1) begin
      dout = (hilo)? dst[15:8]:dst[7:0];
      oe = 1'b1;
    end
    else if (zxuno_addr == DMAPRE && zxuno_regrd == 1'b1) begin
      dout = (hilo)? preescaler[15:8]:preescaler[7:0];
      oe = 1'b1;
    end
    else if (zxuno_addr == DMALEN && zxuno_regrd == 1'b1) begin
      dout = (hilo)? transferlength[15:8]:transferlength[7:0];
      oe = 1'b1;
    end    
    else if (zxuno_addr == DMAPROB && zxuno_regrd == 1'b1) begin
      dout = (hilo)? addrtoreach[15:8]:addrtoreach[7:0];
      oe = 1'b1;
    end
  end

  // CPU writes DMA registers
  always @(posedge clk) begin
    iocnt <= iocnt + 3'd1;  // free running 3-bit counter
    if (rst_n == 1'b0) begin
      data_received <= 1'b0;
      mode <= 2'b00;
      srcdst <= 2'b00;      
      select_addr_to_reach <= 1'b0;
      preescaler <= 16'h0000;
      transferlength <= 16'h0000;
      addrtoreach <= 16'h0000;
      src <= 16'h0000;
      dst <= 16'h0000;
      hilo <= 1'b0;
      read_in_progress <= 1'b0;
    end
    else begin
      if (regaddr_changed == 1'b1) begin
        hilo <= 1'b0;
        read_in_progress <= 1'b0;
      end
      else if (zxuno_regrd == 1'b1 && (zxuno_addr == DMASRC || zxuno_addr == DMADST || zxuno_addr == DMAPRE || zxuno_addr == DMALEN || zxuno_addr == DMAPROB || zxuno_addr == DMASTAT))
        read_in_progress <= 1'b1;
      else if (read_in_progress == 1'b1 && zxuno_regrd == 1'b0) begin
        hilo <= ~hilo;
        read_in_progress <= 1'b0;
        if (zxuno_addr == DMASTAT)
          addr_is_reached <= 1'b0;  // resetear direccion alcanzada después de haber sido leido
      end
      if (zxuno_addr == DMACTRL && zxuno_regwr == 1'b1)
        {select_addr_to_reach,srcdst,mode} <= din[4:0];
      else if (zxuno_regwr == 1'b1 && (zxuno_addr == DMASRC || zxuno_addr == DMADST || zxuno_addr == DMAPRE || zxuno_addr == DMALEN || zxuno_addr == DMAPROB)) begin
        data_received <= 1'b1;
        data <= din;
      end
      else if (data_received == 1'b1 && zxuno_regwr == 1'b0) begin  // just after the I/O write operation has finished, 16-bit registers are updated
        case (zxuno_addr)
          DMASRC : src <= {data, src[15:8]};
          DMADST : dst <= {data, dst[15:8]};
          DMAPRE : preescaler <= {data, preescaler[15:8]};
          DMALEN : transferlength <= {data, transferlength[15:8]};
          DMAPROB: addrtoreach <= {data, addrtoreach[15:8]};
        endcase
        data_received <= 1'b0;
      end
    end

    // DMA FSM
    if (rst_n == 1'b0) begin
      busrq_n <= 1'b1;
      dma_mreq_n <= 1'b1;
      dma_iorq_n <= 1'b1;
      dma_rd_n <= 1'b1;
      dma_wr_n <= 1'b1;
      cntpreescaler <= 16'h0000;
      cnttransfers <= 16'h0000;
      state <= NODMA;
    end
    else begin
      if (srcdst == 2'b00 || iocnt == 3'b000) begin  
        if (cntpreescaler == 16'h0000)
          cntpreescaler <= preescaler;
        else
          cntpreescaler <= cntpreescaler + 16'hFFFF ; // -1         
        case (state)
          NODMA:
          begin
            if (mode == 2'b01/* && m1_n == 1'b0*/) begin
              state <= DOBURST;
              srcidx <= src;
              dstidx <= dst;
              busrq_n <= 1'b0;
              cnttransfers <= transferlength;
            end
            else if (mode == 2'b10 || mode == 2'b11) begin
              state <= DOTIMED;
              srcidx <= src;
              dstidx <= dst;
              cntpreescaler <= preescaler;
              cnttransfers <= transferlength;
            end
            else
              busrq_n <= 1'b1;
          end
          
          DOBURST:
          begin
            if (busak_n == 1'b0) begin
              if (cnttransfers == 16'h0000) begin
                state <= NODMA;
                mode <= 2'b00; // clear transfer mode
                busrq_n <= 1'b1;
              end
              else begin
                state <= DOTRANSFER;
                dma_a <= srcidx;
                if (srcdst[1] == 1'b0)
                  dma_mreq_n <= 1'b0;
                else
                  dma_iorq_n <= 1'b0;
                dma_rd_n <= 1'b0;
                returnstate <= DOBURST;
              end
            end
          end
          
          DOTIMED:
          begin
            if (mode == 2'b00) begin
              state <= NODMA;
              busrq_n <= 1'b1;
            end
            else if (cntpreescaler == 16'h0000) begin
              busrq_n <= 1'b0;
              state <= DOTIMED_2;
            end
            else
              busrq_n <= 1'b1;
          end

          DOTIMED_2:
          begin
            if (busak_n == 1'b0) begin
              if (cnttransfers != 16'h0000) begin
                state <= DOTRANSFER;
                dma_a <= srcidx;
                if (srcdst[1] == 1'b0)
                  dma_mreq_n <= 1'b0;
                else
                  dma_iorq_n <= 1'b0;
                dma_rd_n <= 1'b0;
                returnstate <= DOTIMED;
              end
              else if (mode == 2'b11) begin
                cnttransfers <= transferlength;  // reiniciar timed con reinicio
                srcidx <= src;
                dstidx <= dst;
              end
              else begin
                mode <= 2'b00; // fin de timed sin reinicio
                busrq_n <= 1'b1;
                state <= NODMA;
              end
            end
          end
          
          //--- One transfer ---
          DOTRANSFER:
          begin
            dma_dout <= dma_din;
            dma_rd_n <= 1'b1;
            dma_mreq_n <= 1'b1;
            dma_iorq_n <= 1'b1;
            dma_a <= dstidx;
            state <= TRANSFER_2;
            if ((select_addr_to_reach == 1'b0 && srcidx == addrtoreach) || (select_addr_to_reach == 1'b1 && dstidx == addrtoreach))
              addr_is_reached <= 1'b1;
          end
          
          TRANSFER_2:
          begin
            if (srcdst[0] == 1'b0) begin
              dma_mreq_n <= 1'b0;
            end
            else begin
              dma_iorq_n <= 1'b0;
            end
            dma_wr_n <= 1'b0;
            state <= TRANSFER_3;
          end
          
          TRANSFER_3:
          begin
            dma_mreq_n <= 1'b1;
            dma_iorq_n <= 1'b1;
            dma_wr_n <= 1'b1;
            cnttransfers <= cnttransfers + 16'hFFFF; // -1
            if (srcdst[1] == 1'b0)
                srcidx <= srcidx + 16'd1;
            if (srcdst[0] == 1'b0)
                dstidx <= dstidx + 16'd1;
            state <= returnstate;
          end
          
          default:
            state <= NODMA;
        endcase
      end
    end
  end    
endmodule
