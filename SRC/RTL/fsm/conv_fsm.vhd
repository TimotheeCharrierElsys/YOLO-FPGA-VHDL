-----------------------------------------------------------------------------------
--!     @Package    fsm_one_mac
--!     @brief      This file provides an adder tree entity and architecture
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity fsm_one_mac
--! This entity implements a pipelined multi-operand adder (MOA).
--! It sums multiple operands using a tree structure, reducing the number of inputs
--! by half in each stage until the final sum is obtained.
entity fsm_one_mac is
    generic (
        KERNEL_SIZE : integer := 3 --! Kernel Size
    );
    port (
        clock       : in std_logic;                                   --! Clock signal
        reset_n     : in std_logic;                                   --! Reset signal, active at low state
        i_valid     : in std_logic;                                   --! Valid signal
        o_count_row : out std_logic_vector(KERNEL_SIZE - 1 downto 0); --! Row index tracker
        o_count_col : out std_logic_vector(KERNEL_SIZE - 1 downto 0); --! Col index tracker
        o_valid     : out std_logic                                   --! Valid output
    );
end fsm_one_mac;

architecture fsm_one_mac_arch of fsm_one_mac is

    -------------------------------------------------------------------------------------
    -- STATES
    -------------------------------------------------------------------------------------
    type type_state is (IDLE, COMPUTE, DONE);

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal current_state : type_state;
    signal next_state    : type_state;
    signal count         : integer range 0 to KERNEL_SIZE * KERNEL_SIZE - 1;

begin

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipelined adder.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Initialize the state
            current_state <= IDLE;

        elsif rising_edge(clock) then
            current_state <= next_state;
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- COMB PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipelined adder.
    process (current_state, i_valid, i_first_time)
    begin
        case current_state is
            when IDLE =>
                if (i_valid = '1') then
                    if (i_first_time = '1') then
                        next_state <= COMPUTE_FIRST_TIME;
                    else
                        next_state <= COMPUTE_OTHERS;
                    end if;
                else
                    next_state <= idle;
                end if;

            when COMPUTE_FIRST_TIME =>
            when COMPUTE_OTHERS     =>
            when DONE               =>
        end case;

    end process;

end fsm_one_mac_arch;