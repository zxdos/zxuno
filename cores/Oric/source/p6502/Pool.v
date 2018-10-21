module Pool (
    input CLK_50MHZ,

    // Analog-to-Digital Converter (ADC)
    output AD_CONV,

    // Programmable Gain Amplifier (AMP)
    output AMP_CS,

    // Pushbuttons (BTN)
    input BTN_SOUTH,

    // Digital-to-Analog Converter (DAC)
    output DAC_CLR,
    output DAC_CS,

    // FPGA Configuration Mode, INIT_B Pins (FPGA)
    output FPGA_INIT_B, // platformflash_oe

    // LEDs
    output [7:0] LED,
/*
    // Rotary Pushbutton Switch (ROT)
    input ROT_A,
    input ROT_B,
*/
    // Intel StrataFlash Parallel NOR Flash (SF)
    output SF_CE0, // strataflash_ce
    output SF_OE,  // strataflash_oe
    output SF_WE,  // strataflash_we

    // STMicro SPI serial Flash (SPI)
    // some connections shared with SPI Flash, DAC, ADC, and AMP
//  input  SPI_MISO,
    output SPI_MOSI,
    output SPI_SCK,
    output SPI_SS_B, // spi_rom_cs

    // Slide Switches (SW)
    input [3:0] SW
);
    // Disable SPI devices to prevent conflict as per UG Table 9-2
    assign SPI_SS_B = 1'b1;
    assign AMP_CS = 1'b1;
    assign AD_CONV = 1'b0;
    assign SF_CE0 = 1'b1;
    assign SF_OE = 1'b1;
    assign SF_WE = 1'b1;
    assign FPGA_INIT_B = 1'b0; // platformflash_oe

    // Tie-off LEDs
    assign LED = 8'b0;

    //////////////////////////////////////////////////////////////////////////
    // FPGA clocks

    wire dcm_locked, clk, clk0, clkfx, clk_dac;

    DCM #(
        .CLKIN_PERIOD(20.0),
        .CLKFX_DIVIDE(5),
        .CLKFX_MULTIPLY(16),
        .CLK_FEEDBACK("1X")
    ) dcm_inst (
        .CLKFB(clk_dac),
        .CLK0(clk0),
        .CLKIN(CLK_50MHZ),
        .DSSEN(1'b0),
        .PSCLK(1'b0),
        .PSEN(1'b0),
        .PSINCDEC(1'b0),
        .RST(BTN_SOUTH),
        .LOCKED(dcm_locked),
        .CLKFX(clkfx));

    BUFG bg_clkfx (.I(clkfx), .O(clk));
    BUFG bg_clk0  (.I(clk0),  .O(clk_dac));

    //////////////////////////////////////////////////////////////////////////
    // PET I/O locations

    localparam PET_PIA2_PORTB    = 16'd59426;   // GPIB data bus
    localparam PET_VIA_TIMER1_LO = 16'd59460;   // Read to clear IRQ
    localparam PET_VIA_PORTA     = 16'd59471;   // User port

    //////////////////////////////////////////////////////////////////////////
    // 6502

    wire        rw, res, irq, phi0;
    wire [15:0] ab;
    wire  [7:0] dbo;
    reg   [7:0] dbi;

    chip_6502 chip_6502 (
        .clk    (clk),
        .phi    (phi0),
        .res    (res),
        .so     (1'b0),
        .rdy    (1'b1),
        .nmi    (1'b1),
        .irq    (irq),
        .rw     (rw),
        .dbi    (dbi),
        .dbo    (dbo),
        .sync   (),
        .ab     (ab));

    //////////////////////////////////////////////////////////////////////////
    // 6502 reset

    reg [7:0] start;
    initial start = 0;
    always @ (posedge clk or negedge dcm_locked)
        if (~dcm_locked) start <= 0;
        else if (~start[7]) start <= start + 1;
    assign res = start[7];

    //////////////////////////////////////////////////////////////////////////
    // 6502 phi0 clock

    reg [3:0] div;
    initial div = 0;
    always @ (posedge clk) div <= div + 1;
    assign phi0 = div[3];

    wire clk_phi;
    BUFG bg_phi (.I(phi0), .O(clk_phi));

    //////////////////////////////////////////////////////////////////////////
    // RAM and ROM

    reg [7:0] ram[0:8191];

`ifdef XILINX_ISIM
    initial begin
        $readmemh("src/ram.hex", ram,       0, 8191);
        $readmemh("src/rom.hex", ram, 8192-64, 8191);
    end
`else
    initial begin
        $readmemh("ram.hex", ram,       0, 8191);
        $readmemh("rom.hex", ram, 8192-64, 8191);
    end
`endif

    always @ (posedge clk_phi) begin
        dbi <= ram[ab[12:0]];
        if (res && ~rw && ~ab[15]) ram[ab[12:0]] <= dbo;
    end

    //////////////////////////////////////////////////////////////////////////
    // 6522 VIA timer

    reg [15:0] timer;
    reg        timer_event, timer_irq;

    always @ (posedge clk_phi) if (~res)
        {timer, timer_event, timer_irq} <= 0;
    else begin
        {timer_event, timer} <= {1'b0, timer} + 1;
        if (ab==PET_VIA_TIMER1_LO) timer_irq <= 0;
        else if (timer_event) timer_irq <= 1;
    end

    assign irq = ~timer_irq;

    //////////////////////////////////////////////////////////////////////////
    // DAC outputs

    reg [7:0] countA, countB;

    always @ (posedge clk_phi)
        if (~rw)
            case (ab)
                PET_PIA2_PORTB: countA <= dbo;
                PET_VIA_PORTA: countB  <= dbo;
            endcase

    DAC dac_0 (
        .clk(clk_dac),
        .countA({countA,4'b0}),
        .countB({countB,4'b0}),
        .rstn(DAC_CLR),
        .cs_n(DAC_CS),
        .sclk(SPI_SCK),
        .mosi(SPI_MOSI));

endmodule
