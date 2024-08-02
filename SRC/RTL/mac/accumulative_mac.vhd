-----------------------------------------------------------------------------------
--!     @file       accumulative_mac
--!     @brief      This entity implements a Multiply-Accumulate (MAC) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity accumulative_mac
--! This entity implements a Multiply-Accumulate (MAC) unit.
--! It multiplies two operands and then adds the output.
entity accumulative_mac is
    generic (
        DO_MULTIPLICATION : std_logic := '1'; --! Define if it is a mac ('1') or an additionner ('0')
        INPUT_WIDTH       : integer   := 8;   --! Bit width of input operands
        OUTPUT_WIDTH      : integer   := 16   --! Bit width of output result
    );
    port (
        clock        : in std_logic;                                   --! Clock signal
        reset_n      : in std_logic;                                   --! Reset signal, active low
        i_sys_enable : in std_logic;                                   --! Global enable signal, active high
        i_clear      : in std_logic;                                   --! Clear signal, active high
        i_operand1   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);  --! First multiplication operand
        i_operand2   : in std_logic_vector(INPUT_WIDTH - 1 downto 0);  --! Second multiplication operand
        o_result     : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0) --! Output result value
    );
end accumulative_mac;

architecture accumulative_mac_arch of accumulative_mac is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out               : std_logic_vector(OUTPUT_WIDTH - 1 downto 0); --! MUX output value
    signal multiplication_result : std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
    signal sum_result            : std_logic_vector(OUTPUT_WIDTH - 1 downto 0);

begin

    gen_multiplication : if DO_MULTIPLICATION = '1' generate
        process (all)
        begin
            multiplication_result <= std_logic_vector(signed(i_operand1) * signed(i_operand2));
            sum_result            <= std_logic_vector(signed(mac_out) + signed(multiplication_result));
        end process;
    end generate gen_multiplication;

    do_not_gen_multiplication : if DO_MULTIPLICATION = '0' generate
        process (all)
        begin
            sum_result <= std_logic_vector(resize(signed(i_operand1), OUTPUT_WIDTH) + signed(mac_out));
        end process;
    end generate do_not_gen_multiplication;

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the MAC unit.
    process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            mac_out <= (others => '0');
        elsif rising_edge(clock) then
            if i_sys_enable = '1' then
                if i_clear = '1' then
                    mac_out <= (others => '0');
                else
                    mac_out <= sum_result(OUTPUT_WIDTH - 1 downto 0);
                end if;
            end if;
        end if;
    end process;

    -- Output update
    o_result <= mac_out;

end accumulative_mac_arch;