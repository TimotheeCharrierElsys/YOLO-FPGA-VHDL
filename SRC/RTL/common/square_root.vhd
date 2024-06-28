-----------------------------------------------------------------------------------
--!     @file       square_root_implementation
--!     @brief      This entity implements a square_root module
--!                 It uses hardswish approximation function.
--!                 See https://stackoverflow.com/questions/40779152/how-to-find-square-root-number-in-vhdl for original code
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--! Entity square_root
--! This entity implements an approximated square_root function.
entity square_root is
    generic (
        BITWIDTH : integer := 16);
    port (
        clock        : in std_logic;                                  --! Clock signal
        reset_n      : in std_logic;                                  --! Reset signal, active low
        i_sys_enable : in std_logic;                                  --! Global enable signal, active high
        i_data       : in std_logic_vector (BITWIDTH - 1 downto 0);   --! Input data
        o_data       : out std_logic_vector (BITWIDTH/2 - 1 downto 0) --! Output data
    );
end square_root;

architecture square_root_arch of square_root is

begin

    --! Process
    --! Handles the output update
    process (clock, reset_n)
        variable vop  : unsigned(BITWIDTH - 1 downto 0);
        variable vres : unsigned(BITWIDTH - 1 downto 0);
        variable vone : unsigned(BITWIDTH - 1 downto 0);
    begin
        if reset_n = '0' then
            o_data <= (others => '0');

        elsif rising_edge(clock) then
            if i_sys_enable = '1' then

                vone := to_unsigned(2 ** (BITWIDTH - 2), BITWIDTH);
                vop  := unsigned(i_data);
                vres := (others => '0');
                while (vone /= 0) loop
                    if (vop >= vres + vone) then
                        vop  := vop - (vres + vone);
                        vres := vres/2 + vone;
                    else
                        vres := vres/2;
                    end if;
                    vone := vone/4;
                end loop;

                o_data <= std_logic_vector(vres(o_data'range));

            end if;
        end if;
    end process;
end;