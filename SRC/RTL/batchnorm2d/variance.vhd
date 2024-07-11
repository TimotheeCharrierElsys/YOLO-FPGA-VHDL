-----------------------------------------------------------------------------------
--!     @file       variance
--!     @brief      This file provides a module computing the variance of a given input volume
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity variance
--! Implements a variance computing module
entity variance is
    generic (
        BITWIDTH       : integer := 16; --! Bit width of each operand
        INPUT_SIZE     : integer := 3;  --! Input Matrix Size (squared)
        CHANNEL_NUMBER : integer := 3   --! Number of channels in the input
    );
    port (
        clock           : in std_logic;                                                                                                      --! Clock signal
        reset_n         : in std_logic;                                                                                                      --! Reset signal, active low
        i_sys_enable    : in std_logic;                                                                                                      --! Global enable signal, active high
        i_volume        : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input volume
        i_volume_valid  : in std_logic;                                                                                                      --! Input volume valid signal
        o_mean          : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                     --! Channel-wise output mean
        o_mean_done     : out std_logic;                                                                                                     --! Output mean valid signal
        o_variance      : out t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                 --! Channel-wise output variance
        o_variance_done : out std_logic                                                                                                      --! Output variance valid signal

    );
end variance;

architecture variance_arch of variance is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 10;                                                --! Power of 2 scaling factor for division
    constant DIVISION_SCALE_FACTOR            : integer := 2 ** DIVISION_SCALE_FACTOR_POWER_OF_2;             --! Scale factor for division
    constant VARIANCE_DIVISION_FACTOR         : integer := DIVISION_SCALE_FACTOR / (INPUT_SIZE * INPUT_SIZE); --! Variance scaling factor

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type t_computation_signed is array (CHANNEL_NUMBER - 1 downto 0) of signed(DIVISION_SCALE_FACTOR_POWER_OF_2 + 2 * BITWIDTH - 1 downto 0); --! Type to handle computation

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_channel_mean             : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Mean value for each channel
    signal r_mean_done                : std_logic;                                                 --! Mean computation done flag
    signal r_mean_done_previous_state : std_logic;                                                 --! Previous state of mean done flag
    signal r_start_computation        : std_logic;                                                 --! Flag to start variance computation
    signal r_update_counter           : std_logic;                                                 --! Flag to update the position counters
    signal r_count_row                : integer range 0 to INPUT_SIZE - 1;                         --! Counter for row position within the kernel
    signal r_count_col                : integer range 0 to INPUT_SIZE - 1;                         --! Counter for column position within the kernel
    signal r_diff                     : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Difference between input value and mean

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mean
        generic (
            BITWIDTH                         : integer;
            INPUT_SIZE                       : integer;
            CHANNEL_NUMBER                   : integer;
            DIVISION_SCALE_FACTOR_POWER_OF_2 : integer
        );
        port (
            clock          : in std_logic;
            reset_n        : in std_logic;
            i_sys_enable   : in std_logic;
            i_volume       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_volume_valid : in std_logic;
            o_mean         : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_mean_done    : out std_logic
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- mean INSTANTIATION
    -------------------------------------------------------------------------------------
    mean_inst : mean
    generic map(
        BITWIDTH                         => BITWIDTH,
        INPUT_SIZE                       => INPUT_SIZE,
        CHANNEL_NUMBER                   => CHANNEL_NUMBER,
        DIVISION_SCALE_FACTOR_POWER_OF_2 => DIVISION_SCALE_FACTOR_POWER_OF_2
    )
    port map(
        clock          => clock,
        reset_n        => reset_n,
        i_sys_enable   => i_sys_enable,
        i_volume       => i_volume,
        i_volume_valid => i_volume_valid,
        o_mean         => r_channel_mean,
        o_mean_done    => r_mean_done
    );

    o_mean      <= r_channel_mean;
    o_mean_done <= r_mean_done;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    counter_control : process (clock, reset_n)
        variable variance_division : t_computation_signed                                          := (others => (others => '0')); --! Variable to store the scaled division
        variable r_squared         : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0) := (others => (others => '0')); --! Squared differences accumulation
    begin
        if reset_n = '0' then
            -- Reset counters and control signals to initial states.
            r_count_row                <= 0;
            r_count_col                <= 0;
            r_mean_done_previous_state <= '0';
            r_start_computation        <= '0';
            r_update_counter           <= '0';
            o_variance_done            <= '0';
            o_variance                 <= (others => (others => '0'));
            r_diff                     <= (others => (others => '0'));

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                r_mean_done_previous_state <= r_mean_done;

                -- Start computation when mean is done
                if (r_start_computation = '0' and r_mean_done = '1' and r_mean_done_previous_state = '0') then
                    r_start_computation <= '1';
                    r_update_counter    <= '1';
                    r_diff              <= (others => (others => '0'));
                    r_squared := (others => (others => '0'));
                end if;

                if (r_start_computation = '1') then
                    if (r_update_counter = '1') then
                        -- Update position counters
                        if r_count_col = INPUT_SIZE - 1 then
                            r_count_col <= 0;
                            if r_count_row = INPUT_SIZE - 1 then
                                r_count_row      <= 0;
                                r_update_counter <= '0';
                            else
                                r_count_row <= r_count_row + 1;
                            end if;
                        else
                            r_count_col <= r_count_col + 1;
                        end if;
                    else
                        r_mean_done_previous_state <= '0';
                        r_start_computation        <= '0';
                        o_variance_done            <= '1';
                    end if;

                    -- Compute variance for each channel
                    for c in 0 to CHANNEL_NUMBER - 1 loop
                        -- Compute (x_i - x_mean)
                        r_diff(c) <= std_logic_vector(signed(i_volume(c)(r_count_row)(r_count_col)) - signed(r_channel_mean(c)));

                        -- Compute r_squared += (x_i - x_mean)^2
                        r_squared(c) := std_logic_vector(signed(r_squared(c)) + signed(r_diff(c)) * signed(r_diff(c)));

                        -- Compute the scaled division
                        variance_division(c) := signed(r_squared(c)) * to_signed(VARIANCE_DIVISION_FACTOR, DIVISION_SCALE_FACTOR_POWER_OF_2);
                        variance_division(c) := SHIFT_RIGHT(variance_division(c), DIVISION_SCALE_FACTOR_POWER_OF_2);

                        -- Update the output
                        o_variance(c) <= std_logic_vector(resize(variance_division(c), 2 * BITWIDTH));
                    end loop;
                else
                    o_variance_done <= '0';
                end if;
            end if;
        end if;
    end process counter_control;
end variance_arch;

configuration variance_conf of variance is
    for variance_arch
        for all : mean
            use configuration LIB_RTL.mean_conf;
        end for;
    end for;
end configuration variance_conf;

configuration variance_pipelined_conf of variance is
    for variance_arch
        for all : mean
            use configuration LIB_RTL.mean_pipelined_conf;
        end for;
    end for;
end configuration variance_pipelined_conf;