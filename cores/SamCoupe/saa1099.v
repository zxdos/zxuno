`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Miguel Angel Rodriguez Jodar
// 
// Create Date:    17:20:11 08/09/2015 
// Design Name:    SAM Coupé clone
// Module Name:    saa1099
// Project Name:   SAM Coupé clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module saa1099 (
    input wire clk,  // 8 MHz
    input wire rst_n,
    input wire cs_n,
    input wire a0,  // 0=data, 1=address
    input wire wr_n,
    input wire [7:0] din,
    output wire [7:0] out_l,
    output wire [7:0] out_r
    );
    // DTACK is not implemented. Sorry about that
        
    reg [7:0] amplit0, amplit1, amplit2, amplit3, amplit4, amplit5;
    reg [8:0] freq0, freq1, freq2, freq3, freq4, freq5;
    reg [7:0] oct10, oct32, oct54;
    reg [7:0] freqenable;
    reg [7:0] noiseenable;
    reg [7:0] noisegen;
    reg [7:0] envelope0, envelope1;
    reg [7:0] ctrl;  // frequency reset and sound enable for all channels
    
    reg [4:0] addr;  // holds the address of the register to write to
    
    // Write values into internal registers
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            ctrl <= 8'h00;
        end
        else begin
            if (cs_n == 1'b0 && wr_n == 1'b0) begin
                if (a0 == 1'b1)
                    addr <= din[4:0];
                else begin
                    case (addr)
                        5'h00: amplit0 <= din;
                        5'h01: amplit1 <= din;
                        5'h02: amplit2 <= din;
                        5'h03: amplit3 <= din;
                        5'h04: amplit4 <= din;
                        5'h05: amplit5 <= din;
                        
                        5'h08: freq0   <= 9'd510 - {1'b0, din};
                        5'h09: freq1   <= 9'd510 - {1'b0, din};
                        5'h0A: freq2   <= 9'd510 - {1'b0, din};
                        5'h0B: freq3   <= 9'd510 - {1'b0, din};
                        5'h0C: freq4   <= 9'd510 - {1'b0, din};
                        5'h0D: freq5   <= 9'd510 - {1'b0, din};
                        
                        5'h10: oct10   <= din;
                        5'h11: oct32   <= din;
                        5'h12: oct54   <= din;
                        
                        5'h14: freqenable <= din;
                        5'h15: noiseenable <= din;
                        5'h16: noisegen <= din;
                        
                        5'h18: envelope0 <= din;
                        5'h19: envelope1 <= din;
                        
                        5'h1C: ctrl <= din;
                    endcase
                end
            end
        end
    end
                     
    wire gen0_tone;
    wire gen1_tone;
    wire gen2_tone;
    wire gen3_tone;
    wire gen4_tone;
    wire gen5_tone;
    
    wire pulse_to_noise0, pulse_to_envelope0;
    wire pulse_to_noise1, pulse_to_envelope1;
    
    wire noise0, noise1;
    
    wire [4:0] mixout0_l, mixout0_r;
    wire [4:0] mixout1_l, mixout1_r;
    wire [4:0] mixout2_l, mixout2_r;
    wire [4:0] mixout2_l_with_env, mixout2_r_with_env;
    wire [4:0] mixout3_l, mixout3_r;
    wire [4:0] mixout4_l, mixout4_r;
    wire [4:0] mixout5_l, mixout5_r;
    wire [4:0] mixout5_l_with_env, mixout5_r_with_env;
    
    // Frequency and noise generators, top half

    saa1099_tone_gen freq_gen0 (
        .clk(clk),
        .octave(oct10[2:0]),
        .freq(freq0),
        .out(gen0_tone),
        .pulseout(pulse_to_noise0)
    );

    saa1099_tone_gen freq_gen1 (
        .clk(clk),
        .octave(oct10[6:4]),
        .freq(freq1),
        .out(gen1_tone),
        .pulseout(pulse_to_envelope0)
    );

    saa1099_tone_gen freq_gen2 (
        .clk(clk),
        .octave(oct32[2:0]),
        .freq(freq2),
        .out(gen2_tone),
        .pulseout()
    );

    saa1099_noise_gen noise_gen0 (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_from_gen(pulse_to_noise0),
        .noise_freq(noisegen[1:0]),
        .out(noise0)
    );


    // Frequency and noise generators, bottom half

    saa1099_tone_gen freq_gen3 (
        .clk(clk),
        .octave(oct32[6:4]),
        .freq(freq3),
        .out(gen3_tone),
        .pulseout(pulse_to_noise1)
    );

    saa1099_tone_gen freq_gen4 (
        .clk(clk),
        .octave(oct54[2:0]),
        .freq(freq4),
        .out(gen4_tone),
        .pulseout(pulse_to_envelope1)
    );

    saa1099_tone_gen freq_gen5 (
        .clk(clk),
        .octave(oct54[6:4]),
        .freq(freq5),
        .out(gen5_tone),
        .pulseout()
    );

    saa1099_noise_gen noise_gen1 (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_from_gen(pulse_to_noise1),
        .noise_freq(noisegen[5:4]),
        .out(noise1)
    );


    // Mixers

    sa1099_mixer_and_amplitude mixer0 (
        .clk(clk),
        .en_tone(freqenable[0] == 1'b1 && noisegen[1:0] != 2'd3),  // if gen0 is being used to generate noise, don't use this channel for tone output
        .en_noise(noiseenable[0]),
        .tone(gen0_tone),
        .noise(noise0),
        .amplitude_l(amplit0[3:0]),
        .amplitude_r(amplit0[7:4]),
        .out_l(mixout0_l),
        .out_r(mixout0_r)
    );

    sa1099_mixer_and_amplitude mixer1 (
        .clk(clk),
        .en_tone(freqenable[1] == 1'b1 && envelope0[7] == 1'b0),
        .en_noise(noiseenable[1]),
        .tone(gen1_tone),
        .noise(noise0),
        .amplitude_l(amplit1[3:0]),
        .amplitude_r(amplit1[7:4]),
        .out_l(mixout1_l),
        .out_r(mixout1_r)
    );

    sa1099_mixer_and_amplitude mixer2 (
        .clk(clk),
        .en_tone(freqenable[2]),
        .en_noise(noiseenable[2]),
        .tone(gen2_tone),
        .noise(noise0),
        .amplitude_l(amplit2[3:0]),
        .amplitude_r(amplit2[7:4]),
        .out_l(mixout2_l),
        .out_r(mixout2_r)
    );

    sa1099_mixer_and_amplitude mixer3 (
        .clk(clk),
        .en_tone(freqenable[3] == 1'b1 && noisegen[5:4] != 2'd3),  // if gen3 is being used to generate noise, don't use this channel for tone output
        .en_noise(noiseenable[3]),
        .tone(gen3_tone),
        .noise(noise1),
        .amplitude_l(amplit3[3:0]),
        .amplitude_r(amplit3[7:4]),
        .out_l(mixout3_l),
        .out_r(mixout3_r)
    );

    sa1099_mixer_and_amplitude mixer4 (
        .clk(clk),
        .en_tone(freqenable[4] == 1'b1 && envelope1[7] == 1'b0),
        .en_noise(noiseenable[4]),
        .tone(gen4_tone),
        .noise(noise1),
        .amplitude_l(amplit4[3:0]),
        .amplitude_r(amplit4[7:4]),
        .out_l(mixout4_l),
        .out_r(mixout4_r)
    );

    sa1099_mixer_and_amplitude mixer5 (
        .clk(clk),
        .en_tone(freqenable[5]),
        .en_noise(noiseenable[5]),
        .tone(gen5_tone),
        .noise(noise1),
        .amplitude_l(amplit5[3:0]),
        .amplitude_r(amplit5[7:4]),
        .out_l(mixout5_l),
        .out_r(mixout5_r)
    );


    // Envelope generators

    saa1099_envelope_gen envelope_gen0 (
        .clk(clk),
        .rst_n(rst_n),
        .envreg(envelope0),
        .write_to_envreg_addr(cs_n == 1'b0 && wr_n == 1'b0 && a0 == 1'b1 && din[4:0] == 5'h18),
        .write_to_envreg_data(cs_n == 1'b0 && wr_n == 1'b0 && a0 == 1'b0 && addr == 5'h18),
        .pulse_from_tonegen(pulse_to_envelope0),
        .tone_en(freqenable[2]),
        .noise_en(noiseenable[2]),
        .sound_in_left(mixout2_l),
        .sound_in_right(mixout2_r),
        .sound_out_left(mixout2_l_with_env),
        .sound_out_right(mixout2_r_with_env)
    );
    
    saa1099_envelope_gen envelope_gen1 (
        .clk(clk),
        .rst_n(rst_n),
        .envreg(envelope1),
        .write_to_envreg_addr(cs_n == 1'b0 && wr_n == 1'b0 && a0 == 1'b1 && din[4:0] == 5'h19),
        .write_to_envreg_data(cs_n == 1'b0 && wr_n == 1'b0 && a0 == 1'b0 && addr == 5'h19),
        .pulse_from_tonegen(pulse_to_envelope1),
        .tone_en(freqenable[5]),
        .noise_en(noiseenable[5]),
        .sound_in_left(mixout5_l),
        .sound_in_right(mixout5_r),
        .sound_out_left(mixout5_l_with_env),
        .sound_out_right(mixout5_r_with_env)
    );    
    
    // Final mix

    saa1099_output_mixer outmix_left (
        .clk(clk),
        .sound_enable(ctrl[0]),
        .i0(mixout0_l),
        .i1(mixout1_l),
        .i2(mixout2_l_with_env),
        .i3(mixout3_l),
        .i4(mixout4_l),
        .i5(mixout5_l_with_env),
        .o(out_l)
    );

    saa1099_output_mixer outmix_right (
        .clk(clk),
        .sound_enable(ctrl[0]),
        .i0(mixout0_r),
        .i1(mixout1_r),
        .i2(mixout2_r_with_env),
        .i3(mixout3_r),
        .i4(mixout4_r),
        .i5(mixout5_r_with_env),
        .o(out_r)
    );
    

endmodule

module saa1099_tone_gen (
    input wire clk,
    input wire [2:0] octave,
    input wire [8:0] freq,
    output reg out,
    output reg pulseout
);
  
    reg [7:0] fcounter;
    always @* begin
        case (octave)
            3'd0: fcounter = 8'd255;
            3'd1: fcounter = 8'd127;
            3'd2: fcounter = 8'd63;
            3'd3: fcounter = 8'd31;
            3'd4: fcounter = 8'd15;
            3'd5: fcounter = 8'd7;
            3'd6: fcounter = 8'd3;
            3'd7: fcounter = 8'd1;
        endcase
    end
  
    reg [7:0] count = 8'd0;
    always @(posedge clk) begin
        if (count == fcounter)
            count <= 8'd0;
        else
        count <= count + 1;
    end
  
    reg pulse;
    always @* begin
        if (count == fcounter)
            pulse = 1'b1;
        else
            pulse = 1'b0;
    end
  
    initial out = 1'b0;    
    reg [8:0] cfinal = 9'd0;
    always @(posedge clk) begin
        if (pulse == 1'b1) begin
            if (cfinal == freq) begin
                cfinal <= 9'd0;
                out <= ~out;
            end
            else
                cfinal <= cfinal + 1;
        end
    end
    
    always @* begin
        if (pulse == 1'b1 && cfinal == freq)
            pulseout = 1'b1;
        else
            pulseout = 1'b0;
    end
endmodule

module saa1099_noise_gen (
    input wire clk,
    input wire rst_n,
    input wire pulse_from_gen,
    input wire [1:0] noise_freq,
    output wire out
    );
    
    reg [10:0] fcounter;
    always @* begin
        case (noise_freq)
            2'd0: fcounter = 11'd255;
            2'd1: fcounter = 11'd511;
            2'd2: fcounter = 11'd1023;
            default: fcounter = 11'd2047;  // actually not used
        endcase
    end
  
    reg [10:0] count = 11'd0;
    always @(posedge clk) begin
        if (count == fcounter)
            count <= 11'd0;
        else
        count <= count + 1;
    end
    
    reg [30:0] lfsr = 31'h11111111;
    always @(posedge clk) begin
        if (rst_n == 1'b0)
            lfsr <= 31'h11111111;  // just a seed
        if ((noise_freq == 2'd3 && pulse_from_gen == 1'b1) ||
            (noise_freq != 2'd3 && count == fcounter)) begin
                if ((lfsr[2] ^ lfsr[30]) == 1'b1)
                    lfsr <= {lfsr[29:0], 1'b1};
                else
                    lfsr <= {lfsr[29:0], 1'b0};
        end
    end
    
    assign out = lfsr[0];

endmodule

module sa1099_mixer_and_amplitude (
    input wire clk,
    input wire en_tone,
    input wire en_noise,
    input wire tone,
    input wire noise,
    input wire [3:0] amplitude_l,
    input wire [3:0] amplitude_r,
    output reg [4:0] out_l,
    output reg [4:0] out_r
    );

    reg [4:0] next_out_l, next_out_r;
    always @* begin
        next_out_l = 5'b0000;
        next_out_r = 5'b0000;
        if (en_tone == 1'b1)
            if (tone == 1'b1) begin
                next_out_l = next_out_l + {1'b0, amplitude_l};
                next_out_r = next_out_r + {1'b0, amplitude_r};
            end
        if (en_noise == 1'b1)
            if (noise == 1'b1) begin
                next_out_l = next_out_l + {1'b0, amplitude_l};
                next_out_r = next_out_r + {1'b0, amplitude_r};
            end
    end
    
    always @(posedge clk) begin
        out_l <= next_out_l;
        out_r <= next_out_r;
    end
endmodule

module saa1099_envelope_gen (
    input wire clk,
    input wire rst_n,
    input wire [7:0] envreg,
    input wire write_to_envreg_addr,
    input wire write_to_envreg_data,
    input wire pulse_from_tonegen,
    input wire tone_en,
    input wire noise_en,
    input wire [4:0] sound_in_left,
    input wire [4:0] sound_in_right,
    output wire [4:0] sound_out_left,
    output wire [4:0] sound_out_right
    );
    
    reg [3:0] envelopes[0:511];
    integer i;
    initial begin
        // Generating envelopes
        // 0 0 0 : ______________
        for (i=0;i<64;i=i+1)
            envelopes[{3'b000,i[5:0]}] = 4'd0;
            
        // 0 0 1 : --------------
        for (i=0;i<64;i=i+1)
            envelopes[{3'b001,i[5:0]}] = 4'd15;
            
        // 0 1 0 : \_____________
        for (i=0;i<16;i=i+1)
            envelopes[{3'b010,i[5:0]}] = ~i[3:0];
        for (i=16;i<64;i=i+1)
            envelopes[{3'b010,i[5:0]}] = 4'd0;
            
        // 0 1 1 : \|\|\|\|\|\|\|\
        for (i=0;i<64;i=i+1)
            envelopes[{3'b011,i[5:0]}] = ~i[3:0];
            
        // 1 0 0 : /\______________
        for (i=0;i<16;i=i+1)
            envelopes[{3'b100,i[5:0]}] = i[3:0];
        for (i=16;i<32;i=i+1)
            envelopes[{3'b100,i[5:0]}] = ~i[3:0];
        for (i=32;i<64;i=i+1)
            envelopes[{3'b100,i[5:0]}] = 4'd0;
            
        // 1 0 1 : /\/\/\/\/\/\/\/\
        for (i=0;i<16;i=i+1)
            envelopes[{3'b101,i[5:0]}] = i[3:0];
        for (i=16;i<32;i=i+1)
            envelopes[{3'b101,i[5:0]}] = ~i[3:0];
        for (i=32;i<48;i=i+1)
            envelopes[{3'b101,i[5:0]}] = i[3:0];
        for (i=48;i<64;i=i+1)
            envelopes[{3'b101,i[5:0]}] = ~i[3:0];
        
        // 1 1 0 : /|________________
        for (i=0;i<16;i=i+1)
            envelopes[{3'b110,i[5:0]}] = i[3:0];
        for (i=16;i<64;i=i+1)
            envelopes[{3'b110,i[5:0]}] = 4'd0;
        
        // 1 1 1 : /|/|/|/|/|/|/|/|/|
        for (i=0;i<64;i=i+1)
            envelopes[{3'b111,i[5:0]}] = i[3:0];
    end
    
    reg write_to_address_prev = 1'b0;
    wire write_to_address_edge = (~write_to_address_prev & write_to_envreg_addr);

    reg write_to_data_prev = 1'b0;
    wire write_to_data_edge = (~write_to_data_prev & write_to_envreg_data);

    reg [2:0] envshape = 3'b000;
    reg stereoshape = 1'b0;
    reg envclock = 1'b0;
    wire env_enable = envreg[7];
    wire env_resolution = envreg[4];
    
    reg pending_data = 1'b0;
    
    reg [5:0] envcounter = 6'd0;    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            envcounter <= 6'd0;
            stereoshape <= 1'b0;
            envshape <= 3'b000;
            envclock <= 1'b0;
            write_to_address_prev = 1'b0;
            write_to_data_prev = 1'b0;
            pending_data <= 1'b0;
        end
        else begin
            write_to_address_prev <= write_to_envreg_addr;
            write_to_data_prev <= write_to_envreg_data;
            if (write_to_data_edge == 1'b1)
                pending_data <= 1'b1;
            if (env_enable == 1'b1) begin
                if (envclock == 1'b0 && pulse_from_tonegen == 1'b1 || envclock == 1'b1 && write_to_address_edge == 1'b1) begin  // pulse from internal or external clock?
                    if (envcounter == 6'd63)
                        envcounter <= 6'd32;
                    else begin
                        if (env_resolution == 1'b0)
                            envcounter <= envcounter + 1;
                        else
                            envcounter <= envcounter + 2;
                    end
                    if (envcounter == 6'd0 ||
                        envcounter >= 6'd15 && (envshape == 3'b000 || envshape == 3'b010 || envshape == 3'b110) ||
                        envcounter[3:0] == 4'd15 && (envshape == 3'b001 || envshape == 3'b011 || envshape == 3'b111) ||
                        envcounter >= 6'd31 && envshape == 3'b100 ||
                        envcounter[4:0] == 5'd31 && envshape ==3'b101) begin  // find out when to updated buffered values
                        if (pending_data == 1'b1) begin  // if we reached one of the designated points (3) or (4) and there is pending data, load it
                            envshape <= envreg[3:1];
                            stereoshape <= envreg[0];
                            envclock <= envreg[5];
                            envcounter <= 6'd0;
                            pending_data <= 1'b0;
                        end
                    end
                end
            end
        end
    end
    
    reg [3:0] envleft = 4'b0000;
    wire [3:0] envright = (stereoshape == 1'b0)? envleft : ~envleft;  // bit 0 of envreg inverts envelope shape
    always @(posedge clk)
        envleft <= envelopes[{envshape,envcounter}];  // take current envelope from envelopes ROM
    
    wire [4:0] temp_out_left, temp_out_right;
    
    saa1099_amp_env_mixer modulate_left (
        .a(sound_in_left),
        .b(envleft),
        .o(temp_out_left)
        );

    saa1099_amp_env_mixer modulate_right (
        .a(sound_in_right),
        .b(envright),
        .o(temp_out_right)
        );
        
    assign sound_out_left = (env_enable == 1'b0)? sound_in_left :  // if envelopes are not enabled, just bypass them
                            (env_enable == 1'b1 && tone_en == 1'b0 && noise_en == 1'b0)? {envleft, envleft[3]} : // if tone and noise are off, output is envelope signal itself
                            temp_out_left;  // else it is original signal modulated by envelope
        
    assign sound_out_right = (env_enable == 1'b0)? sound_in_right : 
                             (env_enable == 1'b1 && tone_en == 1'b0 && noise_en == 1'b0)? {envright, envright[3]} :
                             temp_out_right;
endmodule

module saa1099_amp_env_mixer (
    input wire [4:0] a,  // amplitude
    input wire [3:0] b,  // envelope
    output wire [4:0] o  // output
    );
  
    wire [6:0] res1 = ((b[0] == 1'b1)? a : 5'h00)         + ((b[1] == 1'b1)? {a,1'b0} : 6'h00);  
    wire [8:0] res2 = ((b[2] == 1'b1)? {a,2'b00} : 7'h00) + ((b[3] == 1'b1)? {a,3'b000} : 8'h00);
    wire [8:0] res3 = res1 + res2;
    assign o = res3[8:4];
endmodule

module saa1099_output_mixer (
    input wire clk,
    input wire sound_enable,
    input wire [4:0] i0,
    input wire [4:0] i1,
    input wire [4:0] i2,
    input wire [4:0] i3,
    input wire [4:0] i4,
    input wire [4:0] i5,
    output reg [7:0] o
    );

    reg [7:0] compressor_table[0:255];
    initial begin
        $readmemh ("compressor_lut.hex", compressor_table);
    end
    
    reg [7:0] mix;
    always @* begin
        if (sound_enable == 1'b1)
            mix = i0 + i1 + i2 + i3 + i4 + i5;
        else
            mix = 8'd0;
    end
    
    always @(posedge clk) begin
        o <= compressor_table[mix];
    end
endmodule
    