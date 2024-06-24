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
--! This entity implements a convolution operation
entity conv2d is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        INPUT_SIZE     : integer := 5; --! Width and Height of the input
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the input
        KERNEL_SIZE    : integer := 3; --! Size of the kernel
        KERNEL_NUMBER  : integer := 3; --! Number of kernels
        PADDING        : integer := 1; --! Padding value
        STRIDE         : integer := 2  --! Stride value 
    );
    port (
        clock        : in std_logic;                                                                                                                                                                                            --! Clock signal
        reset_n      : in std_logic;                                                                                                                                                                                            --! Reset signal, active low
        i_sys_enable : in std_logic;                                                                                                                                                                                            --! System enable signal, active high                                                                                                                                                     
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                                                                       --! Input data (CHANNEL_NUMBER x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_data_valid : in std_logic;                                                                                                                                                                                            --! Data valid signal, active high
        i_kernel     : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                                  --! Kernel data (KERNEL_NUMBER x CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias       : in t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                                                                                                             --! Input bias value
        o_data       : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Output data
        o_data_valid : out std_logic                                                                                                                                                                                            --! Output valid signal
    );
end conv2d;

architecture conv2d_fc_arch of conv2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input_data   : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Matrix volume with input padded on all channels
    signal sliced_input_volume : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);             --! Sliced volume for conv2d_layer input
    signal output_data_reg     : t_volume(KERNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);          --! Register to store the output data
    signal conv2d_result       : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                 --! Output result of the conv2d_layer
    signal conv2d_start        : std_logic;                                                                                                                    --! Signal to start convolution
    signal conv2d_layer_done   : std_logic;                                                                                                                    --! Signal indicating convolution layer completion
    signal row_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current row index
    signal col_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current column index

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            CHANNEL_NUMBER    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);
            o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
        );
    end component;

    component conv2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_valid      : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_valid      : out std_logic
        );
    end component;
begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, CHANNEL_NUMBER, PADDING, BITWIDTH);
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- MATRIX VOLUME SLICER
    -------------------------------------------------------------------------------------
    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER    => CHANNEL_NUMBER,
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

    -------------------------------------------------------------------------------------
    -- conv2d_layer INSTANTIATION
    -------------------------------------------------------------------------------------
    gen_conv2d_layers : for i in 0 to KERNEL_NUMBER - 1 generate
        conv2d_layer_inst : conv2d_layer
        generic map(
            BITWIDTH       => BITWIDTH,
            CHANNEL_NUMBER => CHANNEL_NUMBER,
            KERNEL_SIZE    => KERNEL_SIZE
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_valid      => conv2d_start,
            i_data       => sliced_input_volume,
            i_kernels    => i_kernel(i),
            i_bias       => i_bias(i),
            o_result     => conv2d_result(i),
            o_valid      => conv2d_layer_done
        );
    end generate gen_conv2d_layers;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (RESET ACTIVE LOW)
    -------------------------------------------------------------------------------------
    --! Process handling synchronous and asynchronous operations of the convolution
    conv2d_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            output_data_reg <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                -- Update output
                if (conv2d_layer_done = '1') then
                    for i in 0 to KERNEL_NUMBER - 1 loop
                        output_data_reg(i)(to_integer(unsigned(row_index)))(to_integer(unsigned(col_index))) <= conv2d_result(i);
                    end loop;
                end if;
            end if;
        end if;
    end process conv2d_control;

    -- Assign output data
    o_data <= output_data_reg;

end architecture;

configuration conv2d_fc_conf of conv2d is
    for conv2d_fc_arch

        for gen_conv2d_layers
            for all : conv2d_layer
                use configuration LIB_RTL.conv2d_layer_fc_conf;
            end for;
        end for;

        for all : volume_slice
            use entity LIB_RTL.volume_slice(volume_slice_arch);
        end for;
    end for;
end configuration conv2d_fc_conf;

architecture conv2d_fc_pipelined_arch of conv2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                       --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_PADDED_SIZE - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input_data   : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Matrix volume with input padded on all channels
    signal sliced_input_volume : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);             --! Sliced volume for conv2d_layer input
    signal output_data_reg     : t_volume(KERNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);          --! Register to store the output data
    signal conv2d_result       : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                 --! Output result of the conv2d_layer
    signal conv2d_start        : std_logic;                                                                                                                    --! Signal to start convolution
    signal conv2d_layer_done   : std_logic;                                                                                                                    --! Signal indicating convolution layer completion
    signal row_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current row index
    signal col_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current column index

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            CHANNEL_NUMBER    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);
            o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
        );
    end component;

    component conv2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_valid      : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_valid      : out std_logic
        );
    end component;
begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, CHANNEL_NUMBER, PADDING, BITWIDTH);
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- MATRIX VOLUME SLICER
    -------------------------------------------------------------------------------------
    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER    => CHANNEL_NUMBER,
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

    -------------------------------------------------------------------------------------
    -- conv2d_layer INSTANTIATION
    -------------------------------------------------------------------------------------
    gen_conv2d_layers : for i in 0 to KERNEL_NUMBER - 1 generate
        conv2d_layer_inst : conv2d_layer
        generic map(
            BITWIDTH       => BITWIDTH,
            CHANNEL_NUMBER => CHANNEL_NUMBER,
            KERNEL_SIZE    => KERNEL_SIZE
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_valid      => conv2d_start,
            i_data       => sliced_input_volume,
            i_kernels    => i_kernel(i),
            i_bias       => i_bias(i),
            o_result     => conv2d_result(i),
            o_valid      => conv2d_layer_done
        );
    end generate gen_conv2d_layers;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (RESET ACTIVE LOW)
    -------------------------------------------------------------------------------------
    --! Process handling synchronous and asynchronous operations of the convolution
    conv2d_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            output_data_reg <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                -- Update output
                if (conv2d_layer_done = '1') then
                    for i in 0 to KERNEL_NUMBER - 1 loop
                        output_data_reg(i)(to_integer(unsigned(row_index)))(to_integer(unsigned(col_index))) <= conv2d_result(i);
                    end loop;
                end if;
            end if;
        end if;
    end process conv2d_control;

    -- Assign output data
    o_data <= output_data_reg;

end architecture;

configuration conv2d_fc_pipelined_conf of conv2d is
    for conv2d_fc_pipelined_arch

        for gen_conv2d_layers
            for all : conv2d_layer
                use configuration LIB_RTL.conv2d_layer_fc_pipelined_conf;
            end for;
        end for;

        for all : volume_slice
            use entity LIB_RTL.volume_slice(volume_slice_arch);
        end for;
    end for;
end configuration conv2d_fc_pipelined_conf;

architecture conv2d_one_mac_arch of conv2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant INPUT_PADDED_SIZE : integer := INPUT_SIZE + 2 * PADDING;                              --! Input matrix size with padding
    constant OUTPUT_SIZE       : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal padded_input_data   : t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Matrix volume with input padded on all channels
    signal sliced_input_volume : t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);             --! Sliced volume for conv2d_layer input
    signal output_data_reg     : t_volume(KERNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);          --! Register to store the output data
    signal conv2d_result       : t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                 --! Output result of the conv2d_layer
    signal conv2d_start        : std_logic;                                                                                                                    --! Signal to start convolution
    signal conv2d_layer_done   : std_logic;                                                                                                                    --! Signal indicating convolution layer completion
    signal row_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current row index
    signal col_index           : std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);                                                        --! Current column index

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component volume_slice
        generic (
            BITWIDTH          : integer;
            INPUT_PADDED_SIZE : integer;
            CHANNEL_NUMBER    : integer;
            KERNEL_SIZE       : integer;
            PADDING           : integer;
            STRIDE            : integer;
            OUTPUT_SIZE       : integer
        );
        port (
            clock                   : in std_logic;
            reset_n                 : in std_logic;
            i_sys_enable            : in std_logic;
            i_data                  : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid            : in std_logic;
            i_last_computation_done : in std_logic;
            o_data                  : out t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_done                  : out std_logic;
            o_computation_start     : out std_logic;
            o_current_row           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0);
            o_current_col           : out std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
        );
    end component;

    component conv2d_layer
        generic (
            BITWIDTH       : integer;
            CHANNEL_NUMBER : integer;
            KERNEL_SIZE    : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_valid      : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);
            o_valid      : out std_logic
        );
    end component;
begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS PADDING THE INPUT DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_data)
    begin
        padded_input_data <= pad_input(i_data, INPUT_SIZE, CHANNEL_NUMBER, PADDING, BITWIDTH);
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- MATRIX VOLUME SLICER
    -------------------------------------------------------------------------------------
    volume_slice_inst : volume_slice
    generic map(
        BITWIDTH          => BITWIDTH,
        INPUT_PADDED_SIZE => INPUT_PADDED_SIZE,
        CHANNEL_NUMBER    => CHANNEL_NUMBER,
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

    -------------------------------------------------------------------------------------
    -- conv2d_layer INSTANTIATION
    -------------------------------------------------------------------------------------
    gen_conv2d_layers : for i in 0 to KERNEL_NUMBER - 1 generate
        conv2d_layer_inst : conv2d_layer
        generic map(
            BITWIDTH       => BITWIDTH,
            CHANNEL_NUMBER => CHANNEL_NUMBER,
            KERNEL_SIZE    => KERNEL_SIZE
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_valid      => conv2d_start,
            i_data       => sliced_input_volume,
            i_kernels    => i_kernel(i),
            i_bias       => i_bias(i),
            o_result     => conv2d_result(i),
            o_valid      => conv2d_layer_done
        );
    end generate gen_conv2d_layers;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (RESET ACTIVE LOW)
    -------------------------------------------------------------------------------------
    --! Process handling synchronous and asynchronous operations of the convolution
    conv2d_control : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            output_data_reg <= (others => (others => (others => (others => '0'))));
        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                -- Update output
                if (conv2d_layer_done = '1') then
                    for i in 0 to KERNEL_NUMBER - 1 loop
                        output_data_reg(i)(to_integer(unsigned(row_index)))(to_integer(unsigned(col_index))) <= conv2d_result(i);
                    end loop;
                end if;
            end if;
        end if;
    end process conv2d_control;

    -- Assign output data
    o_data <= output_data_reg;

end architecture;

configuration conv2d_one_mac_conf of conv2d is
    for conv2d_one_mac_arch

        for gen_conv2d_layers
            for all : conv2d_layer
                use configuration LIB_RTL.conv2d_layer_one_mac_conf;
            end for;
        end for;

        for all : volume_slice
            use entity LIB_RTL.volume_slice(volume_slice_arch);
        end for;
    end for;
end configuration conv2d_one_mac_conf;