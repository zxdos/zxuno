module DAC (
    input        clk,
    input [11:0] countA,
    input [11:0] countB,
    output       rstn,
    output       cs_n,
    output       sclk,
    output       mosi);

    localparam CMD_A = 4'b0000; // Write to Input Register
    localparam CMD_B = 4'b0010; // Write to Input Register n, Update (Power Up) All

    localparam DAC_A = 4'b0000;
    localparam DAC_B = 4'b0001;

    reg [6:0] state;
    always @ (posedge clk) state <= state + 1'b1;

    reg [23:4] sr;
    always @ (posedge clk)
        if (cs_n)
            sr <= state[6] ? {CMD_B, DAC_B, countB}
                           : {CMD_A, DAC_A, countA};
        else
            if (sclk) sr <= {sr[22:4], 1'b0};

    assign cs_n = ~|state[5:4];
    assign sclk = state[0];
    assign mosi = sr[23];
    assign rstn = 1'b1;

endmodule
