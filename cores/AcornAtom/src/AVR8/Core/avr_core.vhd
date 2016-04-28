--************************************************************************************************
--  Top entity for AVR core
--  Version 1.82? (Special version for the JTAG OCD)
--  Designed by Ruslan Lepetenok 
--  Modified 31.08.2006
--  SLEEP and CLRWDT instructions support was added
--  BREAK instructions support was added 
--  PM clock enable was added
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

use Work.AVR_Core_CompPack.all;

entity AVR_Core is port(
                        --Clock and reset
	                    cp2         : in  std_logic;
						cp2en       : in  std_logic;
                        ireset      : in  std_logic;
					    -- JTAG OCD support
					    valid_instr : out std_logic;
						insert_nop  : in  std_logic; 
						block_irq   : in  std_logic;
						change_flow : out std_logic;
                        -- Program Memory
                        pc          : out std_logic_vector(15 downto 0);   
                        inst        : in  std_logic_vector(15 downto 0);
                        -- I/O control
                        adr         : out std_logic_vector(15 downto 0); 	
                        iore        : out std_logic;                       
                        iowe        : out std_logic;						
                        -- Data memory control
                        ramadr      : out std_logic_vector(15 downto 0);
                        ramre       : out std_logic;
                        ramwe       : out std_logic;
						cpuwait     : in  std_logic;
						-- Data paths
                        dbusin      : in  std_logic_vector(7 downto 0);
                        dbusout     : out std_logic_vector(7 downto 0);
                        -- Interrupt
                        irqlines    : in  std_logic_vector(22 downto 0);
                        irqack      : out std_logic;
                        irqackad    : out std_logic_vector(4 downto 0);
                        --Sleep Control
                        sleepi	    : out std_logic;
                        irqok	    : out std_logic;
                        globint	    : out std_logic;
                        --Watchdog
                        wdri	    : out std_logic
						);
end AVR_Core;


architecture Struct of avr_core is

signal dbusin_int  : std_logic_vector(7 downto 0);
signal dbusout_int : std_logic_vector(7 downto 0);

signal adr_int     : std_logic_vector(15 downto 0);      

signal iowe_int    : std_logic;
signal iore_int    : std_logic;

-- SIGNALS FOR INSTRUCTION AND STATES
signal idc_add  : std_logic;
signal idc_adc  : std_logic;
signal idc_adiw : std_logic;
signal idc_sub 	: std_logic;
signal idc_subi : std_logic;
signal idc_sbc 	: std_logic;
signal idc_sbci : std_logic;
signal idc_sbiw : std_logic;
signal adiw_st 	: std_logic;
signal sbiw_st 	: std_logic;
signal idc_and 	: std_logic;
signal idc_andi : std_logic;
signal idc_or 	: std_logic;
signal idc_ori 	: std_logic;
signal idc_eor 	: std_logic;
signal idc_com 	: std_logic;
signal idc_neg 	: std_logic;
signal idc_inc 	: std_logic;
signal idc_dec 	: std_logic;
signal idc_cp 	: std_logic;
signal idc_cpc 	: std_logic;
signal idc_cpi 	: std_logic;
signal idc_cpse : std_logic;
signal idc_lsr 	: std_logic;
signal idc_ror 	: std_logic;
signal idc_asr 	: std_logic;
signal idc_swap : std_logic;
signal sbi_st 	: std_logic;
signal cbi_st 	: std_logic;
signal idc_bst 	: std_logic;
signal idc_bset : std_logic;
signal idc_bclr : std_logic;
signal idc_sbic : std_logic;
signal idc_sbis : std_logic;
signal idc_sbrs : std_logic;
signal idc_sbrc : std_logic;
signal idc_brbs : std_logic;
signal idc_brbc : std_logic;
signal idc_reti : std_logic;

signal alu_data_r_in : std_logic_vector(7 downto 0);
signal alu_data_out  : std_logic_vector(7 downto 0);

signal reg_rd_in     : std_logic_vector(7 downto 0);
signal reg_rd_out    : std_logic_vector(7 downto 0);
signal reg_rr_out    : std_logic_vector(7 downto 0);

