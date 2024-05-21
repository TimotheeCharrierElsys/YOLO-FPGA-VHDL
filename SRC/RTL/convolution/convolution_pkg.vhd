-----------------------------------------------------------------------------------
--!     @Package   convolution_pkg
--!     @brief      This package provides the types definitions for a pipelined adder tree.
--!                 It defines the types necessary for creating arrays of std_logic_vectors
--!     @details    The package defines two types: t_vec and t_mat. t_vec is an array
--!                 of std_logic_vectors with an unconstrained range, and t_mat is an
--!                 array of t_vec with an unconstrained range.
--!     @auth       Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package convolution_pkg is

    type t_vec is array (natural range <>) of std_logic_vector;

    type t_mat is array (natural range <>) of t_vec;

    type t_volume is array (natural range <>) of t_mat;

end convolution_pkg;