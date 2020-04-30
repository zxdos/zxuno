-------------------------------------------------------------------------------
--
-- $Id: T80-c.vhd,v 1.1 2006/01/03 08:23:24 arnim Exp $
--
-------------------------------------------------------------------------------

configuration T80_rtl_c0 of T80 is

  for rtl

    for mcode: T80_MCode
      use configuration work.T80_MCode_rtl_c0;
    end for;

    for alu: T80_ALU
      use configuration work.T80_ALU_rtl_c0;
    end for;

    for Regs: T80_Reg
      use configuration work.T80_Reg_rtl_c0;
    end for;

  end for;

end T80_rtl_c0;
