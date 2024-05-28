-----------------------------------------------------------------------------------
--!     Entity      mac_w_mux
--!     @brief      This entity implements a Multiply-Accumulate (MAC) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity mac_w_mux
--! This entity implements a Multiply-Accumulate (MAC) unit.
--! It multiplies two operands and then adds a third operand.
entity mac_w_mux is
    generic (
        BITWIDTH : integer := 8 --! Bit width of each operand
    );
    port (
        clock         : in std_logic;                                   --! Clock signal
        reset_n       : in std_logic;                                   --! Reset signal, active at low state
        i_enable      : in std_logic;                                   --! Enable signal, active at low state
        i_sel         : in std_logic;                                   --! Select signal for the MUX (1 for (bias + mult), 0 for (output + mult))
        i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
        i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
        i_bias        : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Input addend value
        o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result value
    );
end mac_w_mux;

architecture mac_w_mux_arch of mac_w_mux is

    -------------------------------------------------------------------------------------
    -- SIGNALS
    -------------------------------------------------------------------------------------
    signal mac_out : std_logic_vector(2 * BITWIDTH - 1 downto 0); --! MUX output value

begin

    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the MAC unit.
    process (clock, reset_n)
        variable v_mux : std_logic_vector(2 * BITWIDTH - 1 downto 0);
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            mac_out <= (others => '0');
        elsif rising_edge(clock) then
            if (i_enable = '1') then

                -- MUX update based on i_sel signal
                --      If i_sel is '0', mux_out takes the output value          
                --      If i_sel is '1', mux_out takes the resized value of i_bias
                if i_sel = '0' then
                    v_mux := mac_out; --! Select Output value
                else
                    v_mux := std_logic_vector(resize(signed(i_bias), mac_out'length)); --! Select Bias
                end if;

                -- Multiplication and addition
                mac_out <= std_logic_vector(signed(v_mux) + signed(i_multiplier1) * signed(i_multiplier2));
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------------------
    -- OUTPUT ASSIGNMENT
    -------------------------------------------------------------------------------------
    o_result <= mac_out;

end mac_w_mux_arch;