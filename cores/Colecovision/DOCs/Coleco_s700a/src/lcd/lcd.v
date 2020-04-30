module lcd (clk, lcd_rs, lcd_rw, lcd_e, lcd_0, lcd_1, lcd_2, lcd_3, lcd_4, lcd_5, lcd_6, lcd_7);
                    parameter       k = 18;

//  (* LOC="E12" *)    input           clk;        // synthesis attribute PERIOD clk "50 MHz"
//                    reg   [k+8-1:0] count=0;
//  (* LOC="W20" *)   output reg      NF_CEn;     // high for full LCD access
//                    reg             lcd_busy=1;
//                    reg             lcd_stb;
//                    reg       [5:0] lcd_code;
//                    reg       [6:0] lcd_stuff;
//  (* LOC="Y14" *)   output reg      lcd_rs;
//  (* LOC="W13" *)   output reg      lcd_rw;
//  (* LOC="Y15" *)   output reg      lcd_7;
//  (* LOC="AB16" *)   output reg      lcd_6;
//  (* LOC="Y16" *)   output reg      lcd_5;
//  (* LOC="AA12" *)   output reg      lcd_4;
   input           clk;        // synthesis attribute PERIOD clk "50 MHz"
                    reg   [k+8-1:0] count=0;
                    reg             lcd_busy=1;
                    reg             lcd_stb;
                    reg       [5:0] lcd_code;
                    reg       [6:0] lcd_stuff;
   output reg      lcd_rs;
   output reg      lcd_rw;
   output reg      lcd_7;
   output reg      lcd_6;
   output reg      lcd_5;
   output reg      lcd_4; 
     output reg      lcd_3;
     output reg      lcd_2;
     output reg      lcd_1;
     output reg      lcd_0;
   output reg      lcd_e;

  always @ (posedge clk) begin
    count  <= count + 1;

 lcd_0 <= 0;
 lcd_1 <= 0;
 lcd_2 <= 0;
 lcd_3 <= 0;
	
    case (count[k+7:k+2])
       0: lcd_code <= 6'h03;        // power-on initialization
       1: lcd_code <= 6'h03;
       2: lcd_code <= 6'h03;
       3: lcd_code <= 6'h02;
       4: lcd_code <= 6'h02;        // function set
       5: lcd_code <= 6'h08;
       6: lcd_code <= 6'h00;        // entry mode set
       7: lcd_code <= 6'h06;
       8: lcd_code <= 6'h00;        // display on/off control
       9: lcd_code <= 6'h0C;
      10: lcd_code <= 6'h00;        // display clear
      11: lcd_code <= 6'h01;
		12: lcd_code <= 6'h22;        // *
      13: lcd_code <= 6'h2A;
      14: lcd_code <= 6'h22;        // SPC
      15: lcd_code <= 6'h20;
      16: lcd_code <= 6'h24;        // C
      17: lcd_code <= 6'h23;
      18: lcd_code <= 6'h24;        // O
      19: lcd_code <= 6'h2F;
      20: lcd_code <= 6'h24;        // L
      21: lcd_code <= 6'h2C;
      22: lcd_code <= 6'h24;        // E
      23: lcd_code <= 6'h25;
      24: lcd_code <= 6'h24;        // C
      25: lcd_code <= 6'h23;
      26: lcd_code <= 6'h24;        // O
      27: lcd_code <= 6'h2F;
      28: lcd_code <= 6'h25;        // V
      29: lcd_code <= 6'h26;
      30: lcd_code <= 6'h24;        // I
      31: lcd_code <= 6'h29;
      32: lcd_code <= 6'h25;        // S
      33: lcd_code <= 6'h23;
      34: lcd_code <= 6'h24;        // I
      35: lcd_code <= 6'h29;
		36: lcd_code <= 6'h24;        // O
      37: lcd_code <= 6'h2F;
		38: lcd_code <= 6'h24;        // N
      39: lcd_code <= 6'h2E;
		40: lcd_code <= 6'h22;        // SPC
      41: lcd_code <= 6'h20;
		42: lcd_code <= 6'h22;        // *
      43: lcd_code <= 6'h2A;
      default: lcd_code <= 6'h10;
    endcase
  if (lcd_rw)                     // comment-out for repeating display
    lcd_busy <= 0;                // comment-out for repeating display
  
    lcd_stb <= ^count[k+1:k+0] & ~lcd_rw & lcd_busy;  // clkrate / 2^(k+2)
    lcd_stuff <= {lcd_stb,lcd_code};
    {lcd_e,lcd_rs,lcd_rw,lcd_7,lcd_6,lcd_5,lcd_4} <= lcd_stuff;
  end
endmodule