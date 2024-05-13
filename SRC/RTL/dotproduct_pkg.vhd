------------------------------------------------------------------------------
--! @Package     : dotproduct_pkg
--! @Description : This package provides a function to compute the dot product
--!                of two vectors represented as arrays of float32.
--! @Author      : Timothée Charrier
--! Version      : 1.0
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dotproduct_pkg is
    constant c_N : integer := 2; -- Size of the vectors

    subtype t_bit8 is std_logic_vector(7 downto 0);
    subtype t_bit16 is std_logic_vector(15 downto 0);
    type t_in_vec is array (0 to c_N - 1) of t_bit8;   -- !Input vector type
    type t_out_vec is array (0 to c_N - 1) of t_bit16; --! Output vector type

    function dotproduct (a : t_in_vec; b : t_in_vec) return t_bit16; -- !Dot product function

end package dotproduct_pkg;

package body dotproduct_pkg is

    ---------------------------------------------------------------------------------
    --! @Function    : dotproduct
    --! @Description : Computes the dot product of two input vectors.
    --!                Each vector is represented as an array of signed 8-bit integers.
    --! @Parameters  :
    --!                - a : Input vector A of type t_in_vec
    --!                - b : Input vector B of type t_in_vec
    --! @Returns     : Dot product of vectors a and b as a signed 16-bit integer.
    ---------------------------------------------------------------------------------
    function dotproduct (a : t_in_vec; b : t_in_vec) return t_bit16 is
        variable sum : t_bit16 := (others => '0'); -- !Accumulator for the dot product

    begin
        -- Dot product computation
        for i in 0 to a'length - 1 loop
            sum := std_logic_vector(signed(sum) + (signed(a(i)) * signed(b(i)))); -- Accumulate the product of corresponding elements
        end loop;
        return sum; -- Return the dot product
    end function dotproduct;

end package body dotproduct_pkg;