-------------------------------------------------------------------------------
-- $Id: jop_cv-c.vhd,v 1.2 2006/01/03 21:06:27 arnim Exp $
-------------------------------------------------------------------------------

configuration jop_cv_struct_c0 of jop_cv is

  for struct

    for pll_b: altpll
      use configuration work.altpll_behav_c0;
    end for;

    for cv_console_b: cv_console
      use configuration work.cv_console_struct_c0;
    end for;

    for all: altsyncram
      use configuration work.altsyncram_struct_c0;
    end for;

    for snespads_b: snespad
      use configuration work.snespad_struct_c0;
    end for;

    for dac_b: dac
      use configuration work.dac_rtl_c0;
    end for;

  end for;

end jop_cv_struct_c0;
