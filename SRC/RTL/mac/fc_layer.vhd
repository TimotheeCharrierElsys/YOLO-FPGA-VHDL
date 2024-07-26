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
use LIB_RTL.TYPES_PKG.all;

--! Entity fc_layer
--! This entity implements a full connected layer layer using an adder tree.
entity fc_layer is
    generic (
        DO_PIPELINE : std_logic := '1'; -- Define if the design is pipelined ('1') or not ('0')
        BITWIDTH    : integer   := 8;   --! Bit width of each operand
        MATRIX_SIZE : integer   := 3    --! Input Maxtrix Size (squared)
    );
    port (
        clock        : in std_logic;                                                                        --! Clock signal
        reset_n      : in std_logic;                                                                        --! Reset signal, active low
        i_sys_enable : in std_logic;                                                                        --! Global enable signal, active high
        i_matrix1    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! First input matrix
        i_matrix2    : in t_mat(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Second input matrix
        o_result     : out std_logic_vector(2 * BITWIDTH - 1 downto 0)                                      --! Output matrix dot product
    );
end fc_layer;

architecture fc_layer_arch of fc_layer is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal reg_mult_to_add   : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0); --! Register storing mult_to_add
    signal flatten_i_matrix1 : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);     --! Flattened i_matrix1
    signal flatten_i_matrix2 : t_vec(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);     --! Flattened i_matrix2
    signal sum_result        : std_logic_vector(2 * BITWIDTH - 1 downto 0);                              --! Output signal
    signal reg_sum_result    : std_logic_vector(2 * BITWIDTH - 1 downto 0);                              --! Register storing sum_result

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
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
    -- COMBINATIONAL PROCESS TO FLATTEN THE DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_matrix1, i_matrix2)
    begin
        for i in 0 to MATRIX_SIZE - 1 loop
            for j in 0 to MATRIX_SIZE - 1 loop
                flatten_i_matrix1(i * MATRIX_SIZE + j) <= i_matrix1(i)(j);
                flatten_i_matrix2(i * MATRIX_SIZE + j) <= i_matrix2(i)(j);
            end loop;
        end loop;
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- ADDER TREE
    -------------------------------------------------------------------------------------
    -- Instantiate the adder tree
    adder_tree_inst : adder_tree
    generic map(
        DO_PIPELINE  => DO_PIPELINE,
        NUM_OPERANDS => MATRIX_SIZE * MATRIX_SIZE,
        BITWIDTH     => 2 * BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_operands   => reg_mult_to_add,
        o_result     => sum_result
    );

    -- Case do pipelined version.
    -- We remove the register at the end because already present in the adder_tree
    gen_do_pipeline : if DO_PIPELINE = '1' generate
        process (clock, reset_n)
        begin
            if reset_n = '0' then
                reg_mult_to_add <= (others => (others => '0'));

            elsif rising_edge(clock) then
                if i_sys_enable = '1' then
                    -------------------------------------------------------------------------------------
                    -- MULTIPLICATION GENERATION
                    -------------------------------------------------------------------------------------
                    -- Multiply the two inputs together
                    mult_gen : for i in 0 to MATRIX_SIZE * MATRIX_SIZE - 1 loop
                        reg_mult_to_add(i) <= std_logic_vector(signed(flatten_i_matrix1(i)) * signed(flatten_i_matrix2(i)));
                    end loop;
                end if;
            end if;
        end process;

        -- Assign the final output data from the first stage of the register
        o_result <= sum_result;

    end generate gen_do_pipeline;

    -- Case do not pipelined version.
    -- We add a register at the end for timing purpose.
    gen_do_not_pipeline : if DO_PIPELINE = '0' generate
        process (clock, reset_n)
        begin
            if reset_n = '0' then
                reg_sum_result  <= (others => '0');
                reg_mult_to_add <= (others => (others => '0'));

            elsif rising_edge(clock) then
                if i_sys_enable = '1' then
                    -------------------------------------------------------------------------------------
                    -- MULTIPLICATION GENERATION
                    -------------------------------------------------------------------------------------
                    -- Multiply the two inputs together
                    mult_gen : for i in 0 to MATRIX_SIZE * MATRIX_SIZE - 1 loop
                        reg_mult_to_add(i) <= std_logic_vector(signed(flatten_i_matrix1(i)) * signed(flatten_i_matrix2(i)));
                    end loop;

                    reg_sum_result <= sum_result;
                end if;
            end if;
        end process;

        -- Assign the final output data from the first stage of the register
        o_result <= reg_sum_result;

    end generate gen_do_not_pipeline;
end fc_layer_arch;

configuration fc_layer_conf of fc_layer is
    for fc_layer_arch
        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_arch);
        end for;
    end for;
end configuration fc_layer_conf;