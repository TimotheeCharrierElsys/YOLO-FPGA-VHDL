-----------------------------------------------------------------------------------
--!     @Package    binary_adder_tree_pkg
--!     @brief      This package provides the types definitions for a binary adder tree.
--!                 It defines the types necessary for creating arrays of std_logic_vectors
--!                 and pipelines used in the pipelined BAT entity.
--!     @details    The package defines two types: t_vec and t_mat. t_vec is an array
--!                 of std_logic_vectors with an unconstrained range, and t_mat is an
--!                 array of t_vec with an unconstrained range. These types are used to
--!                 represent the multi-dimensional arrays required for the pipelined adder.
--!     @auth       Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package binary_adder_tree_pkg is
    --! @type t_vec
    --! @brief Defines an unconstrained array of std_logic_vectors.
    --!        This type is used to represent a vector of std_logic_vectors, 
    --!        each of which can represent an operand in the adder tree.
    type t_vec is array (natural range <>) of std_logic_vector;

    --! @type t_mat
    --! @brief Defines an unconstrained array of t_vec.
    --!        This type is used to represent the pipeline stages in the adder tree.
    --!        Each element of the array is a t_vec, corresponding to the outputs
    --!        of one stage of the pipeline.
    type t_mat is array (natural range <>) of t_vec;

end package binary_adder_tree_pkg;