signal reg_rd_adr    : std_logic_vector(4 downto 0);
signal reg_rr_adr    : std_logic_vector(4 downto 0);

signal reg_h_out     : std_logic_vector(15 downto 0);
signal reg_z_out     : std_logic_vector(15 downto 0);

signal reg_h_adr     : std_logic_vector(2 downto 0);

signal reg_rd_wr     : std_logic;
signal post_inc      : std_logic;
signal pre_dec       : std_logic;
signal reg_h_wr      : std_logic;

signal sreg_fl_in    : std_logic_vector(7 downto 0);
signal sreg_out      : std_logic_vector(7 downto 0);
signal sreg_fl_wr_en : std_logic_vector(7 downto 0);
signal spl_out       : std_logic_vector(7 downto 0);
signal sph_out       : std_logic_vector(7 downto 0);
signal rampz_out     : std_logic_vector(7 downto 0);
	   
signal sp_ndown_up   : std_logic;
signal sp_en         : std_logic;

signal bit_num_r_io  : std_logic_vector(2 downto 0);
signal branch        : std_logic_vector(2 downto 0);

signal bitpr_io_out    : std_logic_vector(7 downto 0);
signal bit_pr_sreg_out : std_logic_vector(7 downto 0);
signal sreg_flags      : std_logic_vector(7 downto 0);
signal bld_op_out      : std_logic_vector(7 downto 0);
signal reg_file_rd_in  : std_logic_vector(7 downto 0);

signal bit_test_op_out : std_logic;

signal alu_c_flag_out  : std_logic;
signal alu_z_flag_out  : std_logic;
signal alu_n_flag_out  : std_logic;
signal alu_v_flag_out  : std_logic;
signal alu_s_flag_out  : std_logic;
signal alu_h_flag_out  : std_logic;
 
begin

