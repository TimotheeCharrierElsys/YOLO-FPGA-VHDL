-----------------------------------------------------------------------------------
--!     @Testbench    volume_slice_tb
--!     @brief        This testbench verifies the functionality of the volume_slice
--!     @details      It initializes the inputs, applies test vectors, and checks the outputs.
--!     @auth         Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

entity volume_slice_tb is
end entity;

architecture volume_slice_tb_arch of volume_slice_tb is
    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant i_clk_period   : time    := 10 ns; --! Clock period
    constant WAIT_COUNT     : integer := 5;
    constant BITWIDTH       : integer := 8;
    constant INPUT_SIZE     : integer := 5;
    constant CHANNEL_NUMBER : integer := 3;
    constant OUTPUT_SIZE    : integer := 3;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal i_data            : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
    signal i_row_index_start : std_logic_vector(INPUT_SIZE - 1 downto 0) := std_logic_vector(to_unsigned(1, INPUT_SIZE));
    signal i_row_index_end   : std_logic_vector(INPUT_SIZE - 1 downto 0) := std_logic_vector(to_unsigned(3, INPUT_SIZE));
    signal i_col_index_start : std_logic_vector(INPUT_SIZE - 1 downto 0) := std_logic_vector(to_unsigned(1, INPUT_SIZE));
    signal i_col_index_end   : std_logic_vector(INPUT_SIZE - 1 downto 0) := std_logic_vector(to_unsigned(3, INPUT_SIZE));
    signal o_data            : t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH       : integer := 8; --! Bit width of each operand
            INPUT_SIZE     : integer := 5; --! Input size
            CHANNEL_NUMBER : integer := 3; --! Number of channels in the image
            OUTPUT_SIZE    : integer := 3  --! Output size
        );
        port (
            i_data            : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);   --! Input matrix
            i_row_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! First dimension (row) starting index
            i_row_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! First dimension (row) ending index
            i_col_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! Second dimension (col) starting index
            i_col_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);                                                                        --! Second dimension (col) ending index
            o_data            : out t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0) --! Output sliced matrix
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- UNIT UNDER TEST (UUT)
    -------------------------------------------------------------------------------------
    UUT : volume_slice
    generic map(
        BITWIDTH    => BITWIDTH,
        INPUT_SIZE  => INPUT_SIZE,
        OUTPUT_SIZE => OUTPUT_SIZE
    )
    port map(
        i_data            => i_data,
        i_row_index_start => i_row_index_start,
        i_row_index_end   => i_row_index_end,
        i_col_index_start => i_col_index_start,
        i_col_index_end   => i_col_index_end,
        o_data            => o_data
    );

    i_data(0) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(1, BITWIDTH)), std_logic_vector(to_signed(2, BITWIDTH)), std_logic_vector(to_signed(3, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(4, BITWIDTH)), std_logic_vector(to_signed(5, BITWIDTH)), std_logic_vector(to_signed(6, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(7, BITWIDTH)), std_logic_vector(to_signed(8, BITWIDTH)), std_logic_vector(to_signed(9, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

    i_data(1) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-1, BITWIDTH)), std_logic_vector(to_signed(-2, BITWIDTH)), std_logic_vector(to_signed(-3, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-4, BITWIDTH)), std_logic_vector(to_signed(-5, BITWIDTH)), std_logic_vector(to_signed(-6, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(-7, BITWIDTH)), std_logic_vector(to_signed(-8, BITWIDTH)), std_logic_vector(to_signed(-9, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

    i_data(2) <= (
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(10, BITWIDTH)), std_logic_vector(to_signed(11, BITWIDTH)), std_logic_vector(to_signed(12, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(13, BITWIDTH)), std_logic_vector(to_signed(14, BITWIDTH)), std_logic_vector(to_signed(15, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(16, BITWIDTH)), std_logic_vector(to_signed(17, BITWIDTH)), std_logic_vector(to_signed(18, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH))),
    (std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)), std_logic_vector(to_signed(0, BITWIDTH)))
    );

end architecture;

configuration volume_slice_tb_conf of volume_slice_tb is
    for volume_slice_tb_arch
        for UUT : volume_slice
            use configuration LIB_RTL.volume_slice_conf;
        end for;
    end for;
end configuration volume_slice_tb_conf;