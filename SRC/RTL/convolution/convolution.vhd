-----------------------------------------------------------------------------------
--!     @Package    convolution
--!     @brief      This package provides the pipelined MOA tree entity and architecture
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

library LIB_RTL;
use LIB_RTL.convolution_pkg.all;

entity convolution is
    generic (
        BITWIDTH    : integer := 8; --! Bit width of each operand
        IMG_WIDTH   : integer := 4;
        IMG_HEIGHT  : integer := 4;
        KERNEL_SIZE : integer := 3
    );
    port (
        i_clk    : in std_logic; --! Clock signal
        i_rst    : in std_logic; --! Reset signal
        i_img    : in t_mat(0 to IMG_WIDTH - 1)(0 to IMG_HEIGHT - 1)(0 to BITWIDTH - 1);
        i_kernel : in t_mat(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(0 to BITWIDTH - 1);
        o_result : out t_mat(0 to (IMG_WIDTH - KERNEL_SIZE)/2)(0 to (IMG_HEIGHT - KERNEL_SIZE)/2)(0 to BITWIDTH - 1)
    );
end entity convolution;

architecture convolution_arch of convolution is

    constant OUTPUT_WIDTH  : integer := (IMG_WIDTH - KERNEL_SIZE)/2 + 1;
    constant OUTPUT_HEIGHT : integer := (IMG_HEIGHT - KERNEL_SIZE)/2 + 1;

    signal r_result : t_mat(0 to OUTPUT_WIDTH - 1)(0 to OUTPUT_HEIGHT - 1)(0 to BITWIDTH - 1);
begin

    --! @process
    --! @brief Handles the synchronous and asynchronous operations of the pipelined adder.
    process (i_clk, i_rst)
        variable sum : integer := 0;
    begin
        if i_rst = '1' then
            -- Initialize the pipeline with zeros on reset
            for i in 0 to OUTPUT_WIDTH - 1 loop
                for j in 0 to OUTPUT_HEIGHT - 1 loop
                    r_result(i)(j) <= (others => '0');
                end loop;
            end loop;
            sum := 0;
        elsif rising_edge(i_clk) then
            for i in 0 to OUTPUT_WIDTH - 1 loop
                for j in 0 to OUTPUT_HEIGHT loop
                    sum := 0;
                    for ki in 0 to KERNEL_SIZE - 1 loop
                        for kj in 0 to KERNEL_SIZE - 1 loop
                            sum := sum + to_integer(signed(i_img(i + ki)(j + kj))) * to_integer(signed(i_kernel(ki)(kj)));
                        end loop;
                    end loop;
                    r_result(i)(j) <= std_logic_vector(to_signed(sum, BITWIDTH));
                end loop;
            end loop;
        end if;
    end process;

    o_result <= r_result;

end architecture convolution_arch;