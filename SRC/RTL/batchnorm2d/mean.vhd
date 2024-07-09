-----------------------------------------------------------------------------------
--!     @file       mean
--!     @brief      This entity implements a layer that computes the mean channel-wise.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity mean
entity mean is
    generic (
        BITWIDTH                         : integer := 16; --! Bit width of each operand
        MATRIX_SIZE                      : integer := 3;  --! Input Maxtrix Size (squared)
        CHANNEL_NUMBER                   : integer := 3;  --! Number of channels in the input
        DIVISION_SCALE_FACTOR_POWER_OF_2 : integer := 16  --! Scale factor to compute the division by MATRIX_SIZE * MATRIX_SIZE
    );
    port (
        clock          : in std_logic;                                                                                                        --! Clock signal
        reset_n        : in std_logic;                                                                                                        --! Reset signal, active low
        i_sys_enable   : in std_logic;                                                                                                        --! Global enable signal, active high
        i_volume       : in t_volume(CHANNEL_NUMBER - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Input volume
        i_volume_valid : in std_logic;                                                                                                        --! Input volume valid signal
        o_mean         : out t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                       --! Channel-wise output mean
        o_mean_done    : out std_logic                                                                                                        --! Output valid signal
    );
end mean;

architecture mean_arch of mean is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type t_computation_signed is array (0 to CHANNEL_NUMBER - 1) of signed(DIVISION_SCALE_FACTOR_POWER_OF_2 + BITWIDTH - 1 downto 0); --! Type to handle the computation easily

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant DIVISION_SCALE_FACTOR : integer := 2 ** DIVISION_SCALE_FACTOR_POWER_OF_2;               --! Power of two to scale the data for division
    constant MEAN_DIVISION_FACTOR  : integer := DIVISION_SCALE_FACTOR / (MATRIX_SIZE * MATRIX_SIZE); --! Value to multiply (then shift) for division
    constant N_ADDITION_REG        : integer := 1;                                                   --! Number of addition registers in adder_tree.
    constant N_OUTPUT_REG          : integer := 1;                                                   --! Number of output registers.
    constant DFF_DELAY_UNPIPELINED : integer := N_ADDITION_REG + N_OUTPUT_REG;                       --! Total delay when not pipelined

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal flatten_i_volume : t_mat(CHANNEL_NUMBER - 1 downto 0)(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Flattened i_volume
    signal r_channel_sums   : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                         --! Channel-wise sums

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0);
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)
        );
    end component;

    component pipeline
        generic (
            N_STAGES : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic;
            o_data       : out std_logic
        );
    end component;

begin

    -------------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS TO FLATTEN THE DATAS
    -------------------------------------------------------------------------------------
    comb_proc : process (i_volume)
    begin
        for c in 0 to CHANNEL_NUMBER - 1 loop
            for i in 0 to MATRIX_SIZE - 1 loop
                for j in 0 to MATRIX_SIZE - 1 loop
                    flatten_i_volume(c)(i * MATRIX_SIZE + j) <= i_volume(c)(i)(j);
                end loop;
            end loop;
        end loop;
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- adder_tree INSTANTIATION
    -------------------------------------------------------------------------------------
    -- Instantiate the adder trees
    gen_adder_trees : for i in 0 to CHANNEL_NUMBER - 1 generate
        fc_layer_inst : adder_tree
        generic map(
            N_OPD    => MATRIX_SIZE * MATRIX_SIZE,
            BITWIDTH => BITWIDTH
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_data       => flatten_i_volume(i),
            o_data       => r_channel_sums(i)
        );
    end generate gen_adder_trees;

    -------------------------------------------------------------------------------------
    -- pipeline INSTANTIATION
    -------------------------------------------------------------------------------------
    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY_UNPIPELINED
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_volume_valid,
        o_data       => o_mean_done
    );

    process (clock, reset_n)
        variable mean_division : t_computation_signed; --! Variable to store the scaled division
    begin
        if reset_n = '0' then
            o_mean <= (others => (others => '0'));

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                for i in 0 to CHANNEL_NUMBER - 1 loop

                    -- Compute the division by N
                    mean_division(i) := signed(r_channel_sums(i)) * to_signed(MEAN_DIVISION_FACTOR, DIVISION_SCALE_FACTOR_POWER_OF_2);
                    mean_division(i) := SHIFT_RIGHT(mean_division(i), DIVISION_SCALE_FACTOR_POWER_OF_2);
                    -- mean_division(i) := mean_division(i) + 1; --! Maybe need due to computation approximations

                    o_mean(i) <= std_logic_vector(resize(mean_division(i), BITWIDTH));
                end loop;
            end if;
        end if;
    end process;
end mean_arch;

