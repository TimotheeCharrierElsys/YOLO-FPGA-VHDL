--! --------------------------------------------------------------------
--!   Title     :  Utils Package for the project
--!             :
--!   Library   :  This package shall be compiled into a library
--!             :  symbolically named utils.
--!             :
--!             :
--!   Note      : This package contains utility functions and types
--              : essential for the project.
--!             :
-- --------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is

  -- Types
  type matrix_t is array(natural range <>, natural range <>) of std_logic_vector(7 downto 0); --! Type Declaration: matrix of integer range -128 to 127

end package utils;