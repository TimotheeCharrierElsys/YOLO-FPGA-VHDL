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
        GENERAL_SCALE_FACTOR : integer   := 12;  --! Define the general scale factor of the input data (12 -> 2**12)
        USE_MAC_ARCH         : std_logic := '1'; --! Define if the design uses the mac architecture ('1') or not ('0')
        DO_PIPELINE          : std_logic := '1'; --! Define if the design is pipelined ('1') or not ('0')
        BITWIDTH             : integer   := 16;  --! Bit width of each operand
        INPUT_SIZE           : integer   := 5;   --! Width and Height of the input
        CHANNEL_NUMBER       : integer   := 3;   --! Number of channels in the input
        KERNEL_SIZE          : integer   := 3;   --! Size of the kernel
        KERNEL_NUMBER        : integer   := 3;   --! Number of kernels
        PADDING              : integer   := 1;   --! Padding value
        STRIDE               : integer   := 2;   --! Stride value 
        EPSILON              : integer   := 0    --! A small value  added for numerical stability
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic; --! System enable signal, active high      
        i_data_valid : in std_logic; --! Data valid signal, active high

        -- 
        -- conv2d inputs
        --        

        i_data        : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);                                      --! Input data (CHANNEL_NUMBER x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_kernel      : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Kernel data (KERNEL_NUMBER x CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        i_bias_conv2d : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);                                                                                        --! Input bias vector for conv2d

        -- 
        -- batchnorm2d inputs
        --  

        i_running_mean     : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input mean vector
        i_weight           : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input weight vector
        i_bias_batchnorm2d : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Input bias vector for batchnorm2d   

        -- 
        -- outputs
        --  

        o_data       : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Output data
        o_data_valid : out std_logic                                                                                                                                                                                            --! Output valid signal
    );
end conv;

architecture conv_arch of conv is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant OUTPUT_SIZE : integer := (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1; --! Size of the output 

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_conv2d_output       : t_volume(KERNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
    signal r_conv2d_output_valid : std_logic;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component conv2d
        generic (
            GENERAL_SCALE_FACTOR : integer;
            USE_MAC_ARCH         : std_logic;
            DO_PIPELINE          : std_logic;
            BITWIDTH             : integer;
            INPUT_SIZE           : integer;
            CHANNEL_NUMBER       : integer;
            KERNEL_SIZE          : integer;
            KERNEL_NUMBER        : integer;
            PADDING              : integer;
            STRIDE               : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid : in std_logic;
            i_kernel     : in t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias       : in t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data       : out t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

    component batchnorm2d
        generic (
            BITWIDTH       : integer;
            INPUT_SIZE     : integer;
            CHANNEL_NUMBER : integer;
            EPSILON        : integer
        );
        port (
            clock          : in std_logic;
            reset_n        : in std_logic;
            i_sys_enable   : in std_logic;
            i_data         : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_running_mean : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_weight       : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_bias         : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);
            i_data_valid   : in std_logic;
            o_data         : out t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);
            o_data_valid   : out std_logic
        );
    end component;

begin

    conv2d_inst : conv2d
    generic map(
        GENERAL_SCALE_FACTOR => GENERAL_SCALE_FACTOR,
        USE_MAC_ARCH         => USE_MAC_ARCH,
        DO_PIPELINE          => DO_PIPELINE,
        BITWIDTH             => BITWIDTH,
        INPUT_SIZE           => INPUT_SIZE,
        CHANNEL_NUMBER       => CHANNEL_NUMBER,
        KERNEL_SIZE          => KERNEL_SIZE,
        KERNEL_NUMBER        => KERNEL_NUMBER,
        PADDING              => PADDING,
        STRIDE               => STRIDE
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data,
        i_data_valid => i_data_valid,
        i_kernel     => i_kernel,
        i_bias       => i_bias_conv2d,
        o_data       => r_conv2d_output,
        o_data_valid => r_conv2d_output_valid
    );

    batchnorm2d_inst : batchnorm2d
    generic map(
        BITWIDTH       => 2 * BITWIDTH,
        INPUT_SIZE     => OUTPUT_SIZE,
        CHANNEL_NUMBER => KERNEL_NUMBER,
        EPSILON        => EPSILON
    )
    port map(
        clock          => clock,
        reset_n        => reset_n,
        i_sys_enable   => i_sys_enable,
        i_data         => r_conv2d_output,
        i_running_mean => i_running_mean,
        i_weight       => i_weight,
        i_bias         => i_bias_batchnorm2d,
        i_data_valid   => r_conv2d_output_valid,
        o_data         => o_data,
        o_data_valid   => o_data_valid
    );
end architecture;

configuration conv_conf of conv is
    for conv_arch

        for all : conv2d
            use configuration LIB_RTL.conv2d_conf;
        end for;

        for all : batchnorm2d
            use configuration LIB_RTL.batchnorm2d_conf;
        end for;

    end for;
end configuration conv_conf;