pm_fetch_dec_Inst:component pm_fetch_dec port map(
                                      -- Clock and reset
                                      cp2      => cp2,
									  cp2en    => cp2en,
                                      ireset   => ireset,
									  -- JTAG OCD support
							          valid_instr => valid_instr,
						              insert_nop  => insert_nop,
						              block_irq   => block_irq,
						              change_flow => change_flow,
                                      -- Program memory
                                      pc       => pc,    
                                      inst     => inst,
                                      -- I/O control
                                      adr      => adr_int,
                                      iore     => iore_int,
                                      iowe     => iowe_int,
                                      -- Data memory control
                                      ramadr   => ramadr,
                                      ramre    => ramre,
                                      ramwe    => ramwe,
                                      cpuwait  => cpuwait,
                                      -- Data paths
                                      dbusin   => dbusin_int,
                                      dbusout  => dbusout_int,
                                      -- Interrupt
                                      irqlines => irqlines,
                                      irqack   => irqack,
                                      irqackad => irqackad,
                                      --Sleep 
                                      sleepi	 => sleepi,
                                      irqok	 => irqok,
                                      --Watchdog
                                      wdri	 => wdri,
									 -- ALU interface(Data inputs)
                                     alu_data_r_in   => alu_data_r_in,
									 -- ALU interface(Instruction inputs)
                                     idc_add_out  => idc_add,
                                     idc_adc_out  => idc_adc,
                                     idc_adiw_out => idc_adiw,
                                     idc_sub_out  => idc_sub,
                                     idc_subi_out => idc_subi,
                                     idc_sbc_out  => idc_sbc,
                                     idc_sbci_out => idc_sbci,
                                     idc_sbiw_out => idc_sbiw,

                                     adiw_st_out  => adiw_st,
                                     sbiw_st_out  => sbiw_st,

                                     idc_and_out  => idc_and,
                                     idc_andi_out => idc_andi,
                                     idc_or_out   => idc_or,
                                     idc_ori_out  => idc_ori,
                                     idc_eor_out  => idc_eor,
                                     idc_com_out  => idc_com,
                                     idc_neg_out  => idc_neg,

                                     idc_inc_out  => idc_inc,
                                     idc_dec_out  => idc_dec,

                                     idc_cp_out   => idc_cp,
                                     idc_cpc_out  => idc_cpc,
                                     idc_cpi_out  => idc_cpi,
                                     idc_cpse_out => idc_cpse,

                                     idc_lsr_out  => idc_lsr,
                                     idc_ror_out  => idc_ror,
                                     idc_asr_out  => idc_asr,
                                     idc_swap_out => idc_swap,
                                     -- ALU interface(Data output)
                                     alu_data_out => alu_data_out,
                                     -- ALU interface(Flag outputs)
                                     alu_c_flag_out => alu_c_flag_out,
                                     alu_z_flag_out => alu_z_flag_out,
                                     alu_n_flag_out => alu_n_flag_out,
                                     alu_v_flag_out => alu_v_flag_out,
                                     alu_s_flag_out => alu_s_flag_out,
                                     alu_h_flag_out => alu_h_flag_out,
                                     -- General purpose register file interface
                                     reg_rd_in   => reg_rd_in,
                                     reg_rd_out  => reg_rd_out,
                                     reg_rd_adr  => reg_rd_adr,
                                     reg_rr_out  => reg_rr_out,
                                     reg_rr_adr  => reg_rr_adr,
                                     reg_rd_wr   => reg_rd_wr,

                                     post_inc    => post_inc,
                                     pre_dec     => pre_dec,
                                     reg_h_wr    => reg_h_wr,
                                     reg_h_out   => reg_h_out,
                                     reg_h_adr   => reg_h_adr,
   		                             reg_z_out   => reg_z_out,
                                     -- I/O register file interface
                                     sreg_fl_in    => sreg_fl_in, --??   
                                     globint       => sreg_out(7), -- SREG I flag   

                                     sreg_fl_wr_en => sreg_fl_wr_en,

                                     spl_out       => spl_out,       
                                     sph_out       => sph_out,       
                                     sp_ndown_up   => sp_ndown_up,
                                     sp_en         => sp_en,
  
                                     rampz_out     => rampz_out,
                                     -- Bit processor interface
                                     bit_num_r_io    => bit_num_r_io,  
                                     bitpr_io_out    => bitpr_io_out, 
                                     branch          => branch, 
					                 bit_pr_sreg_out => bit_pr_sreg_out,
					                 bld_op_out      => bld_op_out, 
					                 bit_test_op_out => bit_test_op_out,

                                     sbi_st_out   => sbi_st,
                                     cbi_st_out   => cbi_st,

                                     idc_bst_out  => idc_bst,
                                     idc_bset_out => idc_bset,
                                     idc_bclr_out => idc_bclr,

                                     idc_sbic_out => idc_sbic,
                                     idc_sbis_out => idc_sbis,
              
                                     idc_sbrs_out => idc_sbrs,
                                     idc_sbrc_out => idc_sbrc,
              
                                     idc_brbs_out => idc_brbs,
                                     idc_brbc_out => idc_brbc,

                                     idc_reti_out => idc_reti);


GPRF_Inst:component reg_file port map (
		  	                           --Clock and reset
					                   cp2         => cp2,
									   cp2en       => cp2en,
                                       ireset      => ireset,
		  
                                       reg_rd_in   => reg_rd_in,
                                       reg_rd_out  => reg_rd_out,
                                       reg_rd_adr  => reg_rd_adr,
                                       reg_rr_out  => reg_rr_out,
                                       reg_rr_adr  => reg_rr_adr,
                                       reg_rd_wr   => reg_rd_wr,

                                       post_inc    => post_inc,
                                       pre_dec     => pre_dec,
                                       reg_h_wr    => reg_h_wr,
                                       reg_h_out   => reg_h_out,
                                       reg_h_adr   => reg_h_adr,
   		                               reg_z_out   => reg_z_out);


