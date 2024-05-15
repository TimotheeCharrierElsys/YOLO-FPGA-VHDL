-----------------------------------------------------------------------------------
--!     @Package    conv_pack
--!     @brief      This package provides a function to compute the dot product
--!                 of two vectors represented as arrays of float32.
--!     @author     Timothée Charrier
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package conv_pack is
    subtype t_bit8 is std_logic_vector(7 downto 0);
    subtype t_bit16 is std_logic_vector(15 downto 0);
    subtype t_bit16_signed is signed(15 downto 0);

    type t_in_vec is array (integer range <>) of t_bit8;   --! Input Vector Type
    type t_out_vec is array (integer range <>) of t_bit16; --! Output Vector Type
    type t_int_vec is array (integer range <>) of integer; --! Integer Vector Type

    type t_in_mat is array(integer range <>) of t_in_vec;   --! Input Matrix Type
    type t_out_mat is array(integer range <>) of t_out_vec; --! Output Matrix Type

    function dotproduct (a : t_in_vec; b : t_in_vec) return t_bit16; --! Dot product function

    component matmult_core
        generic (
            VECTOR_SIZE : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_start  : in std_logic;
            i_A      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            i_B      : in t_in_vec(VECTOR_SIZE - 1 downto 0);
            o_result : out t_bit16
        );
    end component;

    component matmult_top
        generic (
            WIDTH  : integer;
            HEIGHT : integer
        );
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_start  : std_logic;
            i_A      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
            i_B      : in t_in_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
            o_result : out t_out_mat(WIDTH - 1 downto 0)(HEIGHT - 1 downto 0);
            o_valid  : out std_logic
        );
    end component;

end package conv_pack;

package body conv_pack is

    -----------------------------------------------------------------------------------
    --! @Function    : dotproduct
    --! @Description : Computes the dot product of two input vectors.
    --!                Each vector is represented as an array of signed 8-bit integers.
    --! @Parameters  :
    --!                - a : Input vector A of type t_in_vec
    --!                - b : Input vector B of type t_in_vec
    --! @Returns     : Dot product of vectors a and b as a signed 16-bit integer.
    -----------------------------------------------------------------------------------
    function dotproduct (a : t_in_vec; b : t_in_vec) return t_bit16 is
        variable sum : integer := 0; -- Accumulator for the dot product
    begin
        -- Dot product computation
        for i in 0 to a'length - 1 loop
            sum := sum + (to_integer(signed(a(i))) * to_integer(signed(b(i)))); -- Accumulate the product of corresponding elements
        end loop;
        return std_logic_vector(to_signed(sum, 16)); -- Return the dot product
    end function dotproduct;
end package body conv_pack;