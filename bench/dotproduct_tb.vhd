
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.dotproduct_pkg.all;
-- use work.dotproduct_pkg.all;

entity dotproduct_top_tb is
end;

architecture bench of dotproduct_top_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  -- Ports
  signal i_clk_s   : std_logic := '0';
  signal i_reset_s : std_logic := '0';
  signal i_A_s     : t_in_vec  := (0, 1);
  signal i_B_s     : t_in_vec  := (1, 0);
  signal o_C_s     : t_signed16;
begin

  UUT : entity work.dotproduct_top
    port map(
      i_clk   => i_clk_s,
      i_reset => i_reset_s,
      i_A     => i_A_s,
      i_B     => i_B_s,
      o_C     => o_C_s
    );

  i_clk_s   <= not i_clk_s after clk_period/2;
  i_reset_s <= '1' after 10 ns, '0' after 30 ns;

end;