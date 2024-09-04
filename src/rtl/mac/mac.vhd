-----------------------------------------------------------------------------------
--!     @file       mac
--!     @brief      This entity implements a Multiply-Accumulate (MAC) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity mac
--! This entity implements a Multiply-Accumulate (MAC) unit.
--! It multiplies two operands and then adds the output.
entity mac is
    generic (
        DO_MULTIPLICATION : std_logic := '1'; --! Define if it is a MAC ('1') or an adder ('0')
        INPUT_WIDTH       : integer   := 8;   --! Bit width of input operands
        OUTPUT_WIDTH      : integer   := 16   --! Bit width of output result
    );
    port (
        clock        : in std_logic;                                   --! Clock signal
        reset_n      : in std_logic;                                   --! Reset signal, active low
        i_sys_enable : in std_logic;                                   --! Global enable signal, active high
        i_valid      : in std_logic;                                   --! Input Valid, active high
        i_clear      : in std_logic;                                   --! Clear signal, active high
        i_operand1   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);  --! First multiplication operand
        i_operand2   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);  --! Second multiplication operand
        o_result     : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0) --! Output result value
    );
end mac;

architecture mac_arch of mac is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal o_result_reg : std_logic_vector(OUTPUT_WIDTH - 1 downto 0); --! Output result register
    signal sum_result   : std_logic_vector(OUTPUT_WIDTH - 1 downto 0); --! Signal containing the addition result 

begin

    -------------------------------------------------------------------------------------
    -- GENERATE BLOCKS
    -------------------------------------------------------------------------------------
    --! Generate block for multiplication and accumulation
    gen_multiplication : if DO_MULTIPLICATION = '1' generate
        process (i_operand1, i_operand2, o_result_reg)
        begin
            sum_result <= std_logic_vector(signed(o_result_reg) + signed(i_operand1) * signed(i_operand2));
        end process;
    end generate gen_multiplication;

    gen_addition : if DO_MULTIPLICATION = '0' generate
        process (i_operand1, i_operand2, o_result_reg)
        begin
            sum_result <= std_logic_vector(signed(o_result_reg) + signed(i_operand1) + signed(i_operand2));
        end process;
    end generate gen_addition;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the MAC unit.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            o_result_reg <= (others => '0');
        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                -- Assign the sum result to the output register, else clear it
                if i_clear = '1' then
                    o_result_reg <= (others => '0');
                elsif i_valid = '1' then
                    o_result_reg <= sum_result;
                end if;
            else
                o_result_reg <= (others => '0');
            end if;
        end if;
    end process;

    -- Output the result
    o_result <= o_result_reg;

end mac_arch;