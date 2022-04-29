`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 19:56:26 2015-10-17 by Miguel Angel Rodriguez Jodar
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

module uart (
    // CPU interface
    input wire clk,  // 28 MHz
    input wire [7:0] txdata,
    input wire txbegin,
    output wire txbusy,
    output wire [7:0] rxdata,
    output wire rxrecv,
    input wire data_read,
    // RS232 interface
    input wire rx,
    output wire tx,
    output wire rts
    );

    parameter CLK = 28000000;

    uart_tx #(.CLK(CLK)) transmitter (
        .clk(clk),
        .txdata(txdata),
        .txbegin(txbegin),
        .txbusy(txbusy),
        .tx(tx)
    );

    uart_rx #(.CLK(CLK)) receiver (
        .clk(clk),
        .rxdata(rxdata),
        .rxrecv(rxrecv),
        .data_read(data_read),
        .rx(rx),
        .rts(rts)
    );
endmodule

module uart_tx (
    // CPU interface
    input wire clk,  // 28 MHz
    input wire [7:0] txdata,
    input wire txbegin,
    output wire txbusy,
    // RS232 interface
    output reg tx
    );

    initial tx = 1'b1;

    parameter CLK = 28000000;
    parameter BPS = 115200;
    parameter PERIOD = CLK / BPS;

    parameter
        IDLE  = 2'd0,
        START = 2'd1,
        BIT   = 2'd2,
        STOP  = 2'd3;

    reg [7:0] txdata_reg;
    reg [1:0] state = IDLE;
    reg [15:0] bpscounter;
    reg [2:0] bitcnt;
    reg txbusy_ff = 1'b0;
    assign txbusy = txbusy_ff;

    always @(posedge clk) begin
        if (txbegin == 1'b1 && txbusy_ff == 1'b0 && state == IDLE) begin
            txdata_reg <= txdata;
            txbusy_ff <= 1'b1;
            state <= START;
            bpscounter <= PERIOD;
        end
        if (txbegin == 1'b0 && txbusy_ff == 1'b1) begin
            case (state)
                START:
                    begin
                        tx <= 1'b0;
                        bpscounter <= bpscounter - 16'd1;
                        if (bpscounter == 16'h0000) begin
                            bpscounter <= PERIOD;
                            bitcnt <= 3'd7;
                            state <= BIT;
                        end
                    end
                BIT:
                    begin
                        tx <= txdata_reg[0];
                        bpscounter <= bpscounter - 16'd1;
                        if (bpscounter == 16'h0000) begin
                            txdata_reg <= {1'b0, txdata_reg[7:1]};
                            bpscounter <= PERIOD;
                            bitcnt <= bitcnt - 3'd1;
                            if (bitcnt == 3'd0) begin
                                state <= STOP;
                            end
                        end
                    end
                STOP:
                    begin
                        tx <= 1'b1;
                        bpscounter <= bpscounter - 16'd1;
                        if (bpscounter == 16'h0000) begin
                            bpscounter <= PERIOD;
                            txbusy_ff <= 1'b0;
                            state <= IDLE;
                        end
                    end
                default:
                    begin
                        state <= IDLE;
                        txbusy_ff <= 1'b0;
                    end
            endcase
        end
    end
endmodule

module uart_rx (
    // CPU interface
    input wire clk,  // 28 MHz
    output reg [7:0] rxdata,
    output reg rxrecv,
    input wire data_read,
    // RS232 interface
    input wire rx,
    output reg rts
    );

    initial rxrecv = 1'b0;
    initial rts = 1'b0;

    parameter CLK = 28000000;
    parameter BPS = 115200;
    parameter PERIOD = CLK / BPS;
    parameter HALFPERIOD = PERIOD / 2;

    parameter
        IDLE  = 3'd0,
        START = 3'd1,
        BIT   = 3'd2,
        STOP  = 3'd3,
        WAIT  = 3'd4;

    // Sincronizacin de señales externas
    reg [1:0] rx_ff = 2'b00;
    always @(posedge clk) begin
        rx_ff <= {rx_ff[0], rx};
    end

    wire rx_is_1    = (rx_ff == 2'b11);
    wire rx_is_0    = (rx_ff == 2'b00);
    wire rx_negedge = (rx_ff == 2'b10);

    reg [15:0] bpscounter;
    reg [2:0] state = IDLE;
    reg [2:0] bitcnt;

    reg [7:0] rxshiftreg;

    always @(posedge clk) begin
        case (state)
            IDLE:
                begin
                    rts <= 1'b0;      // permitimos la recepción
                    rxrecv <= 1'b0;   // si estamos aqui, es porque no hay bytes pendientes de leer
                    if (rx_negedge) begin
                        bpscounter <= PERIOD - 2;  // porque ya hemos perdido 2 ciclos detectando el flanco negativo                        
                        state <= START;
                    end
                end
            START:
                begin
                    bpscounter <= bpscounter - 16'd1;
                    if (bpscounter == HALFPERIOD) begin   // sampleamos el bit a mitad de ciclo
                        if (!rx_is_0) begin  // si no era una señal de START de verdad
                            state <= IDLE;
                        end
                    end
                    else if (bpscounter == 16'h0000) begin
                        bpscounter <= PERIOD;
                        rxshiftreg <= 8'h00;    // aqui iremos guardando los bits recibidos
                        bitcnt <= 3'd7;
                        state <= BIT;
                    end
                end
            BIT:
                begin
                    bpscounter <= bpscounter - 16'd1;
                    if (bpscounter == HALFPERIOD) begin   // sampleamos el bit a mitad de ciclo
                        if (rx_is_1) begin
                            rxshiftreg <= {1'b1, rxshiftreg[7:1]};   // los bits entran por la izquierda, del LSb al MSb
                        end
                        else if (rx_is_0) begin
                            rxshiftreg <= {1'b0, rxshiftreg[7:1]};
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else if (bpscounter == 16'h0000) begin
                        bitcnt <= bitcnt - 3'd1;
                        bpscounter <= PERIOD;
//                        if (bitcnt == 3'd3)
//                            rts <= 1'b1;
                        if (bitcnt == 3'd0)
                            state <= STOP;
                    end
                end

//rts en stop: se come 1 de cada dos chars
//rts a mitad de stop o antes: en vez de ok recibo "-" pero hace eco bien
            STOP:
                begin
                    bpscounter <= bpscounter - 16'd1;
                    if (bpscounter == HALFPERIOD) begin
                        if (!rx_is_1) begin  // si no era una señal de STOP de verdad
                            state <= IDLE;
                        end
                        else begin
                            rxrecv <= 1'b1;
                            rts <= 1'b1;
                            rxdata <= rxshiftreg;
                            state <= WAIT;
                        end
                    end
                end
            WAIT:
                begin
                    if (data_read == 1'b1) begin
                        state <= IDLE;
                    end
                end
            default: state <= IDLE;
        endcase
    end
endmodule
