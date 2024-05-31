-----------------------------------------------------------------------------------
--!     @file       conv
--!     @brief      This entity implements a convolution using conv_layer units
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity conv
--! This entity implements a conv
entity conv is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        INPUT_SIZE     : integer := 5; --! Width and Height of the input
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the input
        KERNEL_SIZE    : integer := 3; --! Size of the kernel
        KERNEL_NUMBER  : integer := 1; --! Number of kernel
        PADDING        : integer := 1; --! Padding value
        STRIDE         : integer := 1  --! Stride value 
    );
    port (
        clock    : in std_logic;                                                                                                                                                             --! Clock signal
        reset_n  : in std_logic;                                                                                                                                                             --! Reset signal, active at low state
        i_enable : in std_logic;                                                                                                                                                             --! Enable signal, active at low state
        i_data   : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                                        --! Input data  (CHANNEL_NUMBER x (IMAGE_W x IMAGE_W x BITWIDTH) bits)
        i_kernel : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                   --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias   : in t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                                                                              --! Input bias value
        o_data   : out t_mat((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Output data
        o_valid  : out std_logic                                                                                                                                                             --! Output valid signal
    );
end conv;

architecture conv_arch of conv is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                   --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE - KERNEL_NUMBER)/STRIDE + 1;    --! Size of the output 
    constant STEP_SIZE         : integer := (INPUT_PADDED_SIZE - KERNEL_NUMBER)/STRIDE; --! Step size for the index

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input      : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Matrix volume with input padded on all channels
    signal sliced_volume     : t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);             --! Sliced volume for conv_layer input
    signal conv_layer_result : std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                                  --! Output result of the conv_layer
    signal conv_layer_valid  : std_logic;                                                                                                                    --! Output valid of the conv_layer
    signal r_count_row       : integer range 0 to INPUT_PADDED_SIZE - 1;                                                                                     --! Counter for the row index
    signal r_count_col       : integer range 0 to INPUT_PADDED_SIZE - 1;                                                                                     --! Counter for the col index

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            OUTPUT_SIZE    : integer
        );
        port (
            i_data            : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_row_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_row_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_col_index_start : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            i_col_index_end   : in std_logic_vector(INPUT_SIZE - 1 downto 0);
            o_data            : out t_volume(CHANNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
        );
    end component;

    component conv_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock     : in std_logic;
            reset_n   : in std_logic;
            i_enable  : in std_logic;
            i_data    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias    : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result  : out std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_valid   : out std_logic
        );
    end component;
begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    process (i_data)
    begin
        padded_input <= pad_input(i_data, INPUT_SIZE, CHANNEL_NUMBER, PADDING, BITWIDTH);
    end process;

    -------------------------------------------------------------------------------------
    -- Matrix volume slicer
    -------------------------------------------------------------------------------------
    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH       => BITWIDTH,
        INPUT_SIZE     => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER => CHANNEL_NUMBER,
        OUTPUT_SIZE    => OUTPUT_SIZE
    )
    port map(
        i_data            => padded_input,
        i_row_index_start => std_logic_vector(to_unsigned(r_count_row * STRIDE, INPUT_PADDED_SIZE)),
        i_row_index_end   => std_logic_vector(to_unsigned(r_count_row * STRIDE + KERNEL_SIZE - 1, INPUT_PADDED_SIZE)),
        i_col_index_start => std_logic_vector(to_unsigned(r_count_col * STRIDE, INPUT_PADDED_SIZE)),
        i_col_index_end   => std_logic_vector(to_unsigned(r_count_col * STRIDE + KERNEL_SIZE - 1, INPUT_PADDED_SIZE)),
        o_data            => sliced_volume
    );

    -------------------------------------------------------------------------------------
    -- CONV_LAYER INSTANTIATION
    -------------------------------------------------------------------------------------
    gen_conv_layers : for i in 0 to KERNEL_NUMBER - 1 generate
        conv_layer_inst : conv_layer
        generic map(
            BITWIDTH       => BITWIDTH,
            CHANNEL_NUMBER => CHANNEL_NUMBER,
            KERNEL_SIZE    => KERNEL_SIZE
        )
        port map(
            clock     => clock,
            reset_n   => reset_n,
            i_enable  => i_enable,
            i_data    => sliced_volume,
            i_kernels => i_kernel(i),
            i_bias    => i_bias(i),
            o_result  => conv_layer_result,
            o_valid   => conv_layer_valid
        );
    end generate gen_conv_layers;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register, counters, and selector to initial states.
            r_count_row <= 0;
            r_count_col <= 0;
            o_valid     <= '0';
            o_data      <= (others => (others => (others => '0')));

        elsif rising_edge(clock) then
            if i_enable = '1' then
                if (conv_layer_valid = '1') then
                    o_data(OUTPUT_SIZE - 1 - r_count_row)(OUTPUT_SIZE - 1 - r_count_col) <= conv_layer_result;
                    if r_count_col = STEP_SIZE - 2 then
                        r_count_col <= 0;
                        o_valid     <= '0';
                        if r_count_row = STEP_SIZE - 2 then
                            r_count_row <= 0;
                            o_valid     <= '1';
                        else
                            r_count_row <= r_count_row + 1;
                        end if;
                    else
                        r_count_col <= r_count_col + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;

configuration conv_conf of conv is
    for conv_arch

        for gen_conv_layers
            for conv_layer_inst : conv_layer
                use configuration LIB_RTL.conv_layer_fc_conf;
            end for;
        end for;

        for all : volume_slice
            use configuration LIB_RTL.volume_slice_conf;
        end for;
    end for;
end configuration conv_conf;