BP_Inst:component bit_processor port map(
		  	                             --Clock and reset
					                     cp2         => cp2,
										 cp2en    => cp2en,
                                         ireset      => ireset, 

                                         bit_num_r_io  => bit_num_r_io,  
                                         dbusin        => dbusin_int,   
                                         bitpr_io_out  => bitpr_io_out,   

                                         sreg_out      => sreg_out,   
                                         branch   => branch,  

                                         bit_pr_sreg_out => bit_pr_sreg_out,

                                         bld_op_out      => bld_op_out,
                                         reg_rd_out      => reg_rd_out,

                                         bit_test_op_out => bit_test_op_out,

                                         -- Instructions and states
                                         sbi_st   => sbi_st,       
                                         cbi_st   => cbi_st,       

                                         idc_bst  => idc_bst,       
                                         idc_bset => idc_bset,       
                                         idc_bclr => idc_bclr,       

                                         idc_sbic => idc_sbic,       
                                         idc_sbis => idc_sbis,       
              
                                         idc_sbrs => idc_sbrs,        
                                         idc_sbrc => idc_sbrc,        
              
                                         idc_brbs => idc_brbs,        
                                         idc_brbc => idc_brbc,        

                                         idc_reti => idc_reti);                      


io_dec_Inst:component io_adr_dec port map (
          adr          => adr_int,
          iore         => iore_int,
          dbusin_int   => dbusin_int,			-- LOCAL DATA BUS OUTPUT
          dbusin_ext   => dbusin,               -- EXTERNAL DATA BUS INPUT
                   
          spl_out      => spl_out,
          sph_out      => sph_out,
          sreg_out     => sreg_out,
          rampz_out    => rampz_out
);

IORegs_Inst: component io_reg_file port map(
	          		                        --Clock and reset
	                                        cp2        => cp2,
											cp2en    => cp2en,
                                            ireset     => ireset,     
	                                        
											adr        => adr_int,       
                                            iowe       => iowe_int,
                                            dbusout    => dbusout_int,     

                                            sreg_fl_in => sreg_fl_in,
                                            sreg_out   => sreg_out,

                                            sreg_fl_wr_en => sreg_fl_wr_en,

                                            spl_out    => spl_out,    
                                            sph_out    => sph_out,    
                                            sp_ndown_up => sp_ndown_up, 
                                            sp_en      => sp_en,   
  
                                            rampz_out  => rampz_out);



ALU_Inst:component alu_avr port map(
			  -- Data inputs
              alu_data_r_in => alu_data_r_in,
              alu_data_d_in => reg_rd_out,
              
              alu_c_flag_in => sreg_out(0),
              alu_z_flag_in => sreg_out(1),
              -- Instructions and states
              idc_add  => idc_add,
              idc_adc  => idc_adc,      
              idc_adiw => idc_adiw,     
              idc_sub  => idc_sub,     
              idc_subi => idc_subi,     
              idc_sbc  => idc_sbc,     
              idc_sbci => idc_sbci,     
              idc_sbiw => idc_sbiw,     

              adiw_st  => adiw_st,     
              sbiw_st  => sbiw_st,     

              idc_and  => idc_and,     
              idc_andi => idc_andi,     
              idc_or   => idc_or,     
              idc_ori  => idc_ori,     
              idc_eor  => idc_eor,     
              idc_com  => idc_com,     
              idc_neg  => idc_neg,     

              idc_inc  => idc_inc,     
              idc_dec  => idc_dec,     

              idc_cp   => idc_cp,     
              idc_cpc  => idc_cpc,     
              idc_cpi  => idc_cpi,    
              idc_cpse => idc_cpse,     

              idc_lsr  => idc_lsr,     
              idc_ror  => idc_ror,      
              idc_asr  => idc_asr,      
              idc_swap => idc_swap,      
              -- Data outputs
              alu_data_out => alu_data_out,  
			  -- Flag outputs
              alu_c_flag_out => alu_c_flag_out,
              alu_z_flag_out => alu_z_flag_out,
              alu_n_flag_out => alu_n_flag_out,
              alu_v_flag_out => alu_v_flag_out,
              alu_s_flag_out => alu_s_flag_out,
              alu_h_flag_out => alu_h_flag_out);


-- Outputs
adr      <= adr_int;     
iowe     <= iowe_int;
iore     <= iore_int;
dbusout  <= dbusout_int;

-- Sleep support
globint	<= sreg_out(7); -- I flag

end Struct;
