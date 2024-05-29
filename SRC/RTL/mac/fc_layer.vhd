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
        MATRIX_SIZE : integer := 3  --! Input Maxtrix Size (squared)
    );
    port (
        clock     : in std_logic;                                                                        --! Clock signal
        reset_n   : in std_logic;                                                                        --! Reset signal, active at low state
        i_enable  : in std_logic;                                                                        --! Enable signal, active at high state
        i_matrix1 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix
        i_matrix2 : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix
        o_result  : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                      --! Output matrix dot product
    );
end fc_layer;

architecture fc_layer_arch of fc_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_mult_to_add     : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Signal between the multiplications and the additions
    signal flatten_i_matrix1 : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);     --! Flattened i_matrix1
    signal flatten_i_matrix2 : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);     --! Flattened i_matrix2
    signal r_sum             : std_logic_vector(2 * BITWIDTH - 1 downto 0);                              --! Output signal register

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock    : in std_logic;                                    --! Clock signal
            reset_n  : in std_logic;                                    --! Reset signal, active at low state
            i_enable : in std_logic;                                    --! Reset signal, active at low state
            i_data   : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Input data vector
            o_data   : out std_logic_vector(BITWIDTH - 1 downto 0)      --! Output data
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS TO FLATTEN THE DATAS
    -------------------------------------------------------------------------------------
    process (i_matrix1, i_matrix2)
    begin
        for i in 0 to MATRIX_SIZE - 1 loop
            for j in 0 to MATRIX_SIZE - 1 loop
                flatten_i_matrix1(i * MATRIX_SIZE + j) <= i_matrix1(i)(j);
                flatten_i_matrix2(i * MATRIX_SIZE + j) <= i_matrix2(i)(j);
            end loop;
        end loop;
    end process;

    -------------------------------------------------------------------------------------
    -- MULTIPLICATION GENERATION
    -------------------------------------------------------------------------------------
    -- Multiply the two inputs together
    mult_gen : for i in 0 to MATRIX_SIZE * MATRIX_SIZE - 1 generate
        r_mult_to_add(i) <= std_logic_vector(signed(flatten_i_matrix1(i)) * signed(flatten_i_matrix2(i)));
    end generate;

    -------------------------------------------------------------------------------------
    -- ADDER TREE
    -------------------------------------------------------------------------------------
    -- Instantiate the adder tree
    adder_tree_inst : adder_tree
    generic map(
        N_OPD    => MATRIX_SIZE * MATRIX_SIZE,
        BITWIDTH => 2 * BITWIDTH
    )
    port map(
        clock    => clock,
        reset_n  => reset_n,
        i_enable => i_enable,
        i_data   => r_mult_to_add,
        o_data   => r_sum
    );

    -------------------------------------------------------------------------------------
    -- OUTPUT UPDATE
    -------------------------------------------------------------------------------------
    -- Assign the final output data from the first stage of the register
    o_result <= r_sum;

end fc_layer_arch;

configuration fc_layer_conf of fc_layer is
    for fc_layer_arch
        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_arch);
        end for;
    end for;
end configuration fc_layer_conf;