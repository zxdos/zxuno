--************************************************************************************************
-- Component declarations for AVR core
-- Version 1.52? (Special version for fhe JTAG OCD)
-- Designed by Ruslan Lepetenok 
-- Modified 31.06.2006
-- PM clock enable was added
--************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;

package AVR_Core_CompPack is
	
component pm_fetch_dec is port(
                              -- Clock and reset
                              cp2              : in  std_logic;
							  cp2en            : in  std_logic; 
                              ireset           : in  std_logic;
							  -- JTAG OCD support
					          valid_instr      : out  std_logic;
						      insert_nop       : in std_logic; 
						      block_irq        : in std_logic;
						      change_flow      : out  std_logic;
                              -- Program memory
                              pc               : out std_logic_vector (15 downto 0);   
                              inst             : in  std_logic_vector (15 downto 0);
                              -- I/O control
                              adr              : out std_logic_vector (15 downto 0); 	
                              iore             : out std_logic;                       
                              iowe             : out std_logic;						
                              -- Data memory control
                              ramadr           : out std_logic_vector (15 downto 0);
                              ramre            : out std_logic;
                              ramwe            : out std_logic;
                              cpuwait          : in  std_logic;
							  -- Data paths
                              dbusin           : in  std_logic_vector (7 downto 0);
                              dbusout          : out std_logic_vector (7 downto 0);
                              -- Interrupt
                              irqlines         : in  std_logic_vector (22 downto 0);
                              irqack           : out std_logic;
                              irqackad         : out std_logic_vector(4 downto 0);
						      --Sleep 
                              sleepi	       : out std_logic;
                              irqok	           : out std_logic;
                              --Watchdog
                              wdri	           : out std_logic;
							  -- ALU interface(Data inputs)
                              alu_data_r_in    : out std_logic_vector(7 downto 0);
							  -- ALU interface(Instruction inputs)
							  idc_add_out      : out std_logic;
                              idc_adc_out      : out std_logic;
                              idc_adiw_out     : out std_logic;
                              idc_sub_out      : out std_logic;
                              idc_subi_out     : out std_logic;
                              idc_sbc_out      : out std_logic;
                              idc_sbci_out     : out std_logic;
                              idc_sbiw_out     : out std_logic;

                              adiw_st_out      : out std_logic;
                              sbiw_st_out      : out std_logic;

                              idc_and_out      : out std_logic;
                              idc_andi_out     : out std_logic;
                              idc_or_out       : out std_logic;
                              idc_ori_out      : out std_logic;
                              idc_eor_out      : out std_logic;              
                              idc_com_out      : out std_logic;              
                              idc_neg_out      : out std_logic;

                              idc_inc_out      : out std_logic;
                              idc_dec_out      : out std_logic;

                              idc_cp_out       : out std_logic;              
                              idc_cpc_out      : out std_logic;
                              idc_cpi_out      : out std_logic;
                              idc_cpse_out     : out std_logic;                            

                              idc_lsr_out      : out std_logic;
                              idc_ror_out      : out std_logic;
                              idc_asr_out      : out std_logic;
                              idc_swap_out     : out std_logic;

                               -- ALU interface(Data output)
                               alu_data_out    : in std_logic_vector(7 downto 0);

                               -- ALU interface(Flag outputs)
                               alu_c_flag_out  : in std_logic;
                               alu_z_flag_out  : in std_logic;
                               alu_n_flag_out  : in std_logic;
                               alu_v_flag_out  : in std_logic;
                               alu_s_flag_out  : in std_logic;
                               alu_h_flag_out  : in std_logic;

							   -- General purpose register file interface
                               reg_rd_in       : out std_logic_vector  (7 downto 0);
                               reg_rd_out      : in  std_logic_vector  (7 downto 0);
                               reg_rd_adr      : out std_logic_vector  (4 downto 0);
                               reg_rr_out      : in  std_logic_vector  (7 downto 0);
                               reg_rr_adr      : out std_logic_vector  (4 downto 0);
                               reg_rd_wr       : out std_logic;

                               post_inc        : out std_logic;                       -- POST INCREMENT FOR LD/ST INSTRUCTIONS
                               pre_dec         : out std_logic;                        -- PRE DECREMENT FOR LD/ST INSTRUCTIONS
                               reg_h_wr        : out std_logic;
                               reg_h_out       : in  std_logic_vector (15 downto 0);
                               reg_h_adr       : out std_logic_vector (2 downto 0);    -- x,y,z
   		                       reg_z_out       : in  std_logic_vector (15 downto 0);  -- OUTPUT OF R31:R30 FOR LPM/ELPM/IJMP INSTRUCTIONS
							   
                               -- I/O register file interface
                               sreg_fl_in      : out std_logic_vector(7 downto 0); 
                               globint         : in  std_logic; -- SREG I flag

                               sreg_fl_wr_en   : out std_logic_vector(7 downto 0);   --FLAGS WRITE ENABLE SIGNALS       

                               spl_out         : in  std_logic_vector(7 downto 0);         
                               sph_out         : in  std_logic_vector(7 downto 0);         
                               sp_ndown_up     : out std_logic; -- DIRECTION OF CHANGING OF STACK POINTER SPH:SPL 0->UP(+) 1->DOWN(-)
                               sp_en           : out std_logic; -- WRITE ENABLE(COUNT ENABLE) FOR SPH AND SPL REGISTERS
  
                               rampz_out       : in  std_logic_vector(7 downto 0);
							   
							   -- Bit processor interface
                               bit_num_r_io    : out std_logic_vector(2 downto 0); -- BIT NUMBER FOR CBI/SBI/BLD/BST/SBRS/SBRC/SBIC/SBIS INSTRUCTIONS
                               bitpr_io_out    : in  std_logic_vector(7 downto 0); -- SBI/CBI OUT        
                               branch          : out std_logic_vector(2 downto 0); -- NUMBER (0..7) OF BRANCH CONDITION FOR BRBS/BRBC INSTRUCTION
                               bit_pr_sreg_out : in  std_logic_vector(7 downto 0); -- BCLR/BSET/BST(T-FLAG ONLY)             
                               bld_op_out      : in  std_logic_vector(7 downto 0); -- BLD OUT (T FLAG)
                               bit_test_op_out : in  std_logic;                    -- OUTPUT OF SBIC/SBIS/SBRS/SBRC

                               sbi_st_out      : out std_logic;
                               cbi_st_out      : out std_logic;

                               idc_bst_out     : out std_logic;
                               idc_bset_out    : out std_logic;
                               idc_bclr_out    : out std_logic;

                               idc_sbic_out    : out std_logic;
                               idc_sbis_out    : out std_logic;
              
                               idc_sbrs_out    : out std_logic;
                               idc_sbrc_out    : out std_logic;
              
                               idc_brbs_out    : out std_logic;
                               idc_brbc_out    : out std_logic;

                               idc_reti_out    : out std_logic);

