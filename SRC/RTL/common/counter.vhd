-----------------------------------------------------------------------------------
--!     @File    counter
--!     @brief   This file provides a generic counter component
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (
        BITWIDTH   : integer := 4; --! Bitwidth
        INIT_VALUE : integer := 0  --! Initialization Value
    );
    port (
        i_clk        : in std_logic;                               --! Clock input
        i_reset      : in std_logic;                               --! Active-low Reset input
        i_enable     : in std_logic;                               --! Enable Input
        i_init_value : in std_logic;                               --! Initialization Value Enable
        o_count      : out std_logic_vector(BITWIDTH - 1 downto 0) --! Output Count Value
    );
end entity counter;

architecture counter_arch of counter is

    --
    -- SIGNALS 
    --

    signal r_count : integer range 0 to 2 ** BITWIDTH - 1 := INIT_VALUE;

begin

    p_counter_seq : process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            r_count <= INIT_VALUE;
            elsif rising_edge(i_clk) then
            if i_init_value = '1' then
                r_count <= INIT_VALUE;
                elsif i_enable = '1' then
                r_count <= (r_count + 1) mod (2 ** BITWIDTH);
            end if;
        end if;
    end process p_counter_seq;

    o_count <= std_logic_vector(to_unsigned(r_count, BITWIDTH));

end architecture;