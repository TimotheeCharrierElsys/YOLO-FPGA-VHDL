-----------------------------------------------------------------------------------
--!     @file       silu_activation
--!     @brief      This entity implements a scaled silu activation function 
--!                 It uses hardswish approxmation fucntion.
--!                 See https://arxiv.org/pdf/1905.02244 for more details
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

--! Entity silu_activation
--! This entity implements an approximated silu activation function.
entity silu_activation is
    generic (
        BITWIDTH            : integer := 16; --! Bit width of each operand
        SCALE_FACTOR_POWER2 : integer := 10  --! Scale factor for integer computation power (eg. 10 -> 2**10)
    );
    port (
        clock        : in std_logic;                                   --! Clock signal
        reset_n      : in std_logic;                                   --! Reset signal, active low
        i_sys_enable : in std_logic;                                   --! Global enable signal, active high
        i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Input data
        o_data       : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output data
    );
end silu_activation;

architecture silu_activation_arch of silu_activation is

    -------------------------------------------------------------------------------------
    -- CONSTANT
    -------------------------------------------------------------------------------------
    constant SCALE_FACTOR   : integer := 2 ** SCALE_FACTOR_POWER2;
    constant THRESHOLD_NEG  : integer := - 3 * SCALE_FACTOR;
    constant THRESHOLD_POS  : integer := 3 * SCALE_FACTOR;
    constant DIVISION_VALUE : integer := integer(ceil(log2(real(SCALE_FACTOR/6))));

    -------------------------------------------------------------------------------------
    -- SIGNAL
    -------------------------------------------------------------------------------------
    signal i_data_signed : signed(BITWIDTH - 1 downto 0);

begin

    -- Input conversion for computation
    i_data_signed <= signed(i_data);

    -------------------------------------------------------------------------------------
    -- GENERATE PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the computation of the activation function
    process (clock, reset_n)
        variable hardswish_add  : signed(BITWIDTH - 1 downto 0);
        variable hardswish_mult : signed(2 * BITWIDTH - 1 downto 0);
    begin
        if reset_n = '0' then
            hardswish_mult := (others => '0');
            hardswish_add  := (others => '0');
            o_data <= (others         => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                if i_data_signed < THRESHOLD_NEG then
                    -- Test if x < -3 scaled
                    hardswish_mult := (others => '0');
                elsif i_data_signed < THRESHOLD_POS then
                    -- Test if x > -3  and x < 3 scaled

                    -- Compute the addition
                    hardswish_add := i_data_signed + to_signed(THRESHOLD_POS, BITWIDTH);

                    -- Compute x * (x + 3) scaled
                    hardswish_mult := resize(hardswish_add * i_data_signed, 2 * BITWIDTH);

                    -- Compute the division using division to multiplication method (multiplu then shift)
                    hardswish_mult := resize(hardswish_mult * to_signed(DIVISION_VALUE, 2 * BITWIDTH), 2 * BITWIDTH);
                    hardswish_mult := shift_right(hardswish_mult, SCALE_FACTOR_POWER2);

                else
                    -- Test if x > 3
                    hardswish_mult := resize(i_data_signed, 2 * BITWIDTH);
                end if;

                -- Output update
                o_data <= std_logic_vector(hardswish_mult);
            end if;
        end if;
    end process;
end architecture;