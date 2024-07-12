-----------------------------------------------------------------------------------
--!     @file       batchnorm2d
--!     @brief      This entity implements a layer that computes the batchnorm2d channel-wise.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity batchnorm2d
entity batchnorm2d is
    generic (
        BITWIDTH : integer := 16; --! Bit width of each operand
        EPSILON  : integer := 0   --! A small value  added for numerical stability.
    );
    port (
        clock        : in std_logic;                                --! Clock signal
        reset_n      : in std_logic;                                --! Reset signal, active low
        i_sys_enable : in std_logic;                                --! Global enable signal, active high
        i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);  --! Input data
        i_mean       : in std_logic_vector(BITWIDTH - 1 downto 0);  --! Input mean value
        i_var        : in std_logic_vector(BITWIDTH - 1 downto 0);  --! input variance value
        i_weight     : in std_logic_vector(BITWIDTH - 1 downto 0);  --! Input weight value
        i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);  --! Input bias value
        i_valid      : in std_logic;                                --! Input valid signal
        o_data       : out std_logic_vector(BITWIDTH - 1 downto 0); --! Channel-wise output data
        o_data_done  : out std_logic                                --! Output valid signal
    );
end batchnorm2d;

architecture batchnorm2d_arch of batchnorm2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant N_OPERATIONS_REG    : integer                                   := 4;                               --! Number of operations registers.
    constant N_OUTPUT_REG        : integer                                   := 1;                               --! Number of output registers.
    constant DFF_DELAY_PIPELINED : integer                                   := N_OPERATIONS_REG + N_OUTPUT_REG; --! Total delay due to flip-flops when pipelined.
    constant ZERO_CONSTANT       : std_logic_vector(BITWIDTH/2 - 1 downto 0) := (others => '0');

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_numerator            : std_logic_vector(BITWIDTH - 1 downto 0);   --! Signal to store the numerator computation result
    signal r_denominator          : std_logic_vector(BITWIDTH - 1 downto 0);   --! Signal to store the denominator computation result
    signal r_square_root_i_valid  : std_logic;                                 --! Square root i_data_valid signal
    signal r_square_root_result   : std_logic_vector(BITWIDTH/2 - 1 downto 0); --! Square root o_data signal
    signal r_square_root_o_valid  : std_logic;                                 --! Square root o_data_valid signal
    signal r_division             : std_logic_vector(BITWIDTH - 1 downto 0);   --! Division signal
    signal r_end_computation_part : std_logic;

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
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

begin

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
        i_data       => i_valid,
        o_data       => o_data_done
    );

    -------------------------------------------------------------------------------------
    -- square_root INSTANTIATION
    -------------------------------------------------------------------------------------
    square_root_inst : square_root
    generic map(
        BITWIDTH => BITWIDTH
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => r_denominator,
        i_data_valid => r_square_root_i_valid,
        o_data       => r_square_root_result,
        o_data_valid => r_square_root_o_valid
    );

    process (clock, reset_n)
        variable r_denominator_pos : std_logic_vector(BITWIDTH/2 - 1 downto 0);
        variable v_mult_add        : std_logic_vector(2 * BITWIDTH - 1 downto 0) := (others => '0');
    begin
        if reset_n = '0' then
            r_numerator            <= (others => '0');
            r_denominator          <= (others => '0');
            o_data                 <= (others => '0');
            r_division             <= (others => '0');
            r_square_root_i_valid  <= '0';
            r_end_computation_part <= '0';

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                if i_valid = '1' then
                    -- Compute i_data - i_mean (x_{cij} - µ_{i})
                    r_numerator <= std_logic_vector(signed(i_data) - signed(i_mean));

                    -- Compute i_var + epsilon (\sigma_i^2 + \epsilon)
                    r_denominator         <= std_logic_vector(signed(i_var) + to_signed(EPSILON, BITWIDTH));
                    r_square_root_i_valid <= '1';

                elsif r_square_root_o_valid = '1' then
                    -- Ensure r_square_root_result is > 0
                    if r_square_root_result = ZERO_CONSTANT then
                        r_denominator_pos := std_logic_vector(to_unsigned(1, BITWIDTH/2));
                    else
                        r_denominator_pos := r_square_root_result;
                    end if;

                    -- Compute division..........
                    r_division <= std_logic_vector(signed(r_numerator) / signed(r_denominator_pos));

                    r_end_computation_part <= '1';

                elsif r_end_computation_part = '1' then
                    -- Compute r_division * i_weight
                    v_mult_add := std_logic_vector(signed(r_division) * signed(i_weight));

                    -- Compute v_mult_add + i_bias
                    v_mult_add := std_logic_vector(signed(v_mult_add) + signed(i_bias));

                    o_data <= std_logic_vector(v_mult_add(o_data'range));
                else
                    r_square_root_i_valid  <= '0';
                    r_end_computation_part <= '0';
                end if;
            end if;
        end if;
    end process;
end batchnorm2d_arch;