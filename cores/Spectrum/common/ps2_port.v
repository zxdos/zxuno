`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 20:16:31 2014-12-26 by Miguel Angel Rodriguez Jodar
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

module ps2_port (
    input wire clk,  // se recomienda 1 MHz <= clk <= 600 MHz
    input wire enable_rcv,  // habilitar la maquina de estados de recepcion
    input wire kb_or_mouse,  // 0: kb, 1: mouse
    input wire ps2clk_ext,
    input wire ps2data_ext,
    output wire kb_interrupt,  // a 1 durante 1 clk para indicar nueva tecla recibida
    output reg [7:0] scancode, // make o breakcode de la tecla
    output wire released,  // soltada=1, pulsada=0
    output wire extended  // extendida=1, no extendida=0
    );
    
    localparam RCVSTART  = 2'b00,
               RCVDATA   = 2'b01,
               RCVPARITY = 2'b10,
               RCVSTOP   = 2'b11;

    reg [7:0] key = 8'h00;

    // Fase de sincronizacion de señales externas con el reloj del sistema
    reg [1:0] ps2clk_synchr;
    reg [1:0] ps2dat_synchr;
    wire ps2clk = ps2clk_synchr[1];
    wire ps2data = ps2dat_synchr[1];
    always @(posedge clk) begin
      ps2clk_synchr[0] <= ps2clk_ext;
      ps2clk_synchr[1] <= ps2clk_synchr[0];
      ps2dat_synchr[0] <= ps2data_ext;
      ps2dat_synchr[1] <= ps2dat_synchr[0];
    end

    // De-glitcher. Sólo detecto flanco de bajada
    reg [15:0] negedgedetect = 16'h0000;
    always @(posedge clk) begin
      negedgedetect <= {negedgedetect[14:0], ps2clk};
    end
    wire ps2clkedge = (negedgedetect == 16'hF000)? 1'b1 : 1'b0;
    
    // Paridad instantánea de los bits recibidos
    wire paritycalculated = ^key;
    
    // Contador de time-out. Al llegar a 16777216 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [23:0] timeoutcnt = 24'h000000;

    reg [1:0] state = RCVSTART;
    reg [1:0] regextended = 2'b00;
    reg [1:0] regreleased = 2'b00;
    reg rkb_interrupt = 1'b0;
    assign released = regreleased[1];
    assign extended = regextended[1];
    assign kb_interrupt = rkb_interrupt;
    
    always @(posedge clk) begin
        if (rkb_interrupt == 1'b1) begin
            rkb_interrupt <= 1'b0;
        end
        if (ps2clkedge && enable_rcv) begin
            timeoutcnt <= 24'h000000;
            case (state)
                RCVSTART: begin
                    if (ps2data == 1'b0) begin
                        state <= RCVDATA;
                        key <= 8'h80;
                    end
                end
                RCVDATA: begin
                    key <= {ps2data, key[7:1]};
                    if (key[0] == 1'b1) begin
                        state <= RCVPARITY;
                    end
                end
                RCVPARITY: begin
                    if (ps2data^paritycalculated == 1'b1) begin
                        state <= RCVSTOP;
                    end
                    else begin
                        state <= RCVSTART;
                    end
                end
                RCVSTOP: begin
                    state <= RCVSTART;                
                    if (ps2data == 1'b1) begin                        
                        scancode <= key;
                        if (kb_or_mouse == 1'b1) begin
                            rkb_interrupt <= 1'b1;  // no se requiere mirar E0 o F0
                        end
                        else begin
                            if (key == 8'hE0) begin
                                regextended <= 2'b01;
                            end
                            else if (key == 8'hF0) begin
                                regreleased <= 2'b01;
                            end
                            else begin
                                regextended <= {regextended[0], 1'b0};
                                regreleased <= {regreleased[0], 1'b0};
                                rkb_interrupt <= 1'b1;
                            end
                        end
                    end
                end    
                default: state <= RCVSTART;
            endcase
        end           
        else begin
            timeoutcnt <= timeoutcnt + 24'd1;
            if (timeoutcnt == 24'hFFFFFF) begin
                state <= RCVSTART;
            end
        end
    end
endmodule


module ps2_host_to_kb (
    input wire clk,          // calibrado para 28 MHz
    inout wire ps2clk_ext,
    inout wire ps2data_ext,
    input wire [7:0] data,
    input wire dataload,
    output wire ps2busy,
    output wire ps2error
    );
    
    `define PULLCLKLOW    3'b000
    `define PULLDATALOW   3'b001 
    `define SENDDATA      3'b010
    `define SENDPARITY    3'b011
    `define RCVACK        3'b100
    `define RCVIDLE       3'b101
    `define SENDFINISHED  3'b110

    reg initial_kb_reset = 1'b1;
    reg busy = 1'b0;
    reg error = 1'b0;
    assign ps2busy = busy;
    assign ps2error = error;

    // Fase de sincronizacion de señales externas con el reloj del sistema
    reg [1:0] ps2clk_synchr;
    reg [1:0] ps2dat_synchr;
    wire ps2clk = ps2clk_synchr[1];
    wire ps2data_in = ps2dat_synchr[1];
    always @(posedge clk) begin
      ps2clk_synchr[0] <= ps2clk_ext;
      ps2clk_synchr[1] <= ps2clk_synchr[0];
      ps2dat_synchr[0] <= ps2data_ext;
      ps2dat_synchr[1] <= ps2dat_synchr[0];
    end

    // De-glitcher. Sólo detecto flanco de bajada
    reg [15:0] edgedetect = 16'h0000;
    always @(posedge clk) begin
      edgedetect <= {edgedetect[14:0], ps2clk};
    end
    wire ps2clknedge = (edgedetect == 16'hF000)? 1'b1 : 1'b0;
    wire ps2clkpedge = (edgedetect == 16'h0FFF)? 1'b1 : 1'b0;
    
    // Contador de time-out. Al llegar a 16777216 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [23:0] timeoutcnt = 24'h000000;

    reg [2:0] state = `SENDFINISHED;
    reg [7:0] shiftreg = 8'h00;
    reg [2:0] cntbits = 3'd0;

    // Dato a enviar se guarda en rdata
    reg [7:0] rdata = 8'h00;

    // Paridad instantánea de los bits a enviar
    wire paritycalculated = ~(^rdata);

    always @(posedge clk) begin
        // Carga de rdata desde el exterior
	`ifdef INITIAL_KB_RESET
	if (initial_kb_reset) begin // Reset inicial de teclado para establecer el SET 2
		initial_kb_reset <= 1'b0;
		rdata <= 8'hFF;
            	busy <= 1'b1;
            	error <= 1'b0;
            	timeoutcnt <= 24'h000000;
            	state <= `PULLCLKLOW;				
	end
	`endif
        if (dataload) begin
            rdata <= data;
            busy <= 1'b1;
            error <= 1'b0;
            timeoutcnt <= 24'h000000;
            state <= `PULLCLKLOW;
        end

        if (!ps2clknedge) begin
            timeoutcnt <= timeoutcnt + 24'd1;
            if (timeoutcnt == 24'hFFFFFF && state != `SENDFINISHED) begin
                error <= 1'b1;
                state <= `SENDFINISHED;
            end
        end

        case (state)
            `PULLCLKLOW: begin  // 280000 cuentas son 10ms para 28 MHz
                if (timeoutcnt >= 24'd280000) begin
                    state <= `PULLDATALOW;
                    shiftreg <= rdata;
                    cntbits <= 3'd0;
                    timeoutcnt <= 24'h000000;
                end
            end
            `PULLDATALOW: begin
                if (ps2clknedge) begin
                    state <= `SENDDATA;
                    timeoutcnt <= 24'h000000;
                end
            end
            `SENDDATA: begin
                if (ps2clknedge) begin
                    timeoutcnt <= 24'h000000;
                    shiftreg <= {1'b0, shiftreg[7:1]};
                    cntbits <= cntbits + 1;
                    if (cntbits == 3'd7)
                        state <= `SENDPARITY;
                end
            end
            `SENDPARITY: begin
                if (ps2clknedge) begin
                    state <= `RCVIDLE;
                    timeoutcnt <= 24'h000000;
                end
            end
            `RCVIDLE: begin
                if (ps2clknedge) begin
                    state <= `RCVACK;
                    timeoutcnt <= 24'h000000;
                end
            end        
            `RCVACK: begin
                if (ps2clknedge) begin
                    state <= `SENDFINISHED;
                    timeoutcnt <= 24'h000000;
                end
            end
            `SENDFINISHED: begin
                busy <= 1'b0;
                timeoutcnt <= 24'h000000;
            end
            default: begin
                timeoutcnt <= timeoutcnt + 1;
                if (timeoutcnt == 24'hFFFFFF && state != `SENDFINISHED) begin
                    error <= 1'b1;
                    state <= `SENDFINISHED;
                end
            end
        endcase     
    end
    
    assign ps2data_ext = (state == `PULLCLKLOW || state == `PULLDATALOW)    ? 1'b0 :
                         (state == `SENDDATA && shiftreg[0] == 1'b0)        ? 1'b0 :
                         (state == `SENDPARITY && paritycalculated == 1'b0) ? 1'b0 : // si lo que se va a enviar es un 1
                                                                              1'bZ;  // no se manda, sino que se pone la línea a alta impedancia
    assign ps2clk_ext = (state == `PULLCLKLOW)                              ? 1'b0 :
                                                                              1'bZ;
endmodule
