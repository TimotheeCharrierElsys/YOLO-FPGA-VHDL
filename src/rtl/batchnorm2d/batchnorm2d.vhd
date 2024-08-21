-----------------------------------------------------------------------------------
--!	@file		batchnorm2d
--!	@brief		This entity implements the batchnorm2d module using batchnorm2d_layers
--!	            It also compute SiLU activation function at the end for ressources sharing purposes.
--!	@author		Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

library LIB_RTL;
use LIB_RTL.TYPES_PKG.all;

--! Entity batchnorm2d
--! This entity implements a maxpool
entity batchnorm2d is
    generic (
        BITWIDTH       : integer := 16; --! Bit width of each operand
        INPUT_SIZE     : integer := 5;  --! Width and Height of the input
        CHANNEL_NUMBER : integer := 3;  --! Number of channels in the input
        EPSILON        : integer := 0   --! A small value  added for numerical stability
    );
    port (
        clock          : in std_logic;                                                                                                       --! Clock signal
        reset_n        : in std_logic;                                                                                                       --! Reset signal, active low
        i_sys_enable   : in std_logic;                                                                                                       --! System enable signal, active high                                                                                                                                                     
        i_data         : in t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0);  --! Input data (CHANNEL_NUMBER x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
        i_running_mean : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                       --! Input mean vector
        i_weight       : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                       --! Input weight vector
        i_bias         : in t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0);                                                       --! Input bias vector
        i_data_valid   : in std_logic;                                                                                                       --! Data valid signal, active high
        o_data         : out t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0); --! Output data
        o_data_valid   : out std_logic                                                                                                       --! Output valid signal
    );
end batchnorm2d;

architecture batchnorm2d_arch of batchnorm2d is

    -------------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------------
    constant N_OUTPUT_REG : integer := 2;            --! Number of output registers
    constant DFF_DELAY    : integer := N_OUTPUT_REG; --! Total delay due to flip-flops

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal r_o_data             : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Signal Output Data Registers
    signal r_o_data_valid       : std_logic_vector(CHANNEL_NUMBER - 1 downto 0);             --! Signal Output valid signal
    signal current_row          : integer range 0 to INPUT_SIZE - 1;                         --! Current row index
    signal current_col          : integer range 0 to INPUT_SIZE - 1;                         --! Current column index
    signal intermediate_data    : t_vec(CHANNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0); --! Intermediate signal
    signal batchnorm_layer_done : std_logic;

    signal start_processing          : std_logic; --! Signal to start processing
    signal data_valid_previous_state : std_logic; --! Previous state of the data_valid signal
    signal data_valid_delayed        : std_logic; --! Signal Delaying by one clock cycle the valid signal
    signal computation_start         : std_logic; --! Signal indicating if the computation is running or not (triggered by rising_edge of i_data_valid input)

    -------------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------------
    component batchnorm2d_layer
        generic (
            BITWIDTH : integer;
            EPSILON  : integer;
            K        : integer
        );
        port (
            clock        : in std_logic;
            reset_n      : in std_logic;
            i_sys_enable : in std_logic;
            i_data       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_mean       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_weight     : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_bias       : in std_logic_vector(BITWIDTH - 1 downto 0);
            i_valid      : in std_logic;
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
    -- batchnorm2d_layer INSTANTIATION
    -------------------------------------------------------------------------------------
    --! Generate
    --! Instantiate one batchnorm2d_layer per channel
    gen_batchnorm2d_layer : for i in 0 to CHANNEL_NUMBER - 1 generate
        batchnorm2d_layer_inst : batchnorm2d_layer
        generic map(
            BITWIDTH => BITWIDTH,
            EPSILON  => EPSILON,
            K        => 12
        )
        port map(
            clock        => clock,
            reset_n      => reset_n,
            i_sys_enable => i_sys_enable,
            i_data       => intermediate_data(i),
            i_mean       => i_running_mean(i),
            i_weight     => i_weight(i),
            i_bias       => i_bias(i),
            i_valid      => computation_start,
            o_data       => r_o_data(i)
        );
    end generate gen_batchnorm2d_layer;

    -------------------------------------------------------------------------------------
    -- pipeline INSTANTIATION
    -------------------------------------------------------------------------------------
    pipeline_inst : pipeline
    generic map(
        N_STAGES => DFF_DELAY
    )
    port map(
        clock        => clock,
        reset_n      => reset_n,
        i_sys_enable => i_sys_enable,
        i_data       => computation_start,
        o_data       => batchnorm_layer_done
    );

    -- Process to update the intermediate signals
    process (all)
    begin
        for i in 0 to CHANNEL_NUMBER - 1 loop
            intermediate_data(i) <= i_data(i)(current_col)(current_row);
        end loop;
    end process;

    -------------------------------------------------------------------------------------
    -- PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset counters  to initial states.
            current_row               <= 0;
            current_col               <= 0;
            start_processing          <= '0';
            data_valid_previous_state <= '0';
            data_valid_delayed        <= '0';
            computation_start         <= '0';
            o_data                    <= (others => (others => (others => (others => '0'))));

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                -- Update last data_valid signal
                data_valid_previous_state <= i_data_valid;

                -- Check if input data is valid
                if (start_processing = '0' and i_data_valid = '1' and data_valid_previous_state = '0') then
                    start_processing  <= '1';
                    computation_start <= '1';
                else
                    data_valid_delayed <= '0';
                    computation_start  <= '0';
                end if;

                -- If input data is valid, start the index computation
                if (start_processing = '1') then
                    if (batchnorm_layer_done = '1') then

                        -- Start next computation
                        computation_start <= '1';

                        -- Update Output Data
                        for i in 0 to CHANNEL_NUMBER - 1 loop
                            o_data(i)(current_col)(current_row) <= r_o_data(i);
                        end loop;

                        -- Update the new index
                        if current_col = INPUT_SIZE - 1 then
                            current_col <= 0;
                            if current_row = INPUT_SIZE - 1 then
                                current_row        <= 0;
                                data_valid_delayed <= '1';
                                start_processing   <= '0';
                            else
                                current_row <= current_row + 1;
                            end if;
                        else
                            current_col <= current_col + 1;
                        end if;
                    else
                        computation_start <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Output Valid Signal Update
    o_data_valid <= data_valid_delayed;

end architecture;

configuration batchnorm2d_conf of batchnorm2d is
    for batchnorm2d_arch
        for gen_batchnorm2d_layer
            for batchnorm2d_layer_inst : batchnorm2d_layer
                use configuration LIB_RTL.batchnorm2d_layer_conf;
            end for;
        end for;

        for all : pipeline
            use entity LIB_RTL.pipeline(pipeline_arch);
        end for;
    end for;
end configuration batchnorm2d_conf;