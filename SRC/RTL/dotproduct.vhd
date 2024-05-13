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

library LIB_RTL;
use LIB_RTL.dotproduct_pkg.all;

entity dotproduct_top is
    port (
        i_clk   : in std_logic; --! Clock input
        i_reset : in std_logic; --! Reset input
        i_A     : in t_in_vec;  --! Input vector A
        i_B     : in t_in_vec;  --! Input vector B
        o_C     : out t_bit16   --! Output for the dot product result
    );
end entity dotproduct_top;

architecture dotproduct_top_arch of dotproduct_top is

    signal reg : t_bit16; --! Internal signal for storing the result

begin

    p_dotproduct_top : process (i_clk, i_reset, reg) is
        variable sum : t_bit16;
    begin
        if i_reset = '1' then
            reg <= (others => '0');
        elsif rising_edge(i_clk) then
            -- Compute the dot product and store in sum
            sum := dotproduct(i_A, i_B);
            reg <= sum;
        end if;
        -- Ouput Update
        o_C <= reg;
    end process p_dotproduct_top;
end architecture dotproduct_top_arch;