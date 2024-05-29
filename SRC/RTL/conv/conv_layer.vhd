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
        clock     : in std_logic;                                                                                                        --! Clock signal
        reset_n   : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_enable  : in std_logic;                                                                                                        --! Enable signal, active at low state
        i_data    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_kernels : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias    : in std_logic_vector(BITWIDTH - 1 downto 0);                                                                          --! Input bias value
        o_result  : out std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                     --! Output value
        o_valid   : out std_logic                                                                                                        --! Output valid signal
    );
end conv_layer;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using pipelined mac
--!                      unit.
--!     @Dependencies:  mac.vhd, mac_layer.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_mac_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(0 to CHANNEL_NUMBER - 1)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal r_count : integer range 0 to KERNEL_SIZE * KERNEL_SIZE - 1;          --! Counter for o_valid data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac_layer
        generic (
            BITWIDTH    : integer;
            MATRIX_SIZE : integer
        );
        port (
            clock     : in std_logic;                                                                        --! Clock signal
            reset_n   : in std_logic;                                                                        --! Reset signal, active at low state
            i_enable  : in std_logic;                                                                        --! Enable signal, active at high state
            i_matrix1 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix
            i_matrix2 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix
            o_result  : out std_logic_vector (2 * BITWIDTH - 1 downto 0)                                     --! Output result
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    conv_layer : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the mac_layer units for each channel.
        gen_mac_layer : mac_layer
        generic map(
            BITWIDTH    => BITWIDTH,
            MATRIX_SIZE => KERNEL_SIZE
        )
        port map(
            clock     => clock,
            reset_n   => reset_n,
            i_enable  => i_enable,
            i_matrix1 => i_data(i),
            i_matrix2 => i_kernels(i),
            o_result  => mac_out(i)
        );
    end generate conv_layer;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            --! Reset output register and sum to zeros.
            o_result <= (others => '0');
            o_valid  <= '0';
            r_count  <= 0;
            sum := (others => '0');

        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Reset output sum
                sum := (others => '0');

                --! Sum the MAC outputs for each channel and add bias.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;

                -- Counter increment
                if (r_count >= KERNEL_SIZE * KERNEL_SIZE - 1) then
                    r_count <= 0;
                    o_valid <= '1';
                else
                    r_count <= r_count + 1;
                    o_valid <= '0';
                end if;

                -- Output update
                o_result <= std_logic_vector(sum + signed(i_bias));
            end if;
        end if;
    end process;
end conv_layer_mac_arch;

configuration conv_layer_mac_conf of conv_layer is
    for conv_layer_mac_arch
        for conv_layer

            for all : mac_layer
                use configuration LIB_RTL.mac_layer_conf;
            end for;

        end for;
    end for;
end configuration conv_layer_mac_conf;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using fully
--!                     connected layer.
--!     @Dependencies:  adder_tree.vhd, fc_layer.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_fc_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    constant DFF_DELAY : integer := (integer(ceil(log2(real(KERNEL_SIZE * KERNEL_SIZE)))) + 1) + 1; --! Number of stages required to complete the addition process + MULT REG

    signal mac_out : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal r_count : integer range 0 to DFF_DELAY - 1;                              --! Counter for o_valid data

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer;
            MATRIX_SIZE : integer
        );
        port (
            clock     : in std_logic;                                                                        --! Clock signal
            reset_n   : in std_logic;                                                                        --! Reset signal, active at low state
            i_enable  : in std_logic;                                                                        --! Enable signal, active at high state
            i_matrix1 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix
            i_matrix2 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix
            o_result  : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                      --! Output matrix dot product
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
            clock     => clock,
            reset_n   => reset_n,
            i_enable  => i_enable,
            i_matrix1 => i_data(i),
            i_matrix2 => i_kernels(i),
            o_result  => mac_out(i)
        );
    end generate gen_fc;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            --! Reset output register and counter to zeros.
            o_result <= (others => '0');
            o_valid  <= '0';
            r_count  <= 0;

        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Reset output sum
                sum := (others => '0');

                --! Sum the MAC outputs for each channel and add bias.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;

                -- Counter increment
                if (r_count >= DFF_DELAY - 1) then
                    r_count <= 0;
                    o_valid <= '1';
                else
                    r_count <= r_count + 1;
                    o_valid <= '0';
                end if;

                -- Output update
                o_result <= std_logic_vector(sum + signed(i_bias));
            end if;
        end if;
    end process;
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
--!     @brief          This architecture implements a convolution layer using one
--!                     mac per channel.
--!     @Dependencies:  mac_w_mux.vhd
-----------------------------------------------------------------------------------
architecture conv_layer_one_mac_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out     : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.
    signal r_count_row : integer range 0 to KERNEL_SIZE - 1;                            --! Counter to track the current position within the kernel.
    signal r_count_col : integer range 0 to KERNEL_SIZE - 1;                            --! Counter to track the current position within the kernel.
    signal r_sel       : std_logic;                                                     --! Selector signal for mac_w_mux control.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac_w_mux
        generic (
            BITWIDTH : integer --! Bit width of each operand
        );
        port (
            clock         : in std_logic;                                   --! Clock signal
            reset_n       : in std_logic;                                   --! Reset signal, active at low state
            i_enable      : in std_logic;                                   --! Enable signal, active at high state
            i_sel         : in std_logic;                                   --! Select signal for the MUX (1 for (bias + mult), 0 for (output + mult))
            i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
            i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
            i_bias        : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Input bias value
            o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result value
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCK FOR MAC UNITS
    -------------------------------------------------------------------------------------
    gen_mac_channel : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate one mac_w_mux unit for each channel except the last one.
        gen_mac_w_mux : if i < CHANNEL_NUMBER - 1 generate
            gen_mac_w_mux_inst : mac_w_mux
            generic map(
                BITWIDTH => BITWIDTH
            )
            port map(
                clock         => clock,
                reset_n       => reset_n,
                i_enable      => i_enable,
                i_sel         => r_sel,
                i_multiplier1 => i_data(i)(r_count_row)(r_count_col),
                i_multiplier2 => i_kernels(i)(r_count_row)(r_count_col),
                i_bias => (others => '0'),
                o_result      => mac_out(i)
            );
        end generate gen_mac_w_mux;

        --! Instantiate the last MAC unit and include bias in the calculation.
        last_mac : if i = CHANNEL_NUMBER - 1 generate
            last_mac_w_mux_inst : mac_w_mux
            generic map(
                BITWIDTH => BITWIDTH
            )
            port map(
                clock         => clock,
                reset_n       => reset_n,
                i_enable      => i_enable,
                i_sel         => r_sel,
                i_multiplier1 => i_data(i)(r_count_row)(r_count_col),
                i_multiplier2 => i_kernels(i)(r_count_row)(r_count_col),
                i_bias        => i_bias,
                o_result      => mac_out(i)
            );
        end generate last_mac;

    end generate gen_mac_channel;

    -------------------------------------------------------------------------------------
    -- PROCESS TO HANDLE SYNCHRONOUS AND ASYNCHRONOUS OPERATIONS
    -------------------------------------------------------------------------------------
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            -- Reset output register, counters, and selector to initial states.
            o_result    <= (others => '0');
            o_valid     <= '0';
            r_count_row <= 0;
            r_count_col <= 0;
            r_sel       <= '1';

        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Initialize sum for this cycle.
                sum := (others => '0');

                -- Sum the MAC outputs for each channel.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;

                -- Update counter and selector signals.
                if r_count_col = KERNEL_SIZE - 1 then
                    r_count_col <= 0;
                    if r_count_row = KERNEL_SIZE - 1 then
                        r_count_row <= 0;
                        o_valid     <= '1';
                    else
                        r_count_row <= r_count_row + 1;
                        o_valid     <= '0';
                    end if;
                else
                    r_count_col <= r_count_col + 1;
                    o_valid     <= '0';
                end if;

                -- Assign the computed sum to the output.
                o_result <= std_logic_vector(sum);

                -- Toggle r_sel at the start of a new kernel
                if r_count_row = 0 and r_count_col = 0 then
                    r_sel <= not r_sel;
                end if;
            end if;
        end if;
    end process;
end conv_layer_one_mac_arch;

configuration conv_layer_one_mac_conf of conv_layer is
    for conv_layer_one_mac_arch
        for gen_mac_channel

            for gen_mac_w_mux
                for all : mac_w_mux
                    use entity LIB_RTL.mac_w_mux(mac_w_mux_arch);
                end for;
            end for;

            for last_mac
                for all : mac_w_mux
                    use entity LIB_RTL.mac_w_mux(mac_w_mux_arch);
                end for;
            end for;
        end for;
    end for;
end configuration conv_layer_one_mac_conf;