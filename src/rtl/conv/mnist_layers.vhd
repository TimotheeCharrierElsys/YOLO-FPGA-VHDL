-----------------------------------------------------------------------------------
--!     @file       conv
--!     @brief      This entity implements two layers of a convolutional neural network
--!                 defined for MNIST dataset. It is used to test the VHDL implementation
--!                 on real data. See 'src/bench/mnist/' for the testbench and 
--!                 'src/bench/model.py' for the Python model.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity mnist_layers
--! This entity implements  two layers of a convolutional neural network defined for MNIST dataset.
entity mnist_layers is
    generic (
        DATA_SCALE_FACTOR : integer := 12; --! Define the general scale factor of the input data (12 -> 2**12)
        BITWIDTH          : integer := 16; --! Bit width of each operand
        INPUT_SIZE        : integer := 28; --! Width and Height of the input
        KERNEL_SIZE       : integer := 3;  --! Size of the kernel
        INPUT_CHANNELS_1  : integer := 1;  --! Number of channels in the input
        OUTPUT_CHANNELS_1 : integer := 32; --! Number of kernels
        PADDING           : integer := 1;  --! Padding value
        STRIDE_1          : integer := 2;  --! Stride value 

        OUTPUT_CHANNELS_2 : integer := 64; --! Number of kernels for the second layer
        STRIDE_2          : integer := 1;  --! Stride value for the second layer
        OUTPUT_SIZE       : integer := 12  --! Output size
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic; --! System enable signal, active high      
        i_data_valid : in std_logic; --! Data valid signal, active high

        -- 
        -- conv2d inputs for first layer
        --        

        i_data_conv2d     : in t_volume(INPUT_CHANNELS_1 - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                   --! Input data (INPUT_CHANNELS_1 x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_kernel_conv2d_1 : in t_tensor(OUTPUT_CHANNELS_1 - 1 downto 0)(INPUT_CHANNELS_1 - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (OUTPUT_CHANNELS_1  x INPUT_CHANNELS_1 x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias_conv2d_1   : in t_vec(OUTPUT_CHANNELS_1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                                   --! Input bias vector for conv2d

        -- 
        -- batchnorm2d inputs for first layer
        --  

        i_mean_bn_1   : in t_vec(OUTPUT_CHANNELS_1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input mean vector
        i_weight_bn_1 : in t_vec(OUTPUT_CHANNELS_1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input weight vector
        i_bias_bn_1   : in t_vec(OUTPUT_CHANNELS_1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input bias vector for batchnorm2d   

        -- conv2d inputs for second layer
        i_kernel_conv2d_2 : in t_tensor(OUTPUT_CHANNELS_2 - 1 downto 0)(OUTPUT_CHANNELS_1 - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (OUTPUT_CHANNELS_2  x OUTPUT_CHANNELS_1 x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias_conv2d_2   : in t_vec(OUTPUT_CHANNELS_2 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                                    --! Input bias vector for conv2d

        -- batchnorm2d inputs for second layer
        i_mean_bn_2   : in t_vec(OUTPUT_CHANNELS_2 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input mean vector
        i_weight_bn_2 : in t_vec(OUTPUT_CHANNELS_2 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input weight vector
        i_bias_bn_2   : in t_vec(OUTPUT_CHANNELS_2 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input bias vector for batchnorm2d

        -- 
        -- outputs
        --  

        o_data       : out t_volume(OUTPUT_CHANNELS_2 - 1 downto 0)(0 to OUTPUT_SIZE - 1)(0 to OUTPUT_SIZE - 1)(2 * BITWIDTH - 1 downto 0); --! Output data
        o_data_valid : out std_logic                                                                                                        --! Output valid signal
    );
end mnist_layers;

architecture mnist_layers_arch of mnist_layers is

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv
        generic (
            DATA_SCALE_FACTOR : integer;
            BITWIDTH          : integer;
            INPUT_SIZE        : integer;
            KERNEL_SIZE       : integer;
            INPUT_CHANNELS    : integer;
            OUTPUT_CHANNELS   : integer;
            PADDING           : integer;
            STRIDE            : integer
        );
        port (
            clock           : in std_logic;
            reset_n         : in std_logic;
            i_sys_enable    : in std_logic;
            i_data_valid    : in std_logic;
            i_data_conv2d   : in t_volume(INPUT_CHANNELS - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_kernel_conv2d : in t_tensor(OUTPUT_CHANNELS - 1 downto 0)(INPUT_CHANNELS - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias_conv2d   : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_mean_bn       : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_weight_bn     : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            i_bias_bn       : in t_vec(OUTPUT_CHANNELS - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data          : out t_volume(OUTPUT_CHANNELS - 1 downto 0)(0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)(0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1)(2 * BITWIDTH - 1 downto 0);
            o_data_valid    : out std_logic
        );
    end component;

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_data_conv2d_1 : t_volume(OUTPUT_CHANNELS_1 - 1 downto 0)
    (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1)
    (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1)
    (2 * BITWIDTH - 1 downto 0); --! Output data from the first conv2d layer
    signal r_data_conv2d_1_resized : t_volume(OUTPUT_CHANNELS_1 - 1 downto 0)
    (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1)
    (0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1)
    (BITWIDTH - 1 downto 0);                  --! Resized output data from the first conv2d layer
    signal r_data_conv2d_1_valid : std_logic; --! Output valid signal from the first conv2d layer

begin

    -------------------------------------------------------------------------------------
    -- INSTANTIATIONS
    -------------------------------------------------------------------------------------
    -- First conv2d layer
    conv_inst : conv
    generic map(
        DATA_SCALE_FACTOR => DATA_SCALE_FACTOR,
        BITWIDTH          => BITWIDTH,
        INPUT_SIZE        => INPUT_SIZE,
        KERNEL_SIZE       => KERNEL_SIZE,
        INPUT_CHANNELS    => INPUT_CHANNELS_1,
        OUTPUT_CHANNELS   => OUTPUT_CHANNELS_1,
        PADDING           => PADDING,
        STRIDE            => STRIDE_1
    )
    port map(
        clock           => clock,
        reset_n         => reset_n,
        i_sys_enable    => i_sys_enable,
        i_data_valid    => i_data_valid,
        i_data_conv2d   => i_data_conv2d,
        i_kernel_conv2d => i_kernel_conv2d_1,
        i_bias_conv2d   => i_bias_conv2d_1,
        i_mean_bn       => i_mean_bn_1,
        i_weight_bn     => i_weight_bn_1,
        i_bias_bn       => i_bias_bn_1,
        o_data          => r_data_conv2d_1,
        o_data_valid    => r_data_conv2d_1_valid
    );

    -- Resize the output data from the first conv2d layer
    -- This is necessary because the output data from the first layer is 2 * BITWIDTH wide,
    -- which is not necessary and would only increase the design size.
    resize_data : process (all)
    begin
        for i in 0 to OUTPUT_CHANNELS_1 - 1 loop
            for j in 0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1 loop
                for k in 0 to (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1 - 1 loop
                    r_data_conv2d_1_resized(i)(j)(k) <= std_logic_vector(resize(signed(r_data_conv2d_1(i)(j)(k)), BITWIDTH));
                end loop;
            end loop;
        end loop;
    end process resize_data;

    -- Second conv2d layer
    conv_inst_2 : conv
    generic map(
        DATA_SCALE_FACTOR => DATA_SCALE_FACTOR,
        BITWIDTH          => BITWIDTH,
        INPUT_SIZE        => (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE_1 + 1,
        KERNEL_SIZE       => KERNEL_SIZE,
        INPUT_CHANNELS    => OUTPUT_CHANNELS_1,
        OUTPUT_CHANNELS   => OUTPUT_CHANNELS_2,
        PADDING           => 0,
        STRIDE            => STRIDE_2
    )
    port map(
        clock           => clock,
        reset_n         => reset_n,
        i_sys_enable    => i_sys_enable,
        i_data_valid    => r_data_conv2d_1_valid,
        i_data_conv2d   => r_data_conv2d_1_resized,
        i_kernel_conv2d => i_kernel_conv2d_2,
        i_bias_conv2d   => i_bias_conv2d_2,
        i_mean_bn       => i_mean_bn_2,
        i_weight_bn     => i_weight_bn_2,
        i_bias_bn       => i_bias_bn_2,
        o_data          => o_data,
        o_data_valid    => o_data_valid
    );
end architecture;