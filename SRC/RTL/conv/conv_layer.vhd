-----------------------------------------------------------------------------------
--!     @file       conv_layer
--!     @brief      This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
--!                 with a 3x3 kernel.
--!                 It performs conv_layer operations using a 3x3 kernel over the input data.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

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
        clock     : in std_logic;                                                                                         --! Clock signal
        reset_n   : in std_logic;                                                                                         --! Reset signal, active at low state
        i_enable  : in std_logic;                                                                                         --! Enable signal, active at low state
        i_data    : in t_mat(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE * KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_kernels : in t_mat(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE * KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias    : in std_logic_vector(BITWIDTH - 1 downto 0);                                                           --! Input bias value
        o_Y       : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                                       --! Output value
    );
end conv_layer;

-------------------------------------------------------------------------------------
-- CONV LAYER USING PIPELINED MAC
-------------------------------------------------------------------------------------

architecture conv_layer_mac_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(0 to CHANNEL_NUMBER - 1)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac_layer
        generic (
            BITWIDTH    : integer; --! Bit width of each operand
            KERNEL_SIZE : integer  --! Size of the kernel
        );
        port (
            clock    : in std_logic;                                                         --! Clock signal
            reset_n  : in std_logic;                                                         --! Reset signal, active at low state
            i_enable : in std_logic;                                                         --! Enable signal, active at low state
            i_X      : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Input data (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
            i_theta  : in t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0); --! Kernel data (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
            o_Y      : out std_logic_vector (2 * BITWIDTH - 1 downto 0)                      --! Output result
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
            KERNEL_SIZE => KERNEL_SIZE
        )
        port map(
            clock    => clock,
            reset_n  => reset_n,
            i_enable => i_enable,
            i_X      => i_data(i),
            i_theta  => i_kernels(i),
            o_Y      => mac_out(i)
        );
    end generate conv_layer;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process to handle synchronous and asynchronous operations.
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            --! Reset output register and counter to zeros.
            o_Y <= (others => '0');
            sum := (others => '0');
        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Counter increment
                sum := (others => '0');
                --! Sum the MAC outputs for each channel and add bias.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;
                o_Y <= std_logic_vector(sum + signed(i_bias));
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

-------------------------------------------------------------------------------------
-- CONV LAYER USING FULLY CONNECTED LAYERS (FC)
-------------------------------------------------------------------------------------

architecture conv_layer_fc_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            BITWIDTH    : integer;
            VECTOR_SIZE : integer
        );
        port (
            clock    : in std_logic;
            reset_n  : in std_logic;
            i_enable : in std_logic;
            i_data   : in t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_weight : in t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_sum    : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
            VECTOR_SIZE => KERNEL_SIZE * KERNEL_SIZE
        )
        port map(
            clock    => clock,
            reset_n  => reset_n,
            i_enable => i_enable,
            i_data   => i_data(i),
            i_weight => i_kernels(i),
            o_sum    => mac_out(i)
        );
    end generate gen_fc;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process to handle synchronous and asynchronous operations.
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            --! Reset output register and counter to zeros.
            o_Y <= (others => '0');
        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Counter increment
                sum := (others => '0');
                --! Sum the MAC outputs for each channel and add bias.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;
                o_Y <= std_logic_vector(sum + signed(i_bias));
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

-------------------------------------------------------------------------------------
-- CONV LAYER USING ONE MAC PER LAYER
-------------------------------------------------------------------------------------

architecture conv_layer_one_mac_arch of conv_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : t_vec(CHANNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component mac_w_mux
        generic (
            BITWIDTH : integer
        );
        port (
            clock         : in std_logic;
            reset_n       : in std_logic;
            i_enable      : in std_logic;
            i_sel         : in std_logic;
            i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_bias        : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
            VECTOR_SIZE => KERNEL_SIZE * KERNEL_SIZE
        )
        port map(
            clock    => clock,
            reset_n  => reset_n,
            i_enable => i_enable,
            i_data   => i_data(i),
            i_weight => i_kernels(i),
            o_sum    => mac_out(i)
        );
    end generate gen_fc;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process to handle synchronous and asynchronous operations.
    process (clock, reset_n)
        variable sum : signed(2 * BITWIDTH - 1 downto 0); --! Variable to accumulate the sum of MAC outputs.
    begin
        if reset_n = '0' then
            --! Reset output register and counter to zeros.
            o_Y <= (others => '0');
        elsif rising_edge(clock) then
            if i_enable = '1' then
                -- Counter increment
                sum := (others => '0');
                --! Sum the MAC outputs for each channel and add bias.
                for i in 0 to CHANNEL_NUMBER - 1 loop
                    sum := sum + signed(mac_out(i));
                end loop;
                o_Y <= std_logic_vector(sum + signed(i_bias));
            end if;
        end if;
    end process;
end conv_layer_one_mac_arch;

configuration conv_layer_fc_conf of conv_layer is
    for conv_layer_one_mac_arch
        for gen_fc
            for all : fc_layer
                use configuration LIB_RTL.fc_layer_conf;
            end for;
        end for;
    end for;
end configuration conv_layer_fc_conf;