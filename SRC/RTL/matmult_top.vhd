------------------------------------------------------------------------------
--! @File        : matmult_top
--! @Description : This file provides the top level to compute the dot product
--!                of two vectors represented as arrays of float32.
--! @Author      : Timothée Charrier
--! Version      : 1.0
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.matmult_pkg.all;

entity matmult_top is
    port (
        i_clk   : in std_logic; --! Clock input
        i_reset : in std_logic; --! Reset input
        i_A     : in t_in_mat;  --! Input vector A
        i_B     : in t_in_mat;  --! Input vector B
        o_C     : out t_out_mat --! Output for the dot product result
    );
end entity matmult_top;

architecture matmult_top_arch of matmult_top is

    signal s_result : t_out_mat; --! Internal signal for storing the resulted Matrix

begin

    p_matmult_top : process (i_clk, i_reset) is
    begin
        if i_reset = '1' then
            s_result <= (others => (others => (others => '0')));
        elsif rising_edge(i_clk) then

            for i in 0 to t_in_mat'length - 1 loop
                for j in 0 to t_in_mat'length - 1 loop
                    -- Compute the dot product and store in s_result
                    s_result(i)(j) <= dotproduct(i_A(i), i_B(i));
                end loop;
            end loop;

        end if;
    end process p_matmult_top;

    o_C <= s_result;
end architecture matmult_top_arch;