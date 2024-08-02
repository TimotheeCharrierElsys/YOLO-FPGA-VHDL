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
        clock        : in std_logic;                                                                                                        --! Clock signal
        reset_n      : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                                                                                        --! Enable signal, active at high state
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_valid      : in std_logic;                                                                                                        --! Input valid signal
        i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias       : in std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                      --! Input bias value
        o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                     --! Output value
        o_valid      : out std_logic
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
    signal r_results                : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal good_results             : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0);
    signal current_row              : integer range 0 to KERNEL_SIZE - 1;                        --! Counter to track the current position within the kernel.
    signal current_col              : integer range 0 to KERNEL_SIZE - 1;                        --! Counter to track the current position within the kernel.
    signal current_channel          : integer range 0 to CHANNEL_NUMBER;                         --! Counter to track the current position within the channels.
    signal intermediate_multiplier1 : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal to avoid static 
    signal intermediate_multiplier2 : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal
    signal intermediate_result      : std_logic_vector(2 * BITWIDTH - 1 downto 0);               --! Intermediate signal for output result sum

    signal i_valid_d1        : std_logic;
    signal is_processing_mac : std_logic;
    signal is_processing_add : std_logic;

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

    component adder_tree
        generic (
            DO_PIPELINE  : std_logic;
            NUM_OPERANDS : integer;
            BITWIDTH     : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_operands   : in t_vec(NUM_OPERANDS - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(BITWIDTH - 1 downto 0)
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

    --! Instantiate one accumulative adder for computing the output su;
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

    -- adder_tree_inst : entity work.adder_tree
    --     generic map(
    --         DO_PIPELINE  => '0',
    --         NUM_OPERANDS => CHANNEL_NUMBER + 1,
    --         BITWIDTH     => 2 * BITWIDTH
    --     )
    --     port map(
    --         clock        => clock,
    --         reset_n      => reset_n,
    --         i_sys_enable => i_sys_enable,
    --         i_operands   => r_results,
    --         o_result     => o_result
    --     );
    process (all)
    begin
        -- Update the intermediate signals
        good_results(CHANNEL_NUMBER) <= i_bias;
        intermediate_result          <= good_results(current_channel);

        for i in 0 to CHANNEL_NUMBER - 1 loop
            intermediate_multiplier1(i) <= i_data(i)(current_col)(current_row);
            intermediate_multiplier2(i) <= i_kernels(i)(current_col)(current_row);
            good_results(i)             <= r_results(i) when is_processing_mac;
        end loop;

    end process;

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
            o_valid           <= '0';

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                -- Update i_valid delayed by one clock cycle
                i_valid_d1 <= i_valid;

                -- Check if it needs to start computation
                if (is_processing_mac = '0' and is_processing_add = '0' and i_valid = '1' and i_valid_d1 = '0') then
                    is_processing_mac <= '1';
                elsif is_processing_mac = '1' then

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

                    if current_channel = CHANNEL_NUMBER then
                        current_channel   <= 0;
                        is_processing_add <= '0';
                        o_valid           <= '1';
                    else
                        current_channel <= current_channel + 1;
                    end if;
                else
                    o_valid <= '0';
                end if;

            end if;
        end if;
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