-----------------------------------------------------------------------------------
--!     @file       volume_slice
--!     @brief      This file provides a volume slicing entity
--!     @author     Timothée Charrier
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
        OUTPUT_SIZE    : integer := 3  --! Output size
    );
    port (
        i_data            : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);   --! Input matrix volume
        i_row_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! First dimension (row) starting index
        i_row_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! First dimension (row) ending index
        i_col_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! Second dimension (col) starting index
        i_col_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! Second dimension (col) ending index
        o_data            : out t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) --! Output sliced matrix volume
    );
end volume_slice;

architecture volume_slice_arch of volume_slice is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal row_index_start : integer range 0 to INPUT_SIZE - 1; --! Signal for integer row starting index
    signal row_index_stop  : integer range 0 to INPUT_SIZE - 1; --! Signal for integer row ending index
    signal col_index_start : integer range 0 to INPUT_SIZE - 1; --! Signal for integer col starting index
    signal col_index_stop  : integer range 0 to INPUT_SIZE - 1; --! Signal for integer col ending index

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
            i_row_index_start => i_row_index_start,
            i_row_index_end   => i_row_index_end,
            i_col_index_start => i_col_index_start,
            i_col_index_end   => i_col_index_end,
            o_data            => o_data(i)
        );

    end generate gen_window_slice;
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