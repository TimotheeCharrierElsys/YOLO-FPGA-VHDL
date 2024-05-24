-----------------------------------------------------------------------------------
--!     @file       fc_layer
--!     @brief      This entity implements a pipelined fully connected layer.
--!                 It performs multiplication and then additions
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.types_pkg.all;

--! Entity fc_layer
--! This entity implements a full connected layer layer using an adder tree.
entity fc_layer is
    generic (
        BITWIDTH    : integer := 8; --! Bit width of each operand
        VECTOR_SIZE : integer := 8  --! Input Vector Size
    );
    port (
        clock    : in std_logic;                                              --! Clock signal
        reset_n  : in std_logic;                                              --! Reset signal, active at low state
        i_enable : in std_logic;                                              --! Enable signal, active at low state
        i_data   : in t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input data
        i_weight : in t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input weights
        o_sum    : out std_logic_vector(2 * BITWIDTH - 1 downto 0)            --! Output value
    );
end fc_layer;

architecture fc_layer_arch of fc_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_mult_to_add : t_vec(VECTOR_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Signal between the multiplications and the additions
    signal r_sum         : std_logic_vector(2 * BITWIDTH - 1 downto 0);                --! Output signal register

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock   : in std_logic;                                    --! Clock signal
            reset_n : in std_logic;                                    --! Reset signal, active at low state
            i_data  : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Input data vector
            o_data  : out std_logic_vector(BITWIDTH - 1 downto 0)      --! Output data
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- MULTIPLICATION GENERATION
    -------------------------------------------------------------------------------------
    -- Multiply the two inputs together
    mult_gen : for i in 0 to VECTOR_SIZE - 1 generate
        r_mult_to_add(i) <= std_logic_vector(signed(i_data(i)) * signed(i_weight(i)));
    end generate;

    -------------------------------------------------------------------------------------
    -- ADDER TREE
    -------------------------------------------------------------------------------------
    -- Instantiate the adder tree
    adder_tree_inst : adder_tree
    generic map(
        N_OPD    => VECTOR_SIZE,
        BITWIDTH => 2 * BITWIDTH
    )
    port map(
        clock   => clock,
        reset_n => reset_n,
        i_data  => r_mult_to_add,
        o_data  => r_sum
    );

    -------------------------------------------------------------------------------------
    -- OUTPUT UPDATE
    -------------------------------------------------------------------------------------
    -- Assign the final output data from the first stage of the register
    o_sum <= r_sum;

end fc_layer_arch;

configuration fc_layer_conf of fc_layer is
    for fc_layer_arch
        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_arch);
        end for;
    end for;
end configuration fc_layer_conf;