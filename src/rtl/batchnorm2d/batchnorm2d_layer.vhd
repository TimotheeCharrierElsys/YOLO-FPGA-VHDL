-----------------------------------------------------------------------------------
--!     @file       batchnorm2d_layer
--!     @brief      This entity implements a layer that computes the batchnorm2d_layer channel-wise.
--!                 Computes SiLU activation function at the end for ressource sharing
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity batchnorm2d_layer
entity batchnorm2d_layer is
    generic (
        BITWIDTH          : integer := 16; --! Bit width of each operand
        DATA_SCALE_FACTOR : integer := 12  --! Input data scale factor. For example, a value of 12 means input values are scaled by 2^12.
    );
    port (
        clock        : in std_logic;                               --! Clock signal
        reset_n      : in std_logic;                               --! Reset signal, active low
        i_sys_enable : in std_logic;                               --! Global enable signal, active high
        i_data       : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input data
        i_mean       : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input mean value
        i_weight     : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input weight value
        i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input bias value
        i_valid      : in std_logic;                               --! Input valid signal
        o_data       : out std_logic_vector(BITWIDTH - 1 downto 0) --! Channel-wise output data
    );
end batchnorm2d_layer;

architecture batchnorm2d_layer_arch of batchnorm2d_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_data_to_silu : std_logic_vector(BITWIDTH - 1 downto 0); --! Signal to store the numerator computation result

    component silu_activation
        generic (
            BITWIDTH          : integer;
            DATA_SCALE_FACTOR : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- SiLU INSTANTIATION
    -------------------------------------------------------------------------------------
    silu_activation_inst : silu_activation
    generic map(
        BITWIDTH          => BITWIDTH,
        DATA_SCALE_FACTOR => DATA_SCALE_FACTOR
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => r_data_to_silu,
        o_data       => o_data
    );

    -------------------------------------------------------------------------------------
    -- PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations.
    process (clock, reset_n)
        variable v_add  : signed(BITWIDTH - 1 downto 0)     := (others => '0'); --! Variable computing \gamma\times x + \beta 
        variable v_mult : signed(2 * BITWIDTH - 1 downto 0) := (others => '0');
    begin
        if reset_n = '0' then
            r_data_to_silu <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                -- If input is valid, compute the numerator and start square root next clock cycle
                if i_valid = '1' then
                    -- Compute i_data - i_mean (x_{cij} - µ_{i})
                    v_add := signed(i_data) - signed(i_mean);

                    v_mult := v_add * signed(i_weight);
                    v_mult := (v_mult'high downto v_mult'high - DATA_SCALE_FACTOR + 1 => v_mult(v_mult'high)) & -- MSB  
                        (v_mult(v_mult'high downto DATA_SCALE_FACTOR));                                             -- LSB

                    v_mult := v_mult + signed(i_bias);

                    r_data_to_silu <= std_logic_vector(resize(signed(v_mult), BITWIDTH));
                end if;
            end if;
        end if;
    end process;
end batchnorm2d_layer_arch;

configuration batchnorm2d_layer_conf of batchnorm2d_layer is
    for batchnorm2d_layer_arch

        for all : silu_activation
            use entity LIB_RTL.silu_activation(silu_activation_arch);
        end for;

    end for;
end configuration batchnorm2d_layer_conf;