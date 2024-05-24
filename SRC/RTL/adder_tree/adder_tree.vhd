-----------------------------------------------------------------------------------
--!     @Package    adder_tree
--!     @brief      This file provides an adder tree entity and architecture
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity adder_tree
--! This entity implements a pipelined multi-operand adder (MOA).
--! It sums multiple operands using a tree structure, reducing the number of inputs
--! by half in each stage until the final sum is obtained.
entity adder_tree is
    generic (
        N_OPD    : integer := 12; --! Number of operands
        BITWIDTH : integer := 8   --! Bit width of each operand
    );
    port (
        i_clk  : in std_logic;                                    --! Clock signal
        i_rst  : in std_logic;                                    --! Reset signal, active at high state
        i_data : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Input data vector
        o_data : out std_logic_vector(BITWIDTH - 1 downto 0)      --! Output data
    );
end adder_tree;

architecture adder_tree_arch of adder_tree is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant N_STAGES : integer := integer(ceil(log2(real(N_OPD)))); --! Number of stages required to complete the addition process.

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_next : t_mat(0 to N_STAGES)(0 to (2 ** N_STAGES) - 1)(BITWIDTH - 1 downto 0); --! Next state of the pipeline registers
    signal r_reg  : t_mat(0 to N_STAGES)(0 to (2 ** N_STAGES) - 1)(BITWIDTH - 1 downto 0); --! Current state of the pipeline registers

begin

    -------------------------------------------------------------------------------------
    -- INPUT GENERATION
    -------------------------------------------------------------------------------------
    -- This generate block assigns the input data to the appropriate stage of the adder tree.
    input_gen : for i in 0 to N_OPD - 1 generate
        r_next(N_STAGES)(i) <= i_data(i);
    end generate;

    -------------------------------------------------------------------------------------
    -- PADDING GENERATION
    -------------------------------------------------------------------------------------
    -- This generate block pads the remaining positions with zeros if the number of operands is less than 2^N_STAGES.
    pading_gen : if N_OPD < 2 ** N_STAGES generate
        r_next(N_STAGES)(N_OPD to (2 ** N_STAGES) - 1) <= (others => (others => '0'));
    end generate;

    -------------------------------------------------------------------------------------
    -- STAGE GENERATION
    -------------------------------------------------------------------------------------
    -- This generate block creates the tree structure of the adder, reducing the number of operands by half in each stage.
    stage_gen : for i in (N_STAGES - 1) downto 0 generate
        row_gen : for j in 0 to (2 ** i - 1) generate
            r_next(i)(j) <= std_logic_vector(signed(r_reg(i + 1)(2 * j)) + signed(r_reg(i + 1)(2 * j + 1)));
        end generate;
    end generate;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset high)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipelined adder.
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Initialize the register with zeros on reset
            for i in 0 to N_STAGES loop
                r_reg(i) <= (others => (others => '0'));
            end loop;
        elsif rising_edge(i_clk) then
            r_reg <= r_next; -- Transfer next state to current state on rising edge of the clock
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- OUTPUT ASSIGNMENT
    -------------------------------------------------------------------------------------
    -- Assign the final output data from the first stage of the register
    o_data <= r_reg(0)(0);

end adder_tree_arch;