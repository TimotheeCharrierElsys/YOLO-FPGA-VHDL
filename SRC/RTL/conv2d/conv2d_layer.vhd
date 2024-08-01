-----------------------------------------------------------------------------------
--!     @file       conv2d_layer
--!     @brief      This entity implements a convolution layer using three different architectures.
--!                 It performs conv2d_layer operations.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity conv2d_layer
--! This entity implements a convolution layer using a pipelined MAC unit with a 3x3 kernel.
entity conv2d_layer is
    generic (
        DO_PIPELINE    : std_logic := '1'; --! Define if the design is pipelined ('1') or not ('0')
        BITWIDTH       : integer   := 8;   --! Bit width of each operand
        CHANNEL_NUMBER : integer   := 3;   --! Number of channels in the image
        KERNEL_SIZE    : integer   := 3    --! Size of the kernel (e.g., 3 for a 3x3 kernel)
    );
    port (
        clock        : in std_logic;                                                                                                        --! Clock signal
        reset_n      : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                                                                                        --! Enable signal, active at high state
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_kernels    : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias       : in std_logic_vector(2 * BITWIDTH - 1 downto 0);                                                                      --! Input bias value
        o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                                                      --! Output value
    );
end conv2d_layer;

-----------------------------------------------------------------------------------
--!     @brief          This architecture implements a convolution layer using fully
--!                     connected layer.
--!     @Dependencies:  adder_tree.vhd, fc_layer.vhd
-----------------------------------------------------------------------------------
architecture conv2d_layer_fc_arch of conv2d_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_results : t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0); --! Intermediate signal to hold the output of each MAC unit for each channel. Add the bias to the vector.

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component fc_layer
        generic (
            DO_PIPELINE : std_logic;
            BITWIDTH    : integer;
            MATRIX_SIZE : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_matrix1    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_matrix2    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)
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
    -- GENERATE BLOCK
    -------------------------------------------------------------------------------------
    gen_fc : for i in 0 to CHANNEL_NUMBER - 1 generate

        --! Instantiate the fc_layer units for each channel.
        gen_fc_layer : fc_layer
        generic map(
            DO_PIPELINE => DO_PIPELINE,
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

    adder_tree_inst : adder_tree
    generic map(
        DO_PIPELINE  => DO_PIPELINE,
        NUM_OPERANDS => CHANNEL_NUMBER + 1,
        BITWIDTH     => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_operands   => r_results,
        o_result     => o_result
    );

    -- Add bias to r_result last position
    r_results(CHANNEL_NUMBER) <= i_bias;

end conv2d_layer_fc_arch;

configuration conv2d_layer_fc_conf of conv2d_layer is
    for conv2d_layer_fc_arch

        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_arch);
        end for;

        for gen_fc
            for all : fc_layer
                use configuration LIB_RTL.fc_layer_conf;
            end for;
        end for;

    end for;
end configuration conv2d_layer_fc_conf;