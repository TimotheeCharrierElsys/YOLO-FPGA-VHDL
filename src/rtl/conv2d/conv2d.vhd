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
        DATA_SCALE_FACTOR : integer   := 0;   --! Define the general scale factor of the input data (e.g., 12 -> 2**12)
        USE_MAC_ARCH      : std_logic := '1'; --! Define if the design is using MAC ('1') or adder ('0')
        DO_PIPELINE       : std_logic := '1'; --! Define if the design is pipelined ('1') or not ('0')
        BITWIDTH          : integer   := 8;   --! Bit width of each operand
        INPUT_SIZE        : integer   := 3;   --! Height and width of the input matrix
        KERNEL_SIZE       : integer   := 3;   --! Size of the kernel (assumes square kernel)
        INPUT_CHANNELS    : integer   := 2;   --! Number of channels in the input
        OUTPUT_CHANNELS   : integer   := 1;   --! Number of output channels (kernels)
        PADDING           : integer   := 1;   --! Padding value
        STRIDE            : integer   := 1    --! Stride value
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic;
        i_data       : in t_volume(0 to INPUT_CHANNELS - 1)(0 to INPUT_SIZE - 1)(0 to INPUT_SIZE - 1)(BITWIDTH - 1 downto 0);
        i_data_valid : in std_logic;
        i_kernel     : in t_tensor(0 to OUTPUT_CHANNELS - 1)(0 to INPUT_CHANNELS - 1)(0 to KERNEL_SIZE - 1)(0 to KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0);
        i_bias       : in t_vec(0 to OUTPUT_CHANNELS - 1)(2 * BITWIDTH - 1 downto 0);
        o_data       : out t_volume(0 to OUTPUT_CHANNELS - 1)
        (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)
        (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)
        (2 * BITWIDTH - 1 downto 0);
        o_data_valid : out std_logic
    );
end entity conv2d;

