-----------------------------------------------------------------------------------
--!     @file       pipeline
--!     @brief      This entity implements a register pipeline
--!                 It delays the input by the constant value N_STAGES
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity pipeline
--! This entity implements a pipeline.
entity pipeline is
    generic (
        N_STAGES : integer := 4 --! Number of pipeline stages
    );
    port (
        clock        : in std_logic; --! Clock signal
        reset_n      : in std_logic; --! Reset signal, active low
        i_sys_enable : in std_logic; --! Global enable signal, active high
        i_data       : in std_logic; --! Input data
        o_data       : out std_logic --! Output data
    );
end pipeline;

architecture pipeline_arch of pipeline is

    -------------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------------
    type reg_array is array (0 to N_STAGES - 1) of std_logic;

    -------------------------------------------------------------------------------------
    -- SIGNAL
    -------------------------------------------------------------------------------------
    signal pipeline_regs : reg_array; --! Pipeline signal

begin

    -------------------------------------------------------------------------------------
    -- GENERATE PROCESS
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the pipeline.
    gen_pipeline : for i in 0 to N_STAGES - 1 generate
        pipeline_control : process (clock, reset_n)
        begin
            if reset_n = '0' then
                pipeline_regs(i) <= '0';
            elsif rising_edge(clock) then
                if i_sys_enable = '1' then
                    if i = 0 then
                        pipeline_regs(i) <= i_data;
                    else
                        pipeline_regs(i) <= pipeline_regs(i - 1);
                    end if;
                end if;
            end if;
        end process pipeline_control;
    end generate;

    -- Output the last stage of the pipeline
    o_data <= pipeline_regs(N_STAGES - 1);

end pipeline_arch;