-----------------------------------------------------------------------------------
--!     @Package    binary_adder_tree
--!     @brief      This file provides the binary adder tree entity and architecture
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity binary_adder_tree
--! This entity implements a pipelined multi-operand adder (MOA).
--!        It sums multiple operands using a tree structure, reducing the number of inputs
--!        by half in each stage until the final sum is obtained.
entity binary_adder_tree is
    generic (
        N_OPD    : integer := 8; --! Number of operands (must be a power of 2)
        BITWIDTH : integer := 8  --! Bit width of each operand
    );
    port (
        i_clk  : in std_logic;                                    --! Clock signal
        i_rst  : in std_logic;                                    --! Reset signal, active at high state
        i_data : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Input data vector
        o_data : out std_logic_vector(BITWIDTH - 1 downto 0)      --! Output data
    );
end binary_adder_tree;

architecture binary_adder_tree_arch of binary_adder_tree is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------

    constant N_STAGES : integer := integer(ceil(log2(real(N_OPD)))); --! Number of stages required to complete the addition process.

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------

    signal r_pipeline : t_mat(0 to N_STAGES)(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Multi-dimensional array representing the pipeline stages.
begin

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset high)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipelined adder.
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Initialize the pipeline with zeros on reset
            for stage in 0 to N_STAGES loop
                for i in 0 to N_OPD - 1 loop
                    r_pipeline(stage)(i) <= (others => '0');
                end loop;
            end loop;
        elsif rising_edge(i_clk) then
            -- Initialize the pipeline with input data
            for i in 0 to N_OPD - 1 loop
                r_pipeline(0)(i) <= i_data(i);
            end loop;

            -- Perform pipelined addition
            for stage in 1 to N_STAGES loop
                for i in 0 to (N_OPD / (2 ** stage)) - 1 loop
                    if (2 * i + 1) < (N_OPD / (2 ** (stage - 1))) then
                        r_pipeline(stage)(i) <= std_logic_vector(unsigned(r_pipeline(stage - 1)(2 * i)) + unsigned(r_pipeline(stage - 1)(2 * i + 1)));
                    else
                        r_pipeline(stage)(i) <= r_pipeline(stage - 1)(2 * i);
                    end if;
                end loop;
            end loop;
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- OUTPUT ASSIGNMENT
    -------------------------------------------------------------------------------------
    o_data <= r_pipeline(N_STAGES)(0);

end binary_adder_tree_arch;