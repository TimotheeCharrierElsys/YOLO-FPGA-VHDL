-----------------------------------------------------------------------------------
--!     @file       adder_tree
--!     @brief      This file provides an adder tree entity and architecture
--!                 It uses recursion to create it.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity adder_tree
--! This entity implements a binary adder tree.
--! It sums multiple operands using a tree structure, reducing the number of inputs
--! by half in each stage until the final sum is obtained.
entity adder_tree is
    generic (
        DO_PIPELINE  : std_logic := '1'; --! Define if the design is pipelined ('1') or not ('0')
        NUM_OPERANDS : integer   := 8;   --! Number of i_operands
        BITWIDTH     : integer   := 8    --! Width of each input
    );
    port (
        clock        : in std_logic;                                               --! Clock signal
        reset_n      : in std_logic;                                               --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                               --! System enable signal, active at high state
        i_operands   : in t_vec(NUM_OPERANDS - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data vector
        o_result     : out std_logic_vector(BITWIDTH - 1 downto 0)                 --! Output sum
    );
end adder_tree;

architecture adder_tree_arch of adder_tree is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant HALF_OPERANDS : integer := NUM_OPERANDS / 2; --! Integer representing half the number of operands

    -------------------------------------------------------------------------------------
    -- SIGNAL
    -------------------------------------------------------------------------------------
    signal r_result                  : std_logic_vector(BITWIDTH - 1 downto 0); --! Result register
    signal result_left, result_right : std_logic_vector(BITWIDTH - 1 downto 0); --! Intermediate results from left and right subtrees

begin

    -------------------------------------------------------------------------------------
    -- Base Case: NUM_OPERANDS = 1
    -------------------------------------------------------------------------------------
    gen_base_case : if NUM_OPERANDS = 1 generate

        -- Pipelined version for base case
        gen_do_pipeline : if DO_PIPELINE = '1' generate
            process (clock, reset_n)
            begin
                if reset_n = '0' then
                    r_result <= (others => '0');
                elsif rising_edge(clock) then
                    if i_sys_enable = '1' then
                        r_result <= i_operands(0);
                    end if;
                end if;
            end process;
            o_result <= r_result;
        end generate gen_do_pipeline;

        -- Non-pipelined version for base case
        gen_do_not_pipeline : if DO_PIPELINE = '0' generate
            r_result <= i_operands(0);
            o_result <= r_result;
        end generate gen_do_not_pipeline;

    end generate gen_base_case;

    -------------------------------------------------------------------------------------
    -- Case: NUM_OPERANDS = 2
    -------------------------------------------------------------------------------------
    gen_two_i_operands : if NUM_OPERANDS = 2 generate

        -- Pipelined version for two operands
        gen_do_pipeline : if DO_PIPELINE = '1' generate
            process (clock, reset_n)
            begin
                if reset_n = '0' then
                    r_result <= (others => '0');
                elsif rising_edge(clock) then
                    if i_sys_enable = '1' then
                        r_result <= std_logic_vector(signed(i_operands(0)) + signed(i_operands(1)));
                    end if;
                end if;
            end process;
            o_result <= r_result;
        end generate gen_do_pipeline;

        -- Non-pipelined version for two operands
        gen_do_not_pipeline : if DO_PIPELINE = '0' generate
            r_result <= std_logic_vector(signed(i_operands(0)) + signed(i_operands(1)));
            o_result <= r_result;
        end generate gen_do_not_pipeline;

    end generate gen_two_i_operands;

    -------------------------------------------------------------------------------------
    -- Recursive Case: NUM_OPERANDS > 2
    -------------------------------------------------------------------------------------
    gen_recursive : if NUM_OPERANDS > 2 generate

        -- Instantiate left adder_tree
        inst_left : entity LIB_RTL.adder_tree
            generic map(
                DO_PIPELINE  => DO_PIPELINE,
                NUM_OPERANDS => HALF_OPERANDS,
                BITWIDTH     => BITWIDTH
            )
            port map(
                clock        => clock,
                reset_n      => reset_n,
                i_sys_enable => i_sys_enable,
                i_operands   => i_operands(HALF_OPERANDS - 1 downto 0),
                o_result     => result_left
            );

        -- Instantiate right adder_tree
        inst_right : entity LIB_RTL.adder_tree
            generic map(
                DO_PIPELINE  => DO_PIPELINE,
                NUM_OPERANDS => NUM_OPERANDS - HALF_OPERANDS,
                BITWIDTH     => BITWIDTH
            )
            port map(
                clock        => clock,
                reset_n      => reset_n,
                i_sys_enable => i_sys_enable,
                i_operands   => i_operands(NUM_OPERANDS - 1 downto HALF_OPERANDS),
                o_result     => result_right
            );

        -- Pipelined version for recursive case
        gen_do_pipeline : if DO_PIPELINE = '1' generate
            process (clock, reset_n)
            begin
                if reset_n = '0' then
                    r_result <= (others => '0');
                elsif rising_edge(clock) then
                    if i_sys_enable = '1' then
                        r_result <= std_logic_vector(signed(result_left) + signed(result_right));
                    end if;
                end if;
            end process;
            o_result <= r_result;
        end generate gen_do_pipeline;

        -- Non-pipelined version for recursive case
        gen_do_not_pipeline : if DO_PIPELINE = '0' generate
            r_result <= std_logic_vector(signed(result_left) + signed(result_right));
            o_result <= r_result;
        end generate gen_do_not_pipeline;
    end generate gen_recursive;
end architecture;