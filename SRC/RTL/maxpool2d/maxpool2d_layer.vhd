-----------------------------------------------------------------------------------
--!     @file       maxpool2d_layer
--!     @brief      This entity implements a max-pooling layer for a convolutional neural network.
--!                 It finds the maximum value in each 3x3 kernel window.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity maxpool2d_layer
--! This entity implements a max-pooling layer
entity maxpool2d_layer is
    generic (
        BITWIDTH       : integer := 8; --! Bit width of each operand
        CHANNEL_NUMBER : integer := 1; --! Number of channels in the image
        KERNEL_SIZE    : integer := 3  --! Size of the kernel (e.g., 3 for a 3x3 kernel)
    );
    port (
        clock        : in std_logic;                                                                                                        --! Clock signal
        reset_n      : in std_logic;                                                                                                        --! Reset signal, active at low state
        i_sys_enable : in std_logic;                                                                                                        --! Enable signal, active at high state
        i_data_valid : in std_logic;                                                                                                        --! Input valid signal
        i_data       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
        o_data       : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                       --! Output values
        o_data_valid : out std_logic                                                                                                        --! Output data valid signal
    );
end maxpool2d_layer;

architecture maxpool2d_layer_arch of maxpool2d_layer is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant DFF_DELAY : integer := 2; --! Total delay

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component pipeline
        generic (
            N_STAGES : integer --! Number of pipeline stages
        );
        port (
            clock        : in std_logic; --! Clock signal
            reset_n      : in std_logic; --! Reset signal, active low
            i_sys_enable : in std_logic; --! Global enable signal, active high
            i_data       : in std_logic; --! Input data
            o_data       : out std_logic --! Output data
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- PIPELINE
    -------------------------------------------------------------------------------------
    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_data_valid,
        o_data       => o_data_valid
    );

    -------------------------------------------------------------------------------------
    -- GENERATE PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipeline.
    gen_pipeline : for i in 0 to CHANNEL_NUMBER - 1 generate
        find_max_process : process (clock, reset_n)
            variable max_value  : signed(BITWIDTH - 1 downto 0); --! Variable to store the maximum value
            variable temp_value : signed(BITWIDTH - 1 downto 0); --! Variable to store the temporary value
        begin
            if reset_n = '0' then
                o_data(i) <= (others => '0');
            elsif rising_edge(clock) then
                if i_sys_enable = '1' then

                    -- Compute the max (with initialization set to bottom right value of the input matrix)
                    max_value := signed(i_data(i)(0)(0));

                    for row in 0 to KERNEL_SIZE - 1 loop
                        for col in 0 to KERNEL_SIZE - 1 loop
                            temp_value := signed(i_data(i)(row)(col));

                            -- Update max if current value > current max_value
                            if temp_value > max_value then
                                max_value := temp_value;
                            end if;
                        end loop;
                    end loop;

                    -- Output update
                    o_data(i) <= std_logic_vector(max_value);
                end if;
            end if;
        end process find_max_process;
    end generate;
end maxpool2d_layer_arch;