-----------------------------------------------------------------------------------
--!     @File    register_gen
--!     @brief   This file provides a generic register_gen component
--!     @author  Timothée Charrier
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_gen is
    generic (
        BITWIDTH : integer := 16 --! Bitwidth
    );
    port (
        i_clk    : in std_logic;                               --! Clock input
        i_reset  : in std_logic;                               --! Active-low Reset input
        i_enable : in std_logic;                               --! Enable Input
        i_data   : in std_logic_vector(BITWIDTH - 1 downto 0); --! Input Data
        o_data   : out std_logic_vector(BITWIDTH - 1 downto 0) --! Output Data
    );
end entity register_gen;

architecture register_gen_arch of register_gen is

    --
    -- SIGNALS 
    --

    signal r_data : std_logic_vector(BITWIDTH - 1 downto 0); --! Registered Data

begin

    p_register_gen_seq : process (i_clk, i_reset)
    begin
        -- Reset the registered data if i_reset is asserted
        if i_reset = '1' then
            r_data <= (others => '0');
            
        -- Load input data into the register on each rising clock edge if i_enable is asserted
        elsif rising_edge(i_clk) then
            if i_enable = '1' then
                r_data <= i_data;
            end if;
        end if;
    end process p_register_gen_seq;

    o_data <= r_data;

end architecture;