end component;


component alu_avr is port(

              alu_data_r_in   : in std_logic_vector(7 downto 0);
              alu_data_d_in   : in std_logic_vector(7 downto 0);
              
              alu_c_flag_in   : in std_logic;
              alu_z_flag_in   : in std_logic;


-- OPERATION SIGNALS INPUTS
              idc_add         :in std_logic;
              idc_adc         :in std_logic;
              idc_adiw        :in std_logic;
              idc_sub         :in std_logic;
              idc_subi        :in std_logic;
              idc_sbc         :in std_logic;
              idc_sbci        :in std_logic;
              idc_sbiw        :in std_logic;

              adiw_st         : in std_logic;
              sbiw_st         : in std_logic;

              idc_and         :in std_logic;
              idc_andi        :in std_logic;
              idc_or          :in std_logic;
              idc_ori         :in std_logic;
              idc_eor         :in std_logic;              
              idc_com         :in std_logic;              
              idc_neg         :in std_logic;

              idc_inc         :in std_logic;
              idc_dec         :in std_logic;

              idc_cp          :in std_logic;              
              idc_cpc         :in std_logic;
              idc_cpi         :in std_logic;
              idc_cpse        :in std_logic;                            

              idc_lsr         :in std_logic;
              idc_ror         :in std_logic;
              idc_asr         :in std_logic;
              idc_swap        :in std_logic;


-- DATA OUTPUT
              alu_data_out    : out std_logic_vector(7 downto 0);

-- FLAGS OUTPUT
              alu_c_flag_out  : out std_logic;
              alu_z_flag_out  : out std_logic;
              alu_n_flag_out  : out std_logic;
              alu_v_flag_out  : out std_logic;
              alu_s_flag_out  : out std_logic;
              alu_h_flag_out  : out std_logic
);

end component;


