-----------------------------------------------------------------------------------
--!     @Entity     mac
--!     @brief      This entity implements a Multiply-Accumulate (mac) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand.
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! @Entity mac
--! @brief This entity implements a Multiply-Accumulate (mac) unit.
--!        It multiplies two operands and then adds a third operand.
entity mac is
    generic (
        BITWIDTH : integer := 8 --! Bit width of each operand
    );
    port (
        i_clk    : in std_logic;                                   --! Clock signal
        i_rst    : in std_logic;                                   --! Reset signal, active at high state
        i_enable : in std_logic;                                   --! Enable signal, active at high state
        i_A      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
        i_B      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
        i_C      : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Accumulation operand
        o_P      : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result
    );
end mac;

architecture mac_arch of mac is

begin
    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset high)
    -------------------------------------------------------------------------------------
    --! @process
    --! @brief Handles the synchronous and asynchronous operations of the mac unit.
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Reset output register to zeros
            o_P <= (others => '0');
        elsif rising_edge(i_clk) then
            if (i_enable = '1') then
                -- Perform the multiplication and addition operation
                o_P <= std_logic_vector(signed(i_C) + signed(i_A) * signed(i_B));
            end if;
        end if;
    end process;
end mac_arch;