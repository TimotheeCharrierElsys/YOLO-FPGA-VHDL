-----------------------------------------------------------------------------------
--!     @file       conv_layer
--!     @brief      This entity implements a convolution layer using three different architectures.
--!                 It performs conv_layer operations.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity conv_layer
--! This entity implements a convolution layer using a pipelined MAC unit with a 3x3 kernel.
entity conv_layer is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the image
        KERNEL_SIZE    : integer := 3  --! Size of the kernel (e.g., 3 for a 3x3 kernel)
    );
    port (
        clock        : in std_logic;                                                                                                        --! Clock signal
        reset_n      : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                                                                                        --! Enable signal, active at high state
        i_valid      : in std_logic;                                                                                                        --! Valid signal, one clock cyle active high state
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);                                                                          --! Input bias value
        o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                     --! Output value
        o_valid      : out std_logic                                                                                                        --! Output valid signal
    );
end conv_layer;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using fully
--!                     connected layer.
--!     @Dependencies:  adder_tree.vhd, fc_layer.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_fc_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant N_ADDITION_REG        : integer := 1;                                 --! Number of addition registers.
    constant N_OUTPUT_REG          : integer := 1;                                 --! Number of output registers.
    constant DFF_DELAY_UNPIPELINED : integer := N_ADDITION_REG + N_OUTPUT_REG + 1; --! Total delay when not pipelined

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_results : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel. Add the bias to the vector.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer; --! Bitwidth of the input and output data.
            MATRIX_SIZE : integer  --! Size of the input matrices.
        );
        port (
            clock        : in std_logic;                                                                        --! Clock signal.
            reset_n      : in std_logic;                                                                        --! Reset signal, active at low state.
            i_sys_enable : in std_logic;                                                                        --! Enable signal, active at high state.
            i_matrix1    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix.
            i_matrix2    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix.
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                      --! Output matrix dot product.
        );
    end component;

    component pipeline
        generic (
            N_STAGES : integer --! Number of pipeline stages
        );
        port (
            clock        : in std_logic; --! Clock signal
            reset_n      : in std_logic; --! Reset signal, active low
            i_sys_enable : in std_logic; --! Global enable signal, active high
            i_data       : in std_logic; --! Input data
            o_data       : out std_logic --! Output data
        );
    end component;

    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    gen_fc : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the fc_layer units for each channel.
        gen_fc_layer : fc_layer
        generic map(
            BITWIDTH    => BITWIDTH,
            MATRIX_SIZE => KERNEL_SIZE
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_matrix1    => i_data(i),
            i_matrix2    => i_kernels(i),
            o_result     => r_results(i)
        );
    end generate gen_fc;

    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY_UNPIPELINED
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_valid,
        o_data       => o_valid
    );

    adder_tree_inst : adder_tree
    generic map(
        N_OPD    => CHANNEL_NUMBER + 1,
        BITWIDTH => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => r_results,
        o_data       => o_result
    );

    -- Add bias to r_result last position
    r_results(CHANNEL_NUMBER) <= std_logic_vector(resize(signed(i_bias), 2 * BITWIDTH));

end conv_layer_fc_arch;

configuration conv_layer_fc_conf of conv_layer is
    for conv_layer_fc_arch
        for gen_fc
            for all : fc_layer
                use configuration LIB_RTL.fc_layer_conf;
            end for;
        end for;
    end for;
end configuration conv_layer_fc_conf;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using fully
--!                     connected layer.
--!     @Dependencies:  adder_tree.vhd, fc_layer.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_fc_pipelined_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant N_STAGES            : integer := integer(ceil(log2(real(KERNEL_SIZE * KERNEL_SIZE)))); --! Number of stages required to complete the addition process.
    constant N_ADDITION_REG      : integer := 1;                                                    --! Number of addition registers.
    constant N_OUTPUT_REG        : integer := 1;                                                    --! Number of output registers.
    constant DFF_DELAY_PIPELINED : integer := N_STAGES + N_ADDITION_REG + N_OUTPUT_REG + 1;         --! Total delay due to flip-flops when pipelined.

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_results : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel. Add the bias to the vector.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer; --! Bitwidth of the input and output data.
            MATRIX_SIZE : integer  --! Size of the input matrices.
        );
        port (
            clock        : in std_logic;                                                                        --! Clock signal.
            reset_n      : in std_logic;                                                                        --! Reset signal, active at low state.
            i_sys_enable : in std_logic;                                                                        --! Enable signal, active at high state.
            i_matrix1    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix.
            i_matrix2    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix.
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                      --! Output matrix dot product.
        );
    end component;

    component pipeline
        generic (
            N_STAGES : integer --! Number of pipeline stages
        );
        port (
            clock        : in std_logic; --! Clock signal
            reset_n      : in std_logic; --! Reset signal, active low
            i_sys_enable : in std_logic; --! Global enable signal, active high
            i_data       : in std_logic; --! Input data
            o_data       : out std_logic --! Output data
        );
    end component;

    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin
    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    gen_fc : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the fc_layer units for each channel.
        gen_fc_layer : fc_layer
        generic map(
            BITWIDTH    => BITWIDTH,
            MATRIX_SIZE => KERNEL_SIZE
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_matrix1    => i_data(i),
            i_matrix2    => i_kernels(i),
            o_result     => r_results(i)
        );
    end generate gen_fc;

    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY_PIPELINED
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_valid,
        o_data       => o_valid
    );

    adder_tree_inst : adder_tree
    generic map(
        N_OPD    => CHANNEL_NUMBER + 1,
        BITWIDTH => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => r_results,
        o_data       => o_result
    );

    -- Add bias to r_result last position
    r_results(CHANNEL_NUMBER) <= std_logic_vector(resize(signed(i_bias), 2 * BITWIDTH));

