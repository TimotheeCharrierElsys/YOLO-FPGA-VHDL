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
        BITWIDTH : integer := 16; --! Bit width of each operand
        EPSILON  : integer := 0;  --! A small value  added for numerical stability
        K        : integer := 10
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
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant SCALE_FACTOR_POWER_OF_2          : integer := 13; --! Scale factor for integer computation power (e.g., 10 -> 2**10)
    constant DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 10; --! Scale factor to compute the division by 6

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_data_to_silu : std_logic_vector(BITWIDTH - 1 downto 0); --! Signal to store the numerator computation result

    component square_root
        generic (
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector (BITWIDTH - 1 downto 0);
            i_data_valid : in std_logic;
            o_data       : out std_logic_vector (BITWIDTH/2 - 1 downto 0);
            o_data_valid : out std_logic
        );
    end component;

    component silu_activation
        generic (
            BITWIDTH                         : integer;
            SCALE_FACTOR_POWER_OF_2          : integer;
            DIVISION_SCALE_FACTOR_POWER_OF_2 : integer
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
        BITWIDTH                         => BITWIDTH,
        SCALE_FACTOR_POWER_OF_2          => SCALE_FACTOR_POWER_OF_2,
        DIVISION_SCALE_FACTOR_POWER_OF_2 => DIVISION_SCALE_FACTOR_POWER_OF_2
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
        variable v_add  : std_logic_vector(BITWIDTH - 1 downto 0)     := (others => '0'); --! Variable computing \gamma\times x + \beta 
        variable v_mult : std_logic_vector(2 * BITWIDTH - 1 downto 0) := (others => '0');
    begin
        if reset_n = '0' then
            r_data_to_silu <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                -- If input is valid, compute the numerator and start square root next clock cycle
                if i_valid = '1' then
                    -- Compute i_data - i_mean (x_{cij} - µ_{i})
                    v_add := std_logic_vector(signed(i_data) - signed(i_mean));

                    v_mult := std_logic_vector(signed(v_add) * signed(i_weight));
                    v_mult := std_logic_vector(shift_right(signed(v_mult), K));

                    v_mult := std_logic_vector(signed(v_mult) + signed(i_bias));

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