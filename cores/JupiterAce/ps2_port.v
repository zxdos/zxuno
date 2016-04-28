`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:16:31 12/26/2014 
// Design Name: 
// Module Name:    ps2_port 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ps2_port (
    input wire clk,  // se recomienda 1 MHz <= clk <= 600 MHz
    input wire enable_rcv,  // habilitar la maquina de estados de recepcion
    input wire ps2clk_ext,
    input wire ps2data_ext,
    output wire kb_interrupt,  // a 1 durante 1 clk para indicar nueva tecla recibida
    output reg [7:0] scancode, // make o breakcode de la tecla
    output wire released,  // soltada=1, pulsada=0
    output wire extended  // extendida=1, no extendida=0
    );
    
    `define RCVSTART    2'b00
    `define RCVDATA     2'b01 
    `define RCVPARITY   2'b10
    `define RCVSTOP     2'b11

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
    
    // Contador de time-out. Al llegar a 65536 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [15:0] timeoutcnt = 16'h0000;

    reg [1:0] state = `RCVSTART;
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
            timeoutcnt <= 16'h0000;
            if (state == `RCVSTART && ps2data == 1'b0) begin
                state <= `RCVDATA;
                key <= 8'h80;
            end
            else if (state == `RCVDATA) begin
                key <= {ps2data, key[7:1]};
                if (key[0] == 1'b1) begin
                    state <= `RCVPARITY;
                end
            end
            else if (state == `RCVPARITY) begin
                if (ps2data^paritycalculated == 1'b1) begin
                    state <= `RCVSTOP;
                end
                else begin
                    state <= `RCVSTART;
                end
            end
            else if (state == `RCVSTOP) begin
                state <= `RCVSTART;                
                if (ps2data == 1'b1) begin
                   scancode <= key;
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
        else begin
            timeoutcnt <= timeoutcnt + 1;
            if (timeoutcnt == 16'hFFFF) begin
                state <= `RCVSTART;
            end
        end
    end
endmodule
