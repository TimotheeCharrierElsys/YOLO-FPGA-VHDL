-----------------------------------------------------------------------------------
--!     @file       conv2d
--!     @brief      This entity implements a convolution using conv2d_layer units
--!     @details    This entity takes an input matrix volume and applies convolution
--!                 using multiple kernels, producing an output matrix.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity conv2d
--! This entity implements a convolution operation matching the one of the tensorflow conv2d function
entity conv2d is
    generic (
        --! Number of input channels
        DATA_SCALE_FACTOR : integer := 0; --! Define the general scale factor of the input data (e.g., 12 -> 2**12)
        BITWIDTH          : integer := 8; --! Bit width of each operand
        INPUT_SIZE        : integer := 3; --! Height and width of the input matrix
        KERNEL_SIZE       : integer := 3; --! Size of the kernel (assumes square kernel)
        INPUT_CHANNELS    : integer := 2; --! Number of channels in the input
        OUTPUT_CHANNELS   : integer := 1; --! Number of output channels (kernels)
        PADDING           : integer := 1; --! Padding value
        STRIDE            : integer := 1  --! Stride value
    );
    port (
        clock        : in std_logic;                                                                                                                      --! Clock signal
        reset_n      : in std_logic;                                                                                                                      --! Reset signal, active low
        i_sys_enable : in std_logic;                                                                                                                      --! Global enable signal, active high
        i_data       : in t_volume(0 to INPUT_CHANNELS - 1)(0 to INPUT_SIZE - 1)(0 to INPUT_SIZE - 1)(BITWIDTH - 1 downto 0);                             --! Input Data
        i_data_valid : in std_logic;                                                                                                                      --! Input Data Valid, pulse detected on Rising Edge
        i_kernel     : in t_tensor(0 to OUTPUT_CHANNELS - 1)(0 to INPUT_CHANNELS - 1)(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Input Kernels
        i_bias       : in t_vec(0 to OUTPUT_CHANNELS - 1)(2 * BITWIDTH - 1 downto 0);                                                                     --! Input Biases
        o_data_valid : out std_logic;                                                                                                                     --! Output Data Valid (pulse)
        o_data       : out t_volume(0 to OUTPUT_CHANNELS - 1)                                                                                             --! Output Data
        (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)
        (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)
        (2 * BITWIDTH - 1 downto 0)
    );
end entity conv2d;

architecture conv2d_arch of conv2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input_data   : t_volume(0 to INPUT_CHANNELS - 1)(0 to INPUT_PADDED_SIZE - 1)(0 to INPUT_PADDED_SIZE - 1)(BITWIDTH - 1 downto 0); --! Padded input data
    signal sliced_input_volume : t_volume(0 to INPUT_CHANNELS - 1)(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);             --! Sliced input volume
    signal conv2d_result       : t_vec(0 to OUTPUT_CHANNELS - 1)(2 * BITWIDTH - 1 downto 0);                                                       --! Conv2d result
    signal conv2d_start        : std_logic;                                                                                                        --! Signal to start convolution
    signal conv2d_layer_done   : std_logic;                                                                                                        --! Signal indicating convolution layer completion
    signal row_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                            --! Current row index
    signal col_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                            --! Current column index

    -- Counters for the mac architecture
    signal s_current_row     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current position within the kernel.
    signal s_current_col     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current position within the kernel.
    signal s_current_channel : integer range 0 to INPUT_CHANNELS;  --! Counter to track the current position within the channels.

    -- Control signals
    signal s_start       : std_logic;
    signal s_valid_d1    : std_logic; --! Delayed input valid signal
    signal s_valid_mac   : std_logic; --! Input valid signal for the MAC
    signal s_valid_adder : std_logic; --! Input valid signal for the adder
    signal s_valid_bn    : std_logic; --! Input valid signal for the bn
    signal s_clear_mac   : std_logic; --! Input clear signal for the MAC
    signal s_clear_adder : std_logic; --! Input clear signal for the adder

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            INPUT_CHANNELS    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(0 to INPUT_CHANNELS - 1)(0 to INPUT_PADDED_SIZE - 1)(0 to INPUT_PADDED_SIZE - 1)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(0 to INPUT_CHANNELS - 1)(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);
            o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
        );
    end component;

    component conv2d_control
        generic (
            KERNEL_SIZE    : integer;
            INPUT_CHANNELS : integer
        );
        port (
            clock             : in std_logic;
            reset_n           : in std_logic;
            i_sys_enable      : in std_logic;
            i_start           : in std_logic;
            i_current_row     : in integer range 0 to KERNEL_SIZE - 1;
            i_current_col     : in integer range 0 to KERNEL_SIZE - 1;
            i_current_channel : in integer range 0 to INPUT_CHANNELS;
            o_valid_mac       : out std_logic;
            o_valid_adder     : out std_logic;
            o_valid_bn        : out std_logic;
            o_clear_mac       : out std_logic;
            o_clear_adder     : out std_logic
        );
    end component;

    component conv2d_layer_mac
        generic (
            DATA_SCALE_FACTOR : integer;
            BITWIDTH          : integer;
            INPUT_CHANNELS    : integer;
            KERNEL_SIZE       : integer
        );
        port (
            clock           : in std_logic;
            reset_n         : in std_logic;
            i_sys_enable    : in std_logic;
            i_data_conv2d   : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernel_conv2d : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias_conv2d   : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            i_bias_bn       : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            i_mean_bn       : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            i_weight_bn     : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            i_valid_mac     : in std_logic;
            i_valid_adder   : in std_logic;
            i_valid_bn      : in std_logic;
            i_clear_mac     : in std_logic;
            i_clear_adder   : in std_logic;
            current_row     : in integer range 0 to KERNEL_SIZE - 1;
            current_col     : in integer range 0 to KERNEL_SIZE - 1;
            current_channel : in integer range 0 to INPUT_CHANNELS;
            o_result        : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, INPUT_CHANNELS, PADDING, BITWIDTH);
    end process comb_proc;

    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        INPUT_CHANNELS    => INPUT_CHANNELS,
        KERNEL_SIZE       => KERNEL_SIZE,
        PADDING           => PADDING,
        STRIDE            => STRIDE,
        OUTPUT_SIZE       => OUTPUT_SIZE
    )
    port map(
        clock                   => clock,
        reset_n                 => reset_n,
        i_sys_enable            => i_sys_enable,
        i_data                  => padded_input_data,
        i_data_valid            => i_data_valid,
        i_last_computation_done => conv2d_layer_done,
        o_data                  => sliced_input_volume,
        o_done                  => o_data_valid,
        o_computation_start     => conv2d_start,
        o_current_row           => row_index,
        o_current_col           => col_index
    );

    gen_conv2d_layers : for i in 0 to OUTPUT_CHANNELS - 1 generate
        conv2d_layer_mac_inst : conv2d_layer_mac
        generic map(
            DATA_SCALE_FACTOR => DATA_SCALE_FACTOR,
            BITWIDTH          => BITWIDTH,
            INPUT_CHANNELS    => INPUT_CHANNELS,
            KERNEL_SIZE       => KERNEL_SIZE
        )
        port map(
            clock           => clock,
            reset_n         => reset_n,
            i_sys_enable    => i_sys_enable,
            i_data_conv2d   => sliced_input_volume,
            i_kernel_conv2d => i_kernel(i),
            i_bias_conv2d   => i_bias_conv2d,
            i_bias_bn       => i_bias_bn,
            i_mean_bn       => i_mean_bn,
            i_weight_bn     => i_weight_bn,
            i_valid_mac     => i_valid_mac,
            i_valid_adder   => i_valid_adder,
            i_valid_bn      => i_valid_bn,
            i_clear_mac     => i_clear_mac,
            i_clear_adder   => i_clear_adder,
            current_row     => current_row,
            current_col     => current_col,
            current_channel => current_channel,
            o_result        => o_result
        );

    end generate gen_conv2d_layers;

    conv2d_control_inst : conv2d_control
    generic map(
        KERNEL_SIZE    => KERNEL_SIZE,
        INPUT_CHANNELS => INPUT_CHANNELS
    )
    port map(
        clock             => clock,
        reset_n           => reset_n,
        i_sys_enable      => i_sys_enable,
        i_start           => i_data_valid,
        i_current_row     => s_current_row,
        i_current_col     => s_current_col,
        i_current_channel => s_current_channel,
        o_valid_mac       => s_valid_mac,
        o_valid_adder     => s_valid_adder,
        o_valid_bn        => s_valid_bn,
        o_clear_mac       => s_clear_mac,
        o_clear_adder     => s_clear_adder
    );

    -------------------------------------------------------------------------------------
    -- PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            o_data_valid      <= '0';
            s_current_row     <= 0;
            s_current_col     <= 0;
            s_current_channel <= 0;

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                if s_valid_mac = '1' then
                    -- Process the MAC unit
                    if s_current_col = KERNEL_SIZE - 1 then
                        s_current_col <= 0;
                        if s_current_row = KERNEL_SIZE - 1 then
                            s_current_row <= 0;
                        else
                            s_current_row <= s_current_row + 1;
                        end if;
                    else
                        s_current_col <= s_current_col + 1;
                    end if;

                elsif s_valid_adder = '1' then

                    -- Process the adder
                    if s_current_channel = INPUT_CHANNELS then
                        s_current_channel <= 0;
                    else
                        s_current_channel <= s_current_channel + 1;
                    end if;

                elsif s_valid_bn then
                    o_data_valid <= '1';
                else
                    o_data_valid <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;