architecture conv2d_arch of conv2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    constant N_STAGES                : integer := integer(ceil(log2(real(KERNEL_SIZE * KERNEL_SIZE))));          --! Number of stages required to complete the addition process.
    constant N_MULT_REG              : integer := 1;                                                             --! Number of addition registers.
    constant N_OUTPUT_REG            : integer := 1;                                                             --! Number of output registers.
    constant DFF_DELAY_NON_PIPELINED : integer := N_MULT_REG + N_OUTPUT_REG + 1;                                 --! Total delay when not pipelined
    constant DFF_DELAY_PIPELINED     : integer := N_STAGES + N_MULT_REG + N_OUTPUT_REG + 2;                      --! Total delay when pipelined
    constant DFF_DELAY_MAC_ARCH      : integer := KERNEL_SIZE * KERNEL_SIZE + INPUT_CHANNELS + 1 + N_OUTPUT_REG; --! Total delay when using MAC architecture

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
    signal current_row     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current position within the kernel.
    signal current_col     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current position within the kernel.
    signal current_channel : integer range 0 to INPUT_CHANNELS;  --! Counter to track the current position within the channels.

    -- Control signals
    signal i_valid_d1        : std_logic; --! Delayed input valid signal
    signal is_processing_mac : std_logic; --! Flag to indicate if the MAC is processing
    signal is_processing_add : std_logic; --! Flag to indicate if the adder is processing

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
    component conv2d_layer
        generic (
            DO_PIPELINE    : std_logic;
            BITWIDTH       : integer;
            INPUT_CHANNELS : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels    : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
            clock             : in std_logic;
            reset_n           : in std_logic;
            i_sys_enable      : in std_logic;
            i_data            : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_valid           : in std_logic;
            i_kernels         : in t_volume(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias            : in std_logic_vector(2 * BITWIDTH - 1 downto 0);
            is_processing_mac : in std_logic;
            is_processing_add : in std_logic;
            current_channel   : in integer range 0 to INPUT_CHANNELS;
            current_col       : in integer range 0 to KERNEL_SIZE - 1;
            current_row       : in integer range 0 to KERNEL_SIZE - 1;
            o_result          : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, INPUT_CHANNELS, PADDING, BITWIDTH);
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- MATRIX VOLUME SLICER
    -------------------------------------------------------------------------------------
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

    gen_fc_arch : if USE_MAC_ARCH = '0' generate
        -------------------------------------------------------------------------------------
        -- pipeline INSTANTIATION
        -------------------------------------------------------------------------------------
        -- Pipelined version
        gen_do_pipeline : if DO_PIPELINE = '1' generate
            pipeline_inst : pipeline
            generic map(
                N_STAGES => DFF_DELAY_PIPELINED
            )
            port map(
                clock        => clock,
                reset_n      => reset_n,
                i_sys_enable => i_sys_enable,
                i_data       => conv2d_start,
                o_data       => conv2d_layer_done
            );
        end generate gen_do_pipeline;

        -- Non-Pipelined version
        gen_do_not_pipeline : if DO_PIPELINE = '0' generate
            pipeline_inst : pipeline
            generic map(
                N_STAGES => DFF_DELAY_NON_PIPELINED
            )
            port map(
                clock        => clock,
                reset_n      => reset_n,
                i_sys_enable => i_sys_enable,
                i_data       => conv2d_start,
                o_data       => conv2d_layer_done
            );
        end generate gen_do_not_pipeline;

        -------------------------------------------------------------------------------------
        -- conv2d_layer INSTANTIATION
        -------------------------------------------------------------------------------------
        gen_conv2d_layers : for i in 0 to OUTPUT_CHANNELS - 1 generate
            conv2d_layer_inst : conv2d_layer
            generic map(
                DO_PIPELINE    => DO_PIPELINE,
                BITWIDTH       => BITWIDTH,
                INPUT_CHANNELS => INPUT_CHANNELS,
                KERNEL_SIZE    => KERNEL_SIZE
            )
            port map(
                clock        => clock,
                reset_n      => reset_n,
                i_sys_enable => i_sys_enable,
                i_data       => sliced_input_volume,
                i_kernels    => i_kernel(i),
                i_bias       => i_bias(i),
                o_result     => conv2d_result(i)
            );
        end generate gen_conv2d_layers;
    end generate gen_fc_arch;

    gen_mac_arch : if USE_MAC_ARCH = '1' generate
        -------------------------------------------------------------------------------------
        -- conv2d_layer INSTANTIATION
        -------------------------------------------------------------------------------------
        gen_conv2d_layers : for i in 0 to OUTPUT_CHANNELS - 1 generate
            conv2d_layer_inst : conv2d_layer_mac
            generic map(
                DATA_SCALE_FACTOR => DATA_SCALE_FACTOR,
                BITWIDTH          => BITWIDTH,
                INPUT_CHANNELS    => INPUT_CHANNELS,
                KERNEL_SIZE       => KERNEL_SIZE
            )
            port map(
                clock             => clock,
                reset_n           => reset_n,
                i_sys_enable      => i_sys_enable,
                i_valid           => conv2d_start,
                i_data            => sliced_input_volume,
                i_kernels         => i_kernel(i),
                i_bias            => i_bias(i),
                is_processing_mac => is_processing_mac,
                is_processing_add => is_processing_add,
                current_row       => current_row,
                current_col       => current_col,
                current_channel   => current_channel,
                o_result          => conv2d_result(i)
            );
        end generate gen_conv2d_layers;

        -- Pipeline for MAC architecture
        pipeline_inst : pipeline
        generic map(
            N_STAGES => DFF_DELAY_MAC_ARCH
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_data       => conv2d_start,
            o_data       => conv2d_layer_done
        );

        -------------------------------------------------------------------------------------
        -- PROCESS
        -------------------------------------------------------------------------------------
        --! Process
        --! Handles the synchronous and asynchronous operations.
        process (clock, reset_n)
        begin
            if reset_n = '0' then
                current_row       <= 0;
                current_col       <= 0;
                current_channel   <= 0;
                i_valid_d1        <= '0';
                is_processing_mac <= '0';
                is_processing_add <= '0';

            elsif rising_edge(clock) then
                if i_sys_enable = '1' then

                    -- Update i_valid delayed by one clock cycle
                    i_valid_d1 <= conv2d_start;

                    -- Check if it needs to start computation
                    if (is_processing_mac = '0' and is_processing_add = '0' and conv2d_start = '1' and i_valid_d1 = '0') then
                        is_processing_mac <= '1';

                    elsif is_processing_mac = '1' then

                        -- Process the MAC unit
                        if current_col = KERNEL_SIZE - 1 then
                            current_col <= 0;
                            if current_row = KERNEL_SIZE - 1 then
                                current_row       <= 0;
                                is_processing_mac <= '0';
                                is_processing_add <= '1';

                            else
                                current_row <= current_row + 1;
                            end if;
                        else
                            current_col <= current_col + 1;
                        end if;

                    elsif is_processing_add = '1' then

                        -- Process the adder
                        if current_channel = INPUT_CHANNELS then
                            current_channel   <= 0;
                            is_processing_add <= '0';
                        else
                            current_channel <= current_channel + 1;
                        end if;
                    end if;
                end if;
            end if;
        end process;
    end generate gen_mac_arch;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (RESET ACTIVE LOW)
    -------------------------------------------------------------------------------------
    --! Process handling synchronous and asynchronous operations of the convolution
    conv2d_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            o_data <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                -- Update output
                if conv2d_layer_done = '1' then
                    for i in 0 to OUTPUT_CHANNELS - 1 loop
                        o_data(i)(to_integer(unsigned(row_index)))(to_integer(unsigned(col_index))) <= conv2d_result(i);
                    end loop;
                end if;
            end if;
        end if;
    end process conv2d_control;

end architecture;

configuration conv2d_conf of conv2d is
    for conv2d_arch

        for all : volume_slice
            use entity LIB_RTL.volume_slice(volume_slice_arch);
        end for;

        for gen_fc_arch
            for gen_conv2d_layers
                for all : conv2d_layer
                    use configuration LIB_RTL.conv2d_layer_fc_conf;
                end for;
            end for;

            for gen_do_pipeline
                for all : pipeline
                    use entity LIB_RTL.pipeline(pipeline_arch);
                end for;
            end for;

            for gen_do_not_pipeline
                for all : pipeline
                    use entity LIB_RTL.pipeline(pipeline_arch);
                end for;
            end for;
        end for;
    end for;
end configuration conv2d_conf;