-----------------------------------------------------------------------------------
--!     @File    matmult_top
--!     @brief   This file provides the top level to compute the matrix multiplication
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.conv_pkg.all;

entity matmult_top is
    generic (
        WIDTH  : integer := 3; --! Matrix Width
        HEIGHT : integer := 3  --! Matrix Height
    );
    port (
        i_clk    : in std_logic;                                           --! Clock Input
        i_reset  : in std_logic;                                           --! Reset Input
        i_start  : std_logic;                                              --! Start Input
        i_A      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);   --! Input Matrix A
        i_B      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);   --! Input Matrix B
        o_result : out t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0); --! Output Matrix
        o_valid  : out std_logic                                           --! Output Valid
    );
end entity matmult_top;

architecture matmult_top_arch of matmult_top is

    -- 
    -- SIGNALS
    --

    signal r_A      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);  --! Registered Input Matrix A
    signal r_B      : t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);  --! Registered Input Matrix B
    signal r_result : t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0); --! Result Matrix

begin

    l_ROW_MULT : for i in 0 to WIDTH - 1 generate
        l_COL_MULT : for j in 0 to HEIGHT - 1 generate

            ROW_COL_MULT : matmult_core
            generic map(
                VECTOR_SIZE => WIDTH
            )
            port map(
                i_clk    => i_clk,
                i_reset  => i_reset,
                i_start  => i_start,
                i_A      => r_A(i),
                i_B      => r_B(j),
                o_result => r_result(i)(j)
            );

        end generate; -- l_COL_MULT
    end generate; -- l_ROW_MULT

    r_A      <= i_A;
    r_B      <= i_B;
    o_result <= r_result;

end architecture matmult_top_arch;

configuration matmult_top_conf of matmult_top is
    for matmult_top_arch
        for l_ROW_MULT
            for l_COL_MULT
                for all : matmult_core
                    use entity LIB_RTL.matmult_core(matmult_core_arch);
                end for;
            end for;
        end for;
    end for;
end configuration matmult_top_conf;