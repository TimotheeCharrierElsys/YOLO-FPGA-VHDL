-----------------------------------------------------------------------------------
--!     @file       window_slice
--!     @brief      This file provides a window slicing entity
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity window_slice
--! This entity takes an input matrix and slices a window from it based on the specified row and column indices.
--! It outputs the sliced window as a separate matrix.
--! The size of the input and output matrices, as well as the bit width of each element, are configurable.
entity window_slice is
    generic (
        BITWIDTH    : integer := 8; --! Bit width of each operand
        INPUT_SIZE  : integer := 5; --! Input size
        OUTPUT_SIZE : integer := 3  --! Output size
    );
    port (
        i_data            : in t_mat(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);   --! Input matrix
        i_row_index_start : in std_logic_vector(BITWIDTH - 1 downto 0);                                          --! First dimension (row) starting index
        i_row_index_end   : in std_logic_vector(BITWIDTH - 1 downto 0);                                          --! First dimension (row) ending index
        i_col_index_start : in std_logic_vector(BITWIDTH - 1 downto 0);                                          --! Second dimension (col) starting index
        i_col_index_end   : in std_logic_vector(BITWIDTH - 1 downto 0);                                          --! Second dimension (col) ending index
        o_data            : out t_mat(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) --! Output sliced matrix
    );
end window_slice;

architecture window_slice_arch of window_slice is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal row_index_start : integer range 0 to INPUT_SIZE; --! Signal for integer row starting index
    signal row_index_stop  : integer range 0 to INPUT_SIZE; --! Signal for integer row ending index
    signal col_index_start : integer range 0 to INPUT_SIZE; --! Signal for integer col starting index
    signal col_index_stop  : integer range 0 to INPUT_SIZE; --! Signal for integer col ending index

begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS
    -------------------------------------------------------------------------------------
    -- Convert the std_logic_vector indices to integers
    process (i_row_index_start, i_row_index_end, i_col_index_start, i_col_index_end)
    begin
        row_index_start <= to_integer(unsigned(i_row_index_start));
        row_index_stop  <= to_integer(unsigned(i_row_index_end));
        col_index_start <= to_integer(unsigned(i_col_index_start));
        col_index_stop  <= to_integer(unsigned(i_col_index_end));
    end process;

    -- Slice the window from the input matrix
    comb_proc : process (row_index_start, row_index_stop, col_index_start, col_index_stop, i_data)
    begin
        -- Assign the sliced window to the output matrix
        for i in 0 to OUTPUT_SIZE - 1 loop
            for j in 0 to OUTPUT_SIZE - 1 loop
                -- Check indices are within valid range
                if row_index_start + i <= row_index_stop and row_index_start + i < INPUT_SIZE and
                    col_index_start + j    <= col_index_stop and col_index_start + j < INPUT_SIZE then
                    o_data(i)(j)           <= i_data(row_index_start + i)(col_index_start + j);
                else
                    o_data(i)(j) <= (others => '0');
                end if;
            end loop;
        end loop;
    end process comb_proc;

end window_slice_arch;