component reg_file is port (
							--Clock and reset
					        cp2         : in  std_logic;
							cp2en       : in  std_logic;
                            ireset      : in  std_logic;
						  
                            reg_rd_in   : in std_logic_vector  (7 downto 0);
                            reg_rd_out  : out std_logic_vector (7 downto 0);
                            reg_rd_adr  : in std_logic_vector  (4 downto 0);
                            reg_rr_out  : out std_logic_vector (7 downto 0);
                            reg_rr_adr  : in std_logic_vector  (4 downto 0);
                            reg_rd_wr   : in std_logic;

                            post_inc    : in std_logic;                       -- POST INCREMENT FOR LD/ST INSTRUCTIONS
                            pre_dec     : in std_logic;                        -- PRE DECREMENT FOR LD/ST INSTRUCTIONS
                            reg_h_wr    : in std_logic;
                            reg_h_out   : out std_logic_vector (15 downto 0);
                            reg_h_adr   : in std_logic_vector (2 downto 0);    -- x,y,z
   		                    reg_z_out   : out std_logic_vector (15 downto 0)  -- OUTPUT OF R31:R30 FOR LPM/ELPM/IJMP INSTRUCTIONS
                            );
end component;

component io_reg_file is port (
          		               --Clock and reset
	                           cp2           : in  std_logic;
							   cp2en         : in  std_logic;							   
                               ireset        : in  std_logic;

                               adr           : in  std_logic_vector(15 downto 0);         
                               iowe          : in  std_logic;         
                               dbusout       : in  std_logic_vector(7 downto 0);         

                               sreg_fl_in    : in  std_logic_vector(7 downto 0);         
                               sreg_out      : out std_logic_vector(7 downto 0);         

                               sreg_fl_wr_en : in std_logic_vector (7 downto 0);   --FLAGS WRITE ENABLE SIGNALS       

                               spl_out       : out std_logic_vector(7 downto 0);         
                               sph_out       : out std_logic_vector(7 downto 0);         
                               sp_ndown_up   : in  std_logic; -- DIRECTION OF CHANGING OF STACK POINTER SPH:SPL 0->UP(+) 1->DOWN(-)
                               sp_en         : in  std_logic; -- WRITE ENABLE(COUNT ENABLE) FOR SPH AND SPL REGISTERS
  
                               rampz_out     : out std_logic_vector(7 downto 0));
end component;


component bit_processor is port(
  							  --Clock and reset
                              cp2             : in  std_logic;
							  cp2en           : in  std_logic;
                              ireset          : in  std_logic;            
              
                              bit_num_r_io    : in  std_logic_vector(2 downto 0); -- BIT NUMBER FOR CBI/SBI/BLD/BST/SBRS/SBRC/SBIC/SBIS INSTRUCTIONS
                              dbusin          : in  std_logic_vector(7 downto 0); -- SBI/CBI/SBIS/SBIC  IN
                              bitpr_io_out    : out std_logic_vector(7 downto 0); -- SBI/CBI OUT        
                              sreg_out        : in  std_logic_vector(7 downto 0); -- BRBS/BRBC/BLD IN 
                              branch          : in  std_logic_vector(2 downto 0); -- NUMBER (0..7) OF BRANCH CONDITION FOR BRBS/BRBC INSTRUCTION
                              bit_pr_sreg_out : out std_logic_vector(7 downto 0); -- BCLR/BSET/BST(T-FLAG ONLY)             
                              bld_op_out      : out std_logic_vector(7 downto 0); -- BLD OUT (T FLAG)
                              reg_rd_out      : in  std_logic_vector(7 downto 0); -- BST/SBRS/SBRC IN    
                              bit_test_op_out : out std_logic;                    -- OUTPUT OF SBIC/SBIS/SBRS/SBRC/BRBC/BRBS
                              -- Instructions and states
                              sbi_st          : in  std_logic;
                              cbi_st          : in  std_logic;
                              idc_bst         : in  std_logic;
                              idc_bset        : in  std_logic;
                              idc_bclr        : in  std_logic;
                              idc_sbic        : in  std_logic;
                              idc_sbis        : in  std_logic;
                              idc_sbrs        : in  std_logic;
                              idc_sbrc        : in  std_logic;
                              idc_brbs        : in  std_logic;
                              idc_brbc        : in  std_logic;
                              idc_reti        : in  std_logic
							  );

end component;

component io_adr_dec is port (
          adr          : in std_logic_vector(15 downto 0);         
          iore         : in std_logic;         
          dbusin_ext   : in std_logic_vector(7 downto 0);
          dbusin_int   : out std_logic_vector(7 downto 0);
                    
          spl_out      : in std_logic_vector(7 downto 0); 
          sph_out      : in std_logic_vector(7 downto 0);           
          sreg_out     : in std_logic_vector(7 downto 0);           
          rampz_out    : in std_logic_vector(7 downto 0));
end component;
	
end AVR_Core_CompPack;	



