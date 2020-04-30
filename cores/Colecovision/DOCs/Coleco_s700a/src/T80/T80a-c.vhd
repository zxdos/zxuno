-------------------------------------------------------------------------------
--
-- $Id: T80a-c.vhd,v 1.1 2006/01/03 08:23:24 arnim Exp $
--
-------------------------------------------------------------------------------

configuration T80a_rtl_c0 of T80a is

  for rtl

    for u0: T80
      use configuration work.T80_rtl_c0;
    end for;

  end for;

end T80a_rtl_c0;
