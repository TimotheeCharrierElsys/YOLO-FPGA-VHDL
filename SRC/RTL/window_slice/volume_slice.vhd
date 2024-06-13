-----------------------------------------------------------------------------------
--! @file       volume_slice
--! @brief      This file provides a volume slicing entity
--! @details    This entity takes an input matrix volume and slices a window 
--!             for each channel from it based on the specified row and column indices.
--!             It outputs the sliced window as a separate volume matrix.
--! @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity volume_slice
--! This entity takes an input matrix volume and slices a window for each channel from it based on the specified row and column indices.
--! It outputs the sliced window as a separate volume matrix.
entity volume_slice is
    generic (
        BITWIDTH          : integer := 8; --! Bit width of each operand
        INPUT_PADDED_SIZE : integer := 7; --! Width and Height of the input
        CHANNEL_NUMBER    : integer := 3; --! Number of channels in the input
        KERNEL_SIZE       : integer := 3; --! Size of the kernel
        PADDING           : integer := 1; --! Padding value
        STRIDE            : integer := 2; --! Stride value 
        OUTPUT_SIZE       : integer := 3  --! Output size of the global volume
    );
    port (
        clock                   : in std_logic;                                                                                                                    --! Clock signal
        reset_n                 : in std_logic;                                                                                                                    --! Reset signal, active at low state
        i_sys_enable            : in std_logic;                                                                                                                    --! System enable signal, active at high state
        i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input matrix volume
        i_data_valid            : in std_logic;                                                                                                                    --! Input valid signal
        i_last_computation_done : in std_logic;                                                                                                                    --! Feedback signal for last computation done
        o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);            --! Output sliced matrix volume
        o_done                  : out std_logic;                                                                                                                   --! Output valid signal
        o_computation_start     : out std_logic;                                                                                                                   --! Signal to start the next computation
        o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                       --! Current row index
        o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)                                                        --! Current column index
    );
end volume_slice;

architecture volume_slice_arch of volume_slice is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal current_row               : integer range 0 to OUTPUT_SIZE - 1 := 0;                                                                          --! Current row counter for slicing
    signal current_col               : integer range 0 to OUTPUT_SIZE - 1 := 0;                                                                          --! Current column counter for slicing
    signal start_processing          : std_logic                          := '0';                                                                        --! Signal to start processing
    signal data_valid_previous_state : std_logic                          := '0';                                                                        --! Previous state of the data_valid signal
    signal sliced_output_data        : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Buffer for output data

begin

    -------------------------------------------------------------------------------------
    -- SUB-MATRIX SELECTION
    -------------------------------------------------------------------------------------
    gen_window_slice : for i in 0 to CHANNEL_NUMBER - 1 generate
        process (i_data, current_row, current_col)
        begin
            for row in 0 to KERNEL_SIZE - 1 loop
                for col in 0 to KERNEL_SIZE - 1 loop
                    sliced_output_data(i)(row)(col) <= i_data(i)(current_row + (KERNEL_SIZE - 1) - row)(current_col + (KERNEL_SIZE - 1) - col);
                end loop;
            end loop;
        end process;
    end generate gen_window_slice;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    state_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register, counters, and selector to initial states.
            current_row               <= 0;
            current_col               <= 0;
            start_processing          <= '0';
            data_valid_previous_state <= '0';
            o_done                    <= '0';
            o_computation_start       <= '0';

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                -- Update last data_valid signal
                data_valid_previous_state <= i_data_valid;

                -- Output update
                o_data <= sliced_output_data;

                -- Check if input data is valid
                if (start_processing = '0' and i_data_valid = '1' and data_valid_previous_state = '0') then
                    start_processing    <= '1';
                    o_computation_start <= '1';
                else
                    o_done              <= '0';
                    o_computation_start <= '0';
                end if;

                -- If input data is valid, start the index computation
                if (start_processing = '1') then

                    -- Start next computation
                    if (i_last_computation_done = '1') then

                        -- Boundaries limit
                        if (current_row = OUTPUT_SIZE - 1 and current_col = OUTPUT_SIZE - 1) then
                            o_computation_start <= '0';
                        else
                            o_computation_start <= '1';
                        end if;

                        -- Update the new index
                        if current_col = OUTPUT_SIZE - 1 then
                            current_col <= 0;
                            if current_row = OUTPUT_SIZE - 1 then
                                current_row      <= 0;
                                o_done           <= '1';
                                start_processing <= '0';
                            else
                                current_row <= current_row + 1;
                            end if;
                        else
                            current_col <= current_col + 1;
                        end if;
                    else
                        o_computation_start <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process state_control;

    -- Output signals update for control
    o_current_row <= std_logic_vector(to_unsigned(current_row, integer(ceil(log2(real(OUTPUT_SIZE))))));
    o_current_col <= std_logic_vector(to_unsigned(current_col, integer(ceil(log2(real(OUTPUT_SIZE))))));

end volume_slice_arch;