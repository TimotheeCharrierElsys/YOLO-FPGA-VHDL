-----------------------------------------------------------------------------------
--!     @file       adder_tree
--!     @brief      This file provides an adder tree entity and architecture
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

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
        clock        : in std_logic;                                        --! Clock signal
        reset_n      : in std_logic;                                        --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                        --! Reset signal, active at low state
        i_data       : in t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data vector
        o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)          --! Output data
    );
end adder_tree;

architecture adder_tree_arch of adder_tree is

    signal reg_i_data  : t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal data_vector : t_vec(0 to (N_OPD - 1))(BITWIDTH - 1 downto 0);

    signal sum     : std_logic_vector((BITWIDTH - 1) downto 0);
    signal reg_sum : std_logic_vector((BITWIDTH - 1) downto 0);

begin

    process (clock, reset_n)
    begin
        if reset_n = '0' then

        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                for TERM_INDEX in 0 to (N_OPD - 1) loop
                    reg_i_data(TERM_INDEX) <= i_data(TERM_INDEX);
                end loop;
                reg_sum <= sum;
            end if;
        end if;
    end process;

    gen_data_vector : process (reg_i_data)
    begin
        for TERM_INDEX in 0 to (N_OPD - 1) loop
            data_vector(TERM_INDEX) <= reg_i_data(TERM_INDEX);
        end loop;
    end process gen_data_vector;

    gen_sum : process (data_vector)
        variable accumulator : std_logic_vector((BITWIDTH - 1) downto 0);
    begin
        accumulator := std_logic_vector(to_signed(0, accumulator'length));
        for TERM_INDEX in 0 to (N_OPD - 1) loop
            accumulator := std_logic_vector(signed(accumulator) + signed(data_vector(TERM_INDEX)));
        end loop;
        sum <= accumulator;
    end process gen_sum;

    o_data <= reg_sum;

end architecture adder_tree_arch;

architecture adder_tree_pipelined_arch of adder_tree is

    signal reg_i_data       : t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal data_vector      : t_vec(0 to (N_OPD - 1))(BITWIDTH - 1 downto 0);
    signal data_vector_next : t_vec(0 to (N_OPD - 1))(BITWIDTH - 1 downto 0);

    signal sum     : std_logic_vector((BITWIDTH - 1) downto 0);
    signal reg_sum : std_logic_vector((BITWIDTH - 1) downto 0);

begin

    process (clock, reset_n)
    begin
        if reset_n = '0' then

        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                for TERM_INDEX in 0 to (N_OPD - 1) loop
                    reg_i_data(TERM_INDEX) <= i_data(TERM_INDEX);
                end loop;
                reg_sum          <= sum;
                data_vector_next <= data_vector;
            end if;
        end if;
    end process;

    gen_data_vector : process (reg_i_data)
    begin
        for TERM_INDEX in 0 to (N_OPD - 1) loop
            data_vector(TERM_INDEX) <= reg_i_data(TERM_INDEX);
        end loop;
    end process gen_data_vector;

    gen_sum : process (data_vector_next)
        variable accumulator : std_logic_vector((BITWIDTH - 1) downto 0);
    begin
        accumulator := std_logic_vector(to_signed(0, accumulator'length));
        for TERM_INDEX in 0 to (N_OPD - 1) loop
            accumulator := std_logic_vector(signed(accumulator) + signed(data_vector_next(TERM_INDEX)));
        end loop;
        sum <= accumulator;
    end process gen_sum;

    o_data <= reg_sum;

end architecture adder_tree_pipelined_arch;