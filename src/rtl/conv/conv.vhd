-----------------------------------------------------------------------------------
--!     @file       conv
--!     @brief      This entity implements a conv module using conv2d, batchnorm2d and silu units
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity conv
--! This entity implements a conv module
entity conv is
    generic (
        DATA_SCALE_FACTOR : integer := 12; --! Define the general scale factor of the input data (12 -> 2**12)
        BITWIDTH          : integer := 16; --! Bit width of each operand
        INPUT_SIZE        : integer := 5;  --! Width and Height of the input
        KERNEL_SIZE       : integer := 3;  --! Size of the kernel
        INPUT_CHANNELS    : integer := 3;  --! Number of channels in the input
        OUTPUT_CHANNELS   : integer := 3;  --! Number of kernels
        PADDING           : integer := 1;  --! Padding value
        STRIDE            : integer := 2   --! Stride value 
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic; --! System enable signal, active high      
        i_data_valid : in std_logic; --! Data valid signal, active high

        -- 
        -- conv2d inputs
        --        

        i_data_conv2d   : in t_volume(INPUT_CHANNELS - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                 --! Input data (INPUT_CHANNELS x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_kernel_conv2d : in t_tensor(OUTPUT_CHANNELS - 1 downto 0)(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (OUTPUT_CHANNELS x INPUT_CHANNELS x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias_conv2d   : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                                 --! Input bias vector for conv2d

        -- 
        -- batchnorm2d inputs
        --  

        i_mean_bn   : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input mean vector
        i_weight_bn : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input weight vector
        i_bias_bn   : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input bias vector for batchnorm2d   

        -- 
        -- outputs
        --  

        o_data       : out t_volume(OUTPUT_CHANNELS - 1 downto 0)(0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)(0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)(2 * BITWIDTH - 1 downto 0); --! Output data
        o_data_valid : out std_logic                                                                                                                                                                                      --! Output valid signal
    );
end conv;

architecture conv_arch of conv is

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
    signal s_result            : t_vec(0 to OUTPUT_CHANNELS - 1)(2 * BITWIDTH - 1 downto 0);                                                       --! Channel-wise results

    -- Counters for the mac architecture
    signal s_current_row_conv2d     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current row within the kernel for Conv2d.
    signal s_current_col_conv2d     : integer range 0 to KERNEL_SIZE - 1; --! Counter to track the current col within the kernel for Conv2d.
    signal s_current_channel_conv2d : integer range 0 to INPUT_CHANNELS;  --! Counter to track the current channel within the channels for Conv2d.

    -- Signals for the window slicer
    signal s_current_row_win : integer range 0 to OUTPUT_SIZE - 1; --! Counter to track the current row within the slicing window
    signal s_current_col_win : integer range 0 to OUTPUT_SIZE - 1; --! Counter to track the current col within the slicing window

    -- Control signals
    signal s_valid_mac   : std_logic; --! Valid signal for the MAC
    signal s_valid_adder : std_logic; --! Valid signal for the adder
    signal s_valid_bn    : std_logic; --! Valid signal for the bn
    signal s_clear_mac   : std_logic; --! Clear signal for the MAC
    signal s_clear_adder : std_logic; --! Clear signal for the adder
    signal s_conv2d_done : std_logic; --! Signal Indicating the end of the conv2d layer

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv_fsm
        generic (
            KERNEL_SIZE    : integer;
            INPUT_CHANNELS : integer;
            OUTPUT_SIZE    : integer
        );
        port (
            clock                    : in std_logic;
            reset_n                  : in std_logic;
            i_sys_enable             : in std_logic;
            i_start                  : in std_logic;
            i_current_row_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
            i_current_col_conv2d     : in integer range 0 to KERNEL_SIZE - 1;
            i_current_channel_conv2d : in integer range 0 to INPUT_CHANNELS;
            i_current_row_win        : in integer range 0 to OUTPUT_SIZE - 1;
            i_current_col_win        : in integer range 0 to OUTPUT_SIZE - 1;
            o_valid_mac              : out std_logic;
            o_valid_adder            : out std_logic;
            o_valid_bn               : out std_logic;
            o_clear_mac              : out std_logic;
            o_clear_adder            : out std_logic;
            o_conv2d_done            : out std_logic;
            o_done                   : out std_logic
        );
    end component;

    component conv2d_layer
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
    comb_proc : process (i_data_conv2d)
    begin
        padded_input_data <= pad_input(i_data_conv2d, INPUT_SIZE, INPUT_CHANNELS, PADDING, BITWIDTH);
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS SELECTING THE CORRECT WINDOW
    -------------------------------------------------------------------------------------
    gen_window_slice : for i in 0 to INPUT_CHANNELS - 1 generate
        process (padded_input_data, s_current_row_win, s_current_col_win)
        begin
            for row in KERNEL_SIZE - 1 downto 0 loop
                for col in KERNEL_SIZE - 1 downto 0 loop
                    sliced_input_volume(i)(row)(col) <= padded_input_data(i)(s_current_row_win * STRIDE + row)(s_current_col_win * STRIDE + col);
                end loop;
            end loop;
        end process;
    end generate gen_window_slice;

    -------------------------------------------------------------------------------------
    -- INSTANTIATIONS
    -------------------------------------------------------------------------------------
    gen_conv2d_layers : for i in 0 to OUTPUT_CHANNELS - 1 generate
        conv2d_layer_inst : conv2d_layer
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
            i_kernel_conv2d => i_kernel_conv2d(i),
            i_bias_conv2d   => i_bias_conv2d(i),
            i_bias_bn       => i_bias_bn(i),
            i_mean_bn       => i_mean_bn(i),
            i_weight_bn     => i_weight_bn(i),
            i_valid_mac     => s_valid_mac,
            i_valid_adder   => s_valid_adder,
            i_valid_bn      => s_valid_bn,
            i_clear_mac     => s_clear_mac,
            i_clear_adder   => s_clear_adder,
            current_row     => s_current_row_conv2d,
            current_col     => s_current_col_conv2d,
            current_channel => s_current_channel_conv2d,
            o_result        => s_result(i)
        );
    end generate gen_conv2d_layers;

    conv2d_control_inst : conv_fsm
    generic map(
        KERNEL_SIZE    => KERNEL_SIZE,
        INPUT_CHANNELS => INPUT_CHANNELS,
        OUTPUT_SIZE    => OUTPUT_SIZE
    )
    port map(
        clock                    => clock,
        reset_n                  => reset_n,
        i_sys_enable             => i_sys_enable,
        i_start                  => i_data_valid,
        i_current_row_conv2d     => s_current_row_conv2d,
        i_current_col_conv2d     => s_current_col_conv2d,
        i_current_channel_conv2d => s_current_channel_conv2d,
        i_current_row_win        => s_current_row_win,
        i_current_col_win        => s_current_col_win,
        o_valid_mac              => s_valid_mac,
        o_valid_adder            => s_valid_adder,
        o_valid_bn               => s_valid_bn,
        o_clear_mac              => s_clear_mac,
        o_clear_adder            => s_clear_adder,
        o_conv2d_done            => s_conv2d_done,
        o_done                   => o_data_valid
    );

    -------------------------------------------------------------------------------------
    -- PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            s_current_row_conv2d     <= 0;
            s_current_col_conv2d     <= 0;
            s_current_channel_conv2d <= 0;
            s_current_row_win        <= 0;
            s_current_col_win        <= 0;
            o_data                   <= (others => (others => (others => (others => '0'))));

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                if s_valid_mac = '1' then
                    -- Process the MAC unit
                    if s_current_col_conv2d = KERNEL_SIZE - 1 then
                        s_current_col_conv2d <= 0;
                        if s_current_row_conv2d = KERNEL_SIZE - 1 then
                            s_current_row_conv2d <= 0;
                        else
                            s_current_row_conv2d <= s_current_row_conv2d + 1;
                        end if;
                    else
                        s_current_col_conv2d <= s_current_col_conv2d + 1;
                    end if;

                elsif s_valid_adder = '1' then
                    -- Process the adder
                    if s_current_channel_conv2d = INPUT_CHANNELS then
                        s_current_channel_conv2d <= 0;
                    else
                        s_current_channel_conv2d <= s_current_channel_conv2d + 1;
                    end if;

                elsif s_conv2d_done = '1' then

                    -- Output Update
                    for i in 0 to OUTPUT_CHANNELS - 1 loop
                        o_data(i)(s_current_row_win)(s_current_col_win) <= s_result(i);
                    end loop;

                    -- Update the indexes for sliding window
                    if s_current_col_win = OUTPUT_SIZE - 1 then
                        s_current_col_win <= 0;
                        if s_current_row_win = OUTPUT_SIZE - 1 then
                            s_current_row_win <= 0;
                        else
                            s_current_row_win <= s_current_row_win + 1;
                        end if;
                    else
                        s_current_col_win <= s_current_col_win + 1;
                    end if;
                end if;
            else
                s_current_row_conv2d     <= 0;
                s_current_col_conv2d     <= 0;
                s_current_channel_conv2d <= 0;
                s_current_row_win        <= 0;
                s_current_col_win        <= 0;
                o_data                   <= (others => (others => (others => (others => '0'))));
            end if;
        end if;
    end process;
end architecture;

configuration conv_conf of conv is
    for conv_arch

        for gen_conv2d_layers
            for all : conv2d_layer
                use entity LIB_RTL.conv2d_layer(conv2d_layer_arch);
            end for;
        end for;

        for all : conv_fsm
            use entity LIB_RTL.conv_fsm(conv_fsm_arch);
        end for;

    end for;
end configuration conv_conf;