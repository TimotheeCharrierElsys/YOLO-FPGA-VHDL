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

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity volume_slice
--! This entity takes an input matrix volume and slices a window for each channel from it based on the specified row and column indices.
--! It outputs the sliced window as a separate volume matrix.
entity volume_slice is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        INPUT_SIZE     : integer := 5; --! Input size
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the image
        KERNEL_SIZE    : integer := 3; --! Kernel size
        STRIDE         : integer := 1; --! Stride value
        OUTPUT_SIZE    : integer := 3  --! Output size
    );
    port (
        clock                   : in std_logic;                                                                                                         --! Clock signal
        reset_n                 : in std_logic;                                                                                                         --! Reset signal, active at low state
        i_sys_enable            : in std_logic;                                                                                                         --! System enable signal, active at high state
        i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);    --! Input matrix volume
        i_data_valid            : in std_logic;                                                                                                         --! Input valid signal
        i_last_computation_done : in std_logic;                                                                                                         --! Feedback signal for last computation done
        o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Output sliced matrix volume
        o_done                  : out std_logic;                                                                                                        --! Output valid signal
        o_computation_start     : out std_logic;                                                                                                        --! Signal to start the next computation
        o_current_row           : out std_logic_vector(KERNEL_SIZE - 1 downto 0);                                                                       --! Current row index
        o_current_col           : out std_logic_vector(KERNEL_SIZE - 1 downto 0)                                                                        --! Current column index
    );
end volume_slice;

architecture volume_slice_arch of volume_slice is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant STEP_SIZE : integer := (INPUT_SIZE - KERNEL_SIZE)/STRIDE; --! Index step size 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal current_row               : integer range 0 to INPUT_SIZE - 1;                                                                                --! Current row counter for slicing
    signal current_col               : integer range 0 to INPUT_SIZE - 1;                                                                                --! Current column counter for slicing
    signal start_processing          : std_logic;                                                                                                        --! Signal to start processing
    signal data_valid_previous_state : std_logic;                                                                                                        --! Previous state of the data_valid signal
    signal sliced_output_data        : t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Buffer for output data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component window_slice
        generic (
            BITWIDTH    : integer;
            INPUT_SIZE  : integer;
            OUTPUT_SIZE : integer
        );
        port (
            i_data            : in t_mat(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_row_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_row_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_col_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_col_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            o_data            : out t_mat(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE THE SLICED WINDOWS
    -------------------------------------------------------------------------------------
    gen_window_slice : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the window_slice units for each channel.
        window_slice_inst : window_slice
        generic map(
            BITWIDTH    => BITWIDTH,
            INPUT_SIZE  => INPUT_SIZE,
            OUTPUT_SIZE => OUTPUT_SIZE
        )
        port map(
            i_data            => i_data(i),
            i_row_index_start => std_logic_vector(to_unsigned(current_row * STRIDE, INPUT_SIZE)),
            i_row_index_end   => std_logic_vector(to_unsigned(current_row * STRIDE + KERNEL_SIZE - 1, INPUT_SIZE)),
            i_col_index_start => std_logic_vector(to_unsigned(current_col * STRIDE, INPUT_SIZE)),
            i_col_index_end   => std_logic_vector(to_unsigned(current_col * STRIDE + KERNEL_SIZE - 1, INPUT_SIZE)),
            o_data            => sliced_output_data(i)
        );
    end generate gen_window_slice;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    process (clock, reset_n)
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
                        if (current_row = KERNEL_SIZE - 1 and current_col = KERNEL_SIZE - 1) then
                            o_computation_start <= '0';
                        else
                            o_computation_start <= '1';
                        end if;

                        -- Update the new index
                        if current_col = KERNEL_SIZE - 1 then
                            current_col <= 0;
                            if current_row = KERNEL_SIZE - 1 then
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
    end process;

    -- Output signals update for debugging and control
    o_current_row <= std_logic_vector(to_unsigned(current_row, KERNEL_SIZE));
    o_current_col <= std_logic_vector(to_unsigned(current_col, KERNEL_SIZE));

end volume_slice_arch;

configuration volume_slice_conf of volume_slice is
    for volume_slice_arch
        for gen_window_slice
            for all : window_slice
                use entity LIB_RTL.window_slice(window_slice_arch);
            end for;
        end for;
    end for;
end configuration volume_slice_conf;