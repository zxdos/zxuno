/*******************************************************************************
*     (c) Copyright 1995 - 2010 Xilinx, Inc. All rights reserved.              *
*                                                                              *
*     This file contains confidential and proprietary information              *
*     of Xilinx, Inc. and is protected under U.S. and                          *
*     international copyright and other intellectual property                  *
*     laws.                                                                    *
*                                                                              *
*     DISCLAIMER                                                               *
*     This disclaimer is not a license and does not grant any                  *
*     rights to the materials distributed herewith. Except as                  *
*     otherwise provided in a valid license issued to you by                   *
*     Xilinx, and to the maximum extent permitted by applicable                *
*     law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND                  *
*     WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES              *
*     AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING                *
*     BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-                   *
*     INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and                 *
*     (2) Xilinx shall not be liable (whether in contract or tort,             *
*     including negligence, or under any other theory of                       *
*     liability) for any loss or damage of any kind or nature                  *
*     related to, arising under or in connection with these                    *
*     materials, including for any direct, or any indirect,                    *
*     special, incidental, or consequential loss or damage                     *
*     (including loss of data, profits, goodwill, or any type of               *
*     loss or damage suffered as a result of any action brought                *
*     by a third party) even if such damage or loss was                        *
*     reasonably foreseeable or Xilinx had been advised of the                 *
*     possibility of the same.                                                 *
*                                                                              *
*     CRITICAL APPLICATIONS                                                    *
*     Xilinx products are not designed or intended to be fail-                 *
*     safe, or for use in any application requiring fail-safe                  *
*     performance, such as life-support or safety devices or                   *
*     systems, Class III medical devices, nuclear facilities,                  *
*     applications related to the deployment of airbags, or any                *
*     other applications that could lead to death, personal                    *
*     injury, or severe property or environmental damage                       *
*     (individually and collectively, "Critical                                *
*     Applications"). Customer assumes the sole risk and                       *
*     liability of any use of Xilinx products in Critical                      *
*     Applications, subject only to applicable laws and                        *
*     regulations governing limitations on product liability.                  *
*                                                                              *
*     THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS                 *
*     PART OF THIS FILE AT ALL TIMES.                                          *
*******************************************************************************/
// The synthesis directives "translate_off/translate_on" specified below are
// supported by Xilinx, Mentor Graphics and Synplicity synthesis
// tools. Ensure they are correct for your synthesis tool(s).

// You must compile the wrapper file rom8k.v when simulating
// the core, rom8k. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

`timescale 1ns/1ps

module rom8k(
	clka,
	ena,
	addra,
	douta);


input clka;
input ena;
input [12 : 0] addra;
output [7 : 0] douta;

// synthesis translate_off

      BLK_MEM_GEN_V4_3 #(
		.C_ADDRA_WIDTH(13),
		.C_ADDRB_WIDTH(13),
		.C_ALGORITHM(1),
		.C_BYTE_SIZE(9),
		.C_COMMON_CLK(0),
		.C_DEFAULT_DATA("0"),
		.C_DISABLE_WARN_BHV_COLL(0),
		.C_DISABLE_WARN_BHV_RANGE(0),
		.C_FAMILY("spartan6"),
		.C_HAS_ENA(1),
		.C_HAS_ENB(0),
		.C_HAS_INJECTERR(0),
		.C_HAS_MEM_OUTPUT_REGS_A(0),
		.C_HAS_MEM_OUTPUT_REGS_B(0),
		.C_HAS_MUX_OUTPUT_REGS_A(0),
		.C_HAS_MUX_OUTPUT_REGS_B(0),
		.C_HAS_REGCEA(0),
		.C_HAS_REGCEB(0),
		.C_HAS_RSTA(0),
		.C_HAS_RSTB(0),
		.C_HAS_SOFTECC_INPUT_REGS_A(0),
		.C_HAS_SOFTECC_OUTPUT_REGS_B(0),
		.C_INITA_VAL("0"),
		.C_INITB_VAL("0"),
		.C_INIT_FILE_NAME("rom8k.mif"),
		.C_LOAD_INIT_FILE(1),
		.C_MEM_TYPE(3),
		.C_MUX_PIPELINE_STAGES(0),
		.C_PRIM_TYPE(1),
		.C_READ_DEPTH_A(8192),
		.C_READ_DEPTH_B(8192),
		.C_READ_WIDTH_A(8),
		.C_READ_WIDTH_B(8),
		.C_RSTRAM_A(0),
		.C_RSTRAM_B(0),
		.C_RST_PRIORITY_A("CE"),
		.C_RST_PRIORITY_B("CE"),
		.C_RST_TYPE("SYNC"),
		.C_SIM_COLLISION_CHECK("ALL"),
		.C_USE_BYTE_WEA(0),
		.C_USE_BYTE_WEB(0),
		.C_USE_DEFAULT_DATA(0),
		.C_USE_ECC(0),
		.C_USE_SOFTECC(0),
		.C_WEA_WIDTH(1),
		.C_WEB_WIDTH(1),
		.C_WRITE_DEPTH_A(8192),
		.C_WRITE_DEPTH_B(8192),
		.C_WRITE_MODE_A("WRITE_FIRST"),
		.C_WRITE_MODE_B("WRITE_FIRST"),
		.C_WRITE_WIDTH_A(8),
		.C_WRITE_WIDTH_B(8),
		.C_XDEVICEFAMILY("spartan6"))
	inst (
		.CLKA(clka),
		.ENA(ena),
		.ADDRA(addra),
		.DOUTA(douta),
		.RSTA(),
		.REGCEA(),
		.WEA(),
		.DINA(),
		.CLKB(),
		.RSTB(),
		.ENB(),
		.REGCEB(),
		.WEB(),
		.ADDRB(),
		.DINB(),
		.DOUTB(),
		.INJECTSBITERR(),
		.INJECTDBITERR(),
		.SBITERR(),
		.DBITERR(),
		.RDADDRECC());


// synthesis translate_on

// XST black box declaration
// box_type "black_box"
// synthesis attribute box_type of rom8k is "black_box"

endmodule

