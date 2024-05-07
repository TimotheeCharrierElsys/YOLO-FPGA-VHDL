------------------------------------------------------------------------------
--! @File        : dotproduct_top
--! @Description : This file provides the top level to compute the dot product
--!                of two vectors represented as arrays of float32.
--! @Author      : Timothée Charrier
--! Version      : 1.0
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dotproduct_pkg.all;

entity dotproduct_top is
  port (
    i_clk   : in std_logic;  --! Clock input
    i_reset : in std_logic;  --! Reset input
    i_A     : in t_in_vec;   --! Input vector A
    i_B     : in t_in_vec;   --! Input vector B
    o_C     : out t_signed16 --! Output for the dot product result
  );
end entity dotproduct_top;

architecture dotproduct_top_arch of dotproduct_top is

  signal s_result : t_signed16; --! Internal signal for storing the result
  signal s_A      : t_in_vec;   --! Internal signal for input vector A
  signal s_B      : t_in_vec;   --! Internal signal for input vector B

begin

  s_A <= i_A;
  s_B <= i_B;

  p_dotproduct_top : process (i_clk, i_reset, s_A, s_B) is
  begin
    if i_reset = '1' then
      s_result <= (others => '0');
    elsif rising_edge(i_clk) then
      s_result <= dotproduct(s_A, s_B); --! Compute the dot product and store in s_result
    end if;
  end process p_dotproduct_top;

  o_C <= s_result;
end architecture dotproduct_top_arch;