configuration mean_conf of mean is
    for mean_arch
        for gen_adder_trees
            for all : adder_tree
                use entity LIB_RTL.adder_tree(adder_tree_arch);
            end for;
        end for;

        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_arch);
        end for;
    end for;
end configuration mean_conf;

architecture mean_pipelined_arch of mean is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type t_computation_signed is array (0 to CHANNEL_NUMBER - 1) of signed(DIVISION_SCALE_FACTOR_POWER_OF_2 + BITWIDTH - 1 downto 0); --! Type to handle the computation easily

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant DIVISION_SCALE_FACTOR : integer := 2 ** DIVISION_SCALE_FACTOR_POWER_OF_2;
    constant MEAN_DIVISION_FACTOR  : integer := DIVISION_SCALE_FACTOR / (MATRIX_SIZE * MATRIX_SIZE);

    constant N_STAGES            : integer := integer(ceil(log2(real(MATRIX_SIZE * MATRIX_SIZE)))); --! Number of stages required to complete the addition process.
    constant N_ADDITION_REG      : integer := 1;                                                    --! Number of addition registers.
    constant N_OUTPUT_REG        : integer := 1;                                                    --! Number of output registers.
    constant DFF_DELAY_PIPELINED : integer := N_STAGES + N_ADDITION_REG + N_OUTPUT_REG;             --! Total delay due to flip-flops when pipelined.

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal flatten_i_volume : t_mat(CHANNEL_NUMBER - 1 downto 0)(MATRIX_SIZE * MATRIX_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Flattened i_volume
    signal r_channel_sums   : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                         --! Channel-wise sums

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component adder_tree
        generic (
            N_OPD    : integer;
            BITWIDTH : integer
        );
        port (
            clock        : in std_logic;                                    --! Clock signal
            reset_n      : in std_logic;                                    --! Reset signal, active at low state
            i_sys_enable : in std_logic;                                    --! Reset signal, active at low state
            i_data       : in t_vec(0 to N_OPD - 1)(BITWIDTH - 1 downto 0); --! Input data vector
            o_data       : out std_logic_vector(BITWIDTH - 1 downto 0)      --! Output data
        );
    end component;

    component pipeline
        generic (
            N_STAGES : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic;
            o_data       : out std_logic
        );
    end component;

begin

    comb_proc : process (i_volume)
    begin
        for c in 0 to CHANNEL_NUMBER - 1 loop
            for i in 0 to MATRIX_SIZE - 1 loop
                for j in 0 to MATRIX_SIZE - 1 loop
                    flatten_i_volume(c)(i * MATRIX_SIZE + j) <= i_volume(c)(i)(j);
                end loop;
            end loop;
        end loop;
    end process comb_proc;

    -------------------------------------------------------------------------------------
    -- adder_tree INSTANTIATION
    -------------------------------------------------------------------------------------
    -- Instantiate the adder trees
    gen_adder_trees : for i in 0 to CHANNEL_NUMBER - 1 generate
        fc_layer_inst : adder_tree
        generic map(
            N_OPD    => MATRIX_SIZE * MATRIX_SIZE,
            BITWIDTH => BITWIDTH
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_data       => flatten_i_volume(i),
            o_data       => r_channel_sums(i)
        );
    end generate gen_adder_trees;

    -------------------------------------------------------------------------------------
    -- pipeline INSTANTIATION
    -------------------------------------------------------------------------------------
    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY_PIPELINED
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => i_volume_valid,
        o_data       => o_mean_done
    );

    process (clock, reset_n)
        variable mean_division : t_computation_signed; --! Variable to store the scaled division
    begin
        if reset_n = '0' then
            o_mean <= (others => (others => '0'));

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                for i in 0 to CHANNEL_NUMBER - 1 loop

                    -- Compute the division by N
                    mean_division(i) := signed(r_channel_sums(i)) * to_signed(MEAN_DIVISION_FACTOR, DIVISION_SCALE_FACTOR_POWER_OF_2);
                    mean_division(i) := SHIFT_RIGHT(mean_division(i), DIVISION_SCALE_FACTOR_POWER_OF_2);
                    -- mean_division(i) := mean_division(i) + 1; --! Maybe need due to computation approximations

                    o_mean(i) <= std_logic_vector(resize(mean_division(i), BITWIDTH));
                end loop;
            end if;
        end if;
    end process;
end mean_pipelined_arch;

configuration mean_pipelined_conf of mean is
    for mean_pipelined_arch
        for gen_adder_trees
            for all : adder_tree
                use entity LIB_RTL.adder_tree(adder_tree_pipelined_arch);
            end for;
        end for;
        for all : adder_tree
            use entity LIB_RTL.adder_tree(adder_tree_pipelined_arch);
        end for;
    end for;
end configuration mean_pipelined_conf;