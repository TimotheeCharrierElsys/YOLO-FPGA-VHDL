------------------------------------------------------------------------------
--! @Package     : matmult_pkg
--! @Description : This package provides a function to compute the matrix
--!                multiplciation of two matrix of signed numbers.
--! @Author      : Timothée Charrier
--! Version      : 1.0
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package matmult_pkg is
    constant c_N : integer := 2; -- Size of the vectors

    subtype t_signed8 is signed(7 downto 0);
    subtype t_signed16 is signed(15 downto 0);

    type t_in_vec is array(0 to c_N - 1) of t_signed8; --! Input vector Type
    type t_in_mat is array(0 to c_N - 1) of t_in_vec;  --! Input Matrix Type

    type t_out_vec is array(0 to c_N - 1) of t_signed16; --! Output vector Type
    type t_out_mat is array(0 to c_N - 1) of t_out_vec; --! Ouput Matrix Type 

    function dotproduct (a : t_in_vec; b : t_in_vec) return t_signed16; --! Dot product function

end package matmult_pkg;

package body matmult_pkg is

    ---------------------------------------------------------------------------------
    --! @Function    : dotproduct
    --! @Description : Computes the dot product of two input vectors.
    --!                Each vector is represented as an array of signed 8-bit integers.
    --! @Parameters  :
    --!                - a : Input vector A of type t_in_vec
    --!                - b : Input vector B of type t_in_vec
    --! @Returns     : Dot product of vectors a and b as a signed 16-bit integer.
    ---------------------------------------------------------------------------------
    function dotproduct (a : t_in_vec; b : t_in_vec) return t_signed16 is
        variable sum : t_signed16 := (others => '0'); -- !Accumulator for the dot product

    begin
        -- Dot product computation
        for i in 0 to a'length - 1 loop
            sum := sum + (a(i) * b(i)); -- Accumulate the product of corresponding elements
        end loop;
        return sum; -- Return the dot product
    end function dotproduct;

end package body matmult_pkg;