-----------------------------------------------------------------------------------
--!     @Package    types_pkg
--!     @brief      This package provides the types definitions for the project.
--!                 It defines the types necessary for creating arrays of std_logic_vectors
--!     @details    The package defines two types: t_vec and t_mat. t_vec is an array
--!                 of std_logic_vectors with an unconstrained range, and t_mat is an
--!                 array of t_vec with an unconstrained range. These types are used to
--!                 represent the multi-dimensional arrays.
--!     @auth       Timothée Charrier
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package types_pkg is
    --! @type t_vec
    --! @brief Defines an unconstrained array of std_logic_vectors.
    --!        This type is used to represent a vector of std_logic_vectors.
    type t_vec is array (natural range <>) of std_logic_vector;

    --! @type t_mat
    --! @brief Defines an unconstrained array of t_vec.
    type t_mat is array (natural range <>) of t_vec;

    --! @type t_volume
    --! @brief Defines an unconstrained array of t_mat.
    type t_volume is array (natural range <>) of t_mat;

    --! @type t_input_feature
    --! @brief Defines an unconstrained array of t_mat.
    type t_input_feature is array (natural range <>) of t_volume;

    --! @type function
    --! @brief Defines a function returning a padded input volume
    function pad_input(
        i_data        : t_volume;
        input_width   : integer;
        input_channel : integer;
        padding       : integer;
        bitwidth      : integer
    ) return t_volume;

end package types_pkg;

package body types_pkg is
    function pad_input(
        i_data        : t_volume;
        input_width   : integer;
        input_channel : integer;
        padding       : integer;
        bitwidth      : integer
    ) return t_volume is
        variable padded : t_volume(input_channel - 1 downto 0)(2 * padding + input_width - 1 downto 0)(2 * padding + input_width - 1 downto 0)(bitwidth - 1 downto 0);
    begin
        for ch in 0 to input_channel - 1 loop
            for row in 0 to 2 * padding + input_width - 1 loop
                for col in 0 to 2 * padding + input_width - 1 loop
                    if row < padding or row >= padding + input_width or col < padding or col >= padding + input_width then
                        padded(ch)(row)(col) := (others => '0');
                    else
                        padded(ch)(row)(col) := i_data(ch)(row - padding)(col - padding);
                    end if;
                end loop;
            end loop;
        end loop;
        return padded;
    end pad_input;
end package body types_pkg;