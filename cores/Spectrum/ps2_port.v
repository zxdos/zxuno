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
    wire ps2clkedge = (negedgedetect == 16'hFF00)? 1'b1 : 1'b0;
    
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
                //rkb_interrupt <= 1'b0;
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


module ps2_host_to_kb (
    input wire clk,          // se recomienda 1 MHz <= clk <= 600 MHz
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
    
    // Contador de time-out. Al llegar a 65536 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [15:0] timeoutcnt = 16'h0000;

    reg [2:0] state = `SENDFINISHED;
    reg [7:0] shiftreg = 8'h00;
    reg [2:0] cntbits = 3'd0;

    // Dato a enviar se guarda en rdata
    reg [7:0] rdata = 8'h00;

    // Paridad instantánea de los bits a enviar
    wire paritycalculated = ~(^rdata);

    always @(posedge clk) begin
        // Carga de rdata desde el exterior
        if (dataload) begin
            rdata <= data;
            busy <= 1'b1;
            error <= 1'b0;
            timeoutcnt <= 16'h0000;
            state <= `PULLCLKLOW;
        end

        if (state == `PULLCLKLOW && timeoutcnt >= 16'd40000) begin  // 40000 cuentas es poco más de 10ms
            state <= `PULLDATALOW;
            shiftreg <= rdata;
            cntbits <= 3'd0;
            timeoutcnt <= 16'h0000;
        end
        else if (state == `PULLDATALOW && ps2clknedge) begin
            state <= `SENDDATA;
            timeoutcnt <= 16'h0000;
        end
        else if (state == `SENDDATA && ps2clknedge) begin
            timeoutcnt <= 16'h0000;
            shiftreg <= {1'b0, shiftreg[7:1]};
            cntbits <= cntbits + 1;
            if (cntbits == 3'd7)
                state <= `SENDPARITY;
        end
        else if (state == `SENDPARITY && ps2clknedge) begin
            state <= `RCVIDLE;
            timeoutcnt <= 16'h0000;
        end
        else if (state == `RCVIDLE && ps2clknedge /*&& ps2data_in == 1'b1*/) begin
            state <= `RCVACK;
            timeoutcnt <= 16'h0000;
        end        
        else if (state == `RCVACK && ps2clknedge /*&& ps2data_in == 1'b0*/) begin
            state <= `SENDFINISHED;
            timeoutcnt <= 16'h0000;
        end
        else if (state == `SENDFINISHED) begin
            busy <= 1'b0;
            timeoutcnt <= 16'h0000;
        end
        else begin
            timeoutcnt <= timeoutcnt + 1;
            if (timeoutcnt == 16'hFFFF && state != `SENDFINISHED) begin
                error <= 1'b1;
                state <= `SENDFINISHED;
            end
        end
    end
    assign ps2data_ext = (state == `PULLCLKLOW || state == `PULLDATALOW)    ? 1'b0 :
                         (state == `SENDDATA && shiftreg[0] == 1'b0)        ? 1'b0 :
                         (state == `SENDPARITY && paritycalculated == 1'b0) ? 1'b0 : // si lo que se va a enviar es un 1
                                                                              1'bZ;  // no se manda, sino que se pone la línea a alta impedancia
    assign ps2clk_ext = (state == `PULLCLKLOW)                              ? 1'b0 :
                                                                              1'bZ;
endmodule
