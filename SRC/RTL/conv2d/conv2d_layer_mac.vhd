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
        BITWIDTH       : integer := 8; --! Bit width of each operand
        CHANNEL_NUMBER : integer := 3; --! Number of channels in the image
        KERNEL_SIZE    : integer := 3  --! Size of the kernel (e.g., 3 for a 3x3 kernel)
    );
    port (
        clock             : in std_logic;                                                                                                        --! Clock signal
        reset_n           : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_sys_enable      : in std_logic;                                                                                                        --! Enable signal, active at high state
        i_data            : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_valid           : in std_logic;                                                                                                        --! Input valid signal
        i_kernels         : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias            : in std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                      --! Input bias value
        is_processing_mac : in std_logic;                                                                                                        --! Processing signal for the MAC units
        is_processing_add : in std_logic;                                                                                                        --! Processing signal for the adder unit
        current_row       : in integer range 0 to KERNEL_SIZE - 1;                                                                               --! Current row index
        current_col       : in integer range 0 to KERNEL_SIZE - 1;                                                                               --! Current column index
        current_channel   : in integer range 0 to CHANNEL_NUMBER;                                                                                --! Current channel index
        o_result          : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                                                      --! Output value
    );
end conv2d_layer_mac;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using one
--!                     mac per channel.
--!     @Dependencies:  mac.vhd, accumulative_mac.vhd, pipeline.vhd, adder_tree.vhd
-----------------------------------------------------------------------------------
architecture conv2d_layer_mac_arch of conv2d_layer_mac is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    -- Intermediate signals
    signal r_results                : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal intermediate_multiplier1 : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal to avoid static 
    signal intermediate_multiplier2 : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal
    signal intermediate_result      : std_logic_vector(2 * BITWIDTH - 1 downto 0);               --! Intermediate signal for output result sum

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component accumulative_mac
        generic (
            DO_MULTIPLICATION : std_logic;
            INPUT_WIDTH       : integer;
            OUTPUT_WIDTH      : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_clear      : in std_logic;
            i_operand1   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
            i_operand2   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
            o_result     : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK FOR MAC UNITS
    -------------------------------------------------------------------------------------
    gen_mac_channel : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate one accumulative mac for each channel
        gen_accumulative_mac_inst : accumulative_mac
        generic map(
            DO_MULTIPLICATION => '1',
            INPUT_WIDTH       => BITWIDTH,
            OUTPUT_WIDTH      => 2 * BITWIDTH
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_clear      => i_valid,
            i_operand1   => intermediate_multiplier1(i),
            i_operand2   => intermediate_multiplier2(i),
            o_result     => r_results(i)
        );
    end generate gen_mac_channel;

    --! Instantiate one accumulative adder for computing the output sum
    gen_output_sum : accumulative_mac
    generic map(
        DO_MULTIPLICATION => '0',
        INPUT_WIDTH       => 2 * BITWIDTH,
        OUTPUT_WIDTH      => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_clear      => is_processing_mac,
        i_operand1   => intermediate_result,
        i_operand2 => (others => '0'),
        o_result     => o_result
    );

    -------------------------------------------------------------------------------------
    -- ASSIGNMENTS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the assignment of the input data to the intermediate signals.
    process (all)
    begin
        r_results(CHANNEL_NUMBER) <= std_logic_vector(shift_left(signed(i_bias), 12));                                                       --! Initialize the output with the bias value
        intermediate_result       <= std_logic_vector(shift_right(signed(r_results(current_channel)), 12)) when is_processing_add = '1' else --! Intermediate signal to hold the output of each MAC unit for each channel.
            (others => '0');                                                                                                                     -- TODO repalce 12 by a generic value

        for i in 0 to CHANNEL_NUMBER - 1 loop
            intermediate_multiplier1(i) <= i_data(i)(current_col)(current_row) when is_processing_mac = '1' else
            (others => '0');
            intermediate_multiplier2(i) <= i_kernels(i)(current_col)(current_row) when is_processing_mac = '1' else
            (others => '0');
        end loop;
    end process;
end conv2d_layer_mac_arch;

configuration conv2d_layer_mac_conf of conv2d_layer_mac is

    for conv2d_layer_mac_arch
        for gen_mac_channel
            for all : accumulative_mac
                use entity LIB_RTL.accumulative_mac(accumulative_mac_arch);
            end for;
        end for;

        for all : accumulative_mac
            use entity LIB_RTL.accumulative_mac(accumulative_mac_arch);
        end for;
    end for;

end configuration conv2d_layer_mac_conf;