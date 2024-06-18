-----------------------------------------------------------------------------------
--!     @file       mac
--!     @brief      This entity implements a Multiply-Accumulate (mac) unit.
--!                 It performs multiplication of two operands followed by an addition
--!                 with a third operand.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity mac
--! This entity implements a Multiply-Accumulate (mac) unit.
--!        It multiplies two operands and then adds a third operand.
entity mac is
    generic (
        BITWIDTH : integer := 8 --! Bit width of each operand
    );
    port (
        clock         : in std_logic;                                   --! Clock signal
        reset_n       : in std_logic;                                   --! Reset signal, active low
        i_sys_enable  : in std_logic;                                   --! Global enable signal, active high
        i_multiplier1 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! First multiplication operand
        i_multiplier2 : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Second multiplication operand
        i_add         : in std_logic_vector(BITWIDTH - 1 downto 0);     --! Accumulation operand
        o_result      : out std_logic_vector(2 * BITWIDTH - 1 downto 0) --! Output result
    );
end mac;

architecture mac_arch of mac is

begin
    -------------------------------------------------------------------------------------
    -- PROCESS ASYNC (reset negative)
    -------------------------------------------------------------------------------------
    --! Process
    --! Handles the synchronous and asynchronous operations of the mac unit.
    mac_operation : process (clock, reset_n)
    begin
        if reset_n = '0' then
            -- Reset output register to zeros
            o_result <= (others => '0');
        elsif rising_edge(clock) then
            if (i_sys_enable = '1') then
                -- Perform the multiplication and addition operation
                o_result <= std_logic_vector(signed(i_add) + signed(i_multiplier1) * signed(i_multiplier2));
            end if;
        end if;
    end process mac_operation;
end mac_arch;