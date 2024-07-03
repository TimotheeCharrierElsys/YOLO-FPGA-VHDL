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
        i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);                                                                          --! Input bias value
        o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                                                      --! Output value
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
end conv2d_layer_mac_arch;

configuration conv2d_layer_mac_conf of conv2d_layer_mac is
    for conv2d_layer_mac_arch
        for gen_mac_channel

            for all : accumulative_mac
                use entity LIB_RTL.accumulative_mac(accumulative_mac_arch);
            end for;

        end for;
    end for;
end configuration conv2d_layer_mac_conf;