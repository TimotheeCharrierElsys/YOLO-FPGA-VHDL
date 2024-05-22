-----------------------------------------------------------------------------------
--!     @Entity     mac
--!     @brief      This entity implements a pipelined Multiply-Accumulate (MAC) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand. The design is pipelined to improve performance.
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! @Entity mac
--! @brief This entity implements a pipelined Multiply-Accumulate (MAC) unit.
--!        It multiplies two operands and then adds a third operand.
entity mac is
    generic (
        BITWIDTH : integer := 8 --! Bit width of each operand
    );
    port (
        i_clk : in std_logic;                                   --! Clock signal
        i_rst : in std_logic;                                   --! Reset signal
        i_A   : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
        i_B   : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
        i_C   : in std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Accumulation operand
        o_P   : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result
    );
end mac;

architecture mac_arch of mac is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------

    signal r_A            : std_logic_vector(BITWIDTH - 1 downto 0);     --! Registered version of input operand A.
    signal r_B            : std_logic_vector(BITWIDTH - 1 downto 0);     --! Registered version of input operand B.
    signal r_C            : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Registered version of input operand C.
    signal r_mult         : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Result of the multiplication of r_A and r_B.
    signal mult_stage_reg : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Registered output of the multiplication stage.
    signal add_stage_reg  : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! Registered output of the addition stage.

begin

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset high)
    -------------------------------------------------------------------------------------
    --! @process
    --! @brief Handles the synchronous and asynchronous operations of the pipelined MAC unit.
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Reset all registers to zero
            r_A            <= (others => '0');
            r_B            <= (others => '0');
            r_C            <= (others => '0');
            r_mult         <= (others => '0');
            mult_stage_reg <= (others => '0');
            add_stage_reg  <= (others => '0');
        elsif rising_edge(i_clk) then
            -- Stage 1: Register inputs
            r_A <= i_A;
            r_B <= i_B;
            r_C <= i_C;

            -- Stage 2: Perform multiplication and register the result
            mult_stage_reg <= std_logic_vector(signed(r_A) * signed(r_B));

            -- Stage 3: Perform addition with registered multiplier output and register the result
            add_stage_reg <= std_logic_vector(signed(mult_stage_reg) + signed(r_C));
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- OUTPUT ASSIGNMENT
    -------------------------------------------------------------------------------------
    o_P <= add_stage_reg;

end mac_arch;