end conv_layer_fc_pipelined_arch;

configuration conv_layer_fc_pipelined_conf of conv_layer is
    for conv_layer_fc_pipelined_arch
        for gen_fc
            for all : fc_layer
                use configuration LIB_RTL.fc_layer_pipelined_conf;
            end for;
        end for;
    end for;
end configuration conv_layer_fc_pipelined_conf;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using one
--!                     mac per channel.
--!     @Dependencies:  mac.vhd, accumulative_mac.vhd, pipeline.vhd, adder_tree.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_one_mac_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    constant N_OUTPUT_REG : integer := 1;                                            --! Number of output registers.
    constant DFF_DELAY    : integer := KERNEL_SIZE * KERNEL_SIZE + N_OUTPUT_REG + 1; --! Total delay due to flip-flops and computation (+1 for clear)

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_results   : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal r_count_row : integer range 0 to KERNEL_SIZE - 1;                        --! Counter to track the current position within the kernel.
    signal r_count_col : integer range 0 to KERNEL_SIZE - 1;                        --! Counter to track the current position within the kernel.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component accumulative_mac
        generic (
            BITWIDTH : integer
        );
        port (
            clock         : in std_logic;
            reset_n       : in std_logic;
            i_sys_enable  : in std_logic;
            i_clear       : in std_logic;
            i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
        );
    end component;

    component pipeline
        generic (
            N_STAGES : integer --! Number of pipeline stages
        );
        port (
            clock        : in std_logic; --! Clock signal
            reset_n      : in std_logic; --! Reset signal, active low
            i_sys_enable : in std_logic; --! Global enable signal, active high
            i_data       : in std_logic; --! Input data
            o_data       : out std_logic --! Output data
        );
    end component;

    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_vec(N_OPD - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK FOR MAC UNITS
    -------------------------------------------------------------------------------------
    gen_mac_channel : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate one accumualtive mac for each channel
        gen_accumulative_mac_inst : accumulative_mac
        generic map(
            BITWIDTH => BITWIDTH
        )
        port map(
            clock         => clock,
            reset_n       => reset_n,
            i_sys_enable  => i_sys_enable,
            i_clear       => i_valid,
            i_multiplier1 => i_data(i)(r_count_row)(r_count_col),
            i_multiplier2 => i_kernels(i)(r_count_row)(r_count_col),
            o_result      => r_results(i)
        );

    end generate gen_mac_channel;

    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_valid,
        o_data       => o_valid
    );

    adder_tree_inst : adder_tree
    generic map(
        N_OPD    => CHANNEL_NUMBER + 1,
        BITWIDTH => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => r_results,
        o_data       => o_result
    );

    -- Add bias to r_result last position
    r_results(CHANNEL_NUMBER) <= std_logic_vector(resize(signed(i_bias), 2 * BITWIDTH));

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    counter_control : process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            -- Reset counters  to initial states.
            r_count_row <= 0;
            r_count_col <= 0;

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                -- Update counter signals.
                if r_count_col = KERNEL_SIZE - 1 then
                    r_count_col <= 0;
                    if r_count_row = KERNEL_SIZE - 1 then
                        r_count_row <= 0;
                    else
                        r_count_row <= r_count_row + 1;
                    end if;
                else
                    r_count_col <= r_count_col + 1;
                end if;
            end if;
        end if;
    end process counter_control;
end conv_layer_one_mac_arch;

configuration conv_layer_one_mac_conf of conv_layer is
    for conv_layer_one_mac_arch
        for gen_mac_channel

            for all : accumulative_mac
                use entity LIB_RTL.accumulative_mac(accumulative_mac_arch);
            end for;

        end for;
    end for;
end configuration conv_layer_one_mac_conf;