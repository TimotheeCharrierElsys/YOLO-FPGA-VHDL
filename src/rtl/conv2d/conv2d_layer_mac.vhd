-----------------------------------------------------------------------------------
--!     @file       conv2d_layer_mac
--!     @brief      This entity implements a convolution layer using the mac architecture.
--!                 It performs conv2d_layer_mac operations.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity conv2d_layer_mac
--! This entity implements a convolution layer using a pipelined MAC unit with a 3x3 kernel.
entity conv2d_layer_mac is
    generic (
        DATA_SCALE_FACTOR : integer := 12; --! Input data scale factor. For example, a value of 12 means input values are scaled by 2^12.
        BITWIDTH          : integer := 8;  --! Bit width of each operand
        INPUT_CHANNELS    : integer := 3;  --! Number of input channels
        KERNEL_SIZE       : integer := 3   --! Size of the kernel (e.g., 3 for a 3x3 kernel)
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active at low state
        i_sys_enable : in std_logic; --! Enable signal, active at high state

        -- Conv2d
        i_data_conv2d   : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (INPUT_CHANNELS x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_kernel_conv2d : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (INPUT_CHANNELS x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias_conv2d   : in std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                      --! Input bias value for the conv2d

        -- Batchnormn2d and SiLU
        i_bias_bn   : in std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Input bias value for the bn
        i_mean_bn   : in std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Input mean value for the bn
        i_weight_bn : in std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Input weight value for the bn

        -- Control Signals
        i_valid_mac     : in std_logic;                          --! Input valid signal for the MAC
        i_valid_adder   : in std_logic;                          --! Input valid signal for the adder
        i_valid_bn      : in std_logic;                          --! Input valid signal for the bn
        i_clear_mac     : in std_logic;                          --! Input clear signal for the MAC
        i_clear_adder   : in std_logic;                          --! Input clear signal for the adder
        current_row     : in integer range 0 to KERNEL_SIZE - 1; --! Current row index
        current_col     : in integer range 0 to KERNEL_SIZE - 1; --! Current column index
        current_channel : in integer range 0 to INPUT_CHANNELS;  --! Current channel index

        -- Output Result
        o_result : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output value
    );
end conv2d_layer_mac;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using one
--!                     mac per channel.
--!     @Dependencies:  mac.vhd, mac.vhd, pipeline.vhd, adder_tree.vhd
-----------------------------------------------------------------------------------
architecture conv2d_layer_mac_arch of conv2d_layer_mac is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    -- Intermediate signals
    signal conv2d_result            : std_logic_vector(2 * BITWIDTH - 1 downto 0);
    signal r_results                : t_vec(INPUT_CHANNELS downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal intermediate_multiplier1 : t_vec(INPUT_CHANNELS - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal to avoid static 
    signal intermediate_multiplier2 : t_vec(INPUT_CHANNELS - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal
    signal intermediate_result      : std_logic_vector(2 * BITWIDTH - 1 downto 0);               --! Intermediate signal for output result sum

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac
        generic (
            DO_MULTIPLICATION : std_logic;
            INPUT_WIDTH       : integer;
            OUTPUT_WIDTH      : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_valid      : in std_logic;
            i_clear      : in std_logic;
            i_operand1   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
            i_operand2   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
            o_result     : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
        );
    end component;

    component batchnorm2d_layer
        generic (
            BITWIDTH          : integer;
            DATA_SCALE_FACTOR : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_mean       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_weight     : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_valid      : in std_logic;
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;
begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK FOR MAC UNITS
    -------------------------------------------------------------------------------------
    gen_mac_channel : for i in 0 to INPUT_CHANNELS - 1 generate
        --! Instantiate one accumulative mac for each channel
        gen_mac_inst : mac
        generic map(
            DO_MULTIPLICATION => '1',
            INPUT_WIDTH       => BITWIDTH,
            OUTPUT_WIDTH      => 2 * BITWIDTH
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_valid      => i_valid_mac,
            i_clear      => i_clear_mac,
            i_operand1   => intermediate_multiplier1(i),
            i_operand2   => intermediate_multiplier2(i),
            o_result     => r_results(i)
        );
    end generate gen_mac_channel;

    --! Instantiate one accumulative adder for computing the output sum
    gen_output_sum : mac
    generic map(
        DO_MULTIPLICATION => '0',
        INPUT_WIDTH       => 2 * BITWIDTH,
        OUTPUT_WIDTH      => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_valid      => i_valid_adder,
        i_clear      => i_clear_adder,
        i_operand1   => intermediate_result,
        i_operand2 => (others => '0'),
        o_result     => conv2d_result
    );

    batchnorm2d_layer_inst : batchnorm2d_layer
    generic map(
        BITWIDTH          => 2 * BITWIDTH,
        DATA_SCALE_FACTOR => DATA_SCALE_FACTOR
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => conv2d_result,
        i_mean       => i_mean_bn,
        i_weight     => i_weight_bn,
        i_bias       => i_bias_bn,
        i_valid      => i_valid_bn,
        o_data       => o_result
    );

    -------------------------------------------------------------------------------------
    -- ASSIGNMENTS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the assignment of the input data to the intermediate signals.
    process (all)
    begin
        r_results(INPUT_CHANNELS) <= std_logic_vector(shift_left(signed(i_bias_conv2d), DATA_SCALE_FACTOR));               --! Initialize the output with the bias value
        intermediate_result       <= std_logic_vector(shift_right(signed(r_results(current_channel)), DATA_SCALE_FACTOR)); --! Intermediate signal to hold the output of each MAC unit for each channel.
        for i in 0 to INPUT_CHANNELS - 1 loop
            intermediate_multiplier1(i) <= i_data_conv2d(i)(current_col)(current_row);
            intermediate_multiplier2(i) <= i_kernel_conv2d(i)(current_col)(current_row);
        end loop;
    end process;
end conv2d_layer_mac_arch;

configuration conv2d_layer_mac_conf of conv2d_layer_mac is

    for conv2d_layer_mac_arch
        for gen_mac_channel
            for all : mac
                use entity LIB_RTL.mac(mac_arch);
            end for;
        end for;

        for all : mac
            use entity LIB_RTL.mac(mac_arch);
        end for;

        for all : batchnorm2d_layer
            use entity LIB_RTL.batchnorm2d_layer(batchnorm2d_layer_arch);
        end for;
    end for;

end configuration conv2d_layer_mac_conf;