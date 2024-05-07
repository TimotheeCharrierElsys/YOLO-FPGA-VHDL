
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.utils.all;

entity conv2D_tb is
end;

architecture conv2D_tb_arch of conv2D_tb is

  -- Constants
  constant clk_period : time := 5 ns;

  constant data : matrix_t(0 to 6, 0 to 6) := (
  ("00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000"),
  ("00000000", "00000000", "00000001", "00000010", "00000001", "00000001", "00000000"),
  ("00000000", "00000001", "00000000", "00000000", "00000000", "00000001", "00000000"),
  ("00000000", "00000000", "00000000", "00000000", "00000001", "00000000", "00000000"),
  ("00000000", "00000010", "00000000", "00000001", "00000001", "00000000", "00000000"),
  ("00000000", "00000010", "00000001", "00000010", "00000000", "00000001", "00000000"),
  ("00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000")
  );

  constant kernel : matrix_t(0 to 2, 0 to 2) := (
  ("00000001", "00000000", "00000000"),
  ("00000000", "00000001", "00000000"),
  ("00000000", "00000000", "00000001"));

  -- Generics
  constant INPUT_HEIGHT : integer := 7;
  constant INPUT_WIDTH  : integer := 7;
  constant KERNEL_SIZE  : integer := 3;
  constant STRIDE       : integer := 1;
  -- Ports
  signal clk_s          : std_logic;
  signal reset_s        : std_logic;
  signal data_i_s       : matrix_t(0 to INPUT_HEIGHT - 1, 0 to INPUT_WIDTH - 1);
  signal kernel_s       : matrix_t(0 to KERNEL_SIZE - 1, 0 to KERNEL_SIZE - 1);
  signal data_o_s       : matrix_t(0 to (INPUT_HEIGHT - KERNEL_SIZE)/STRIDE + 1, 0 to (INPUT_WIDTH - KERNEL_SIZE)/STRIDE + 1);
  signal output_valid_s : std_logic;
begin

  UUT : entity work.conv2D
    generic map(
      INPUT_HEIGHT => INPUT_HEIGHT,
      INPUT_WIDTH  => INPUT_WIDTH,
      KERNEL_SIZE  => KERNEL_SIZE,
      STRIDE       => STRIDE
    )
    port map(
      clk_i          => clk_s,
      reset_i        => reset_s,
      data_i         => data_i_s,
      kernel_i       => kernel_s,
      data_o         => data_o_s,
      output_valid_o => output_valid_s
    );

  clk_s    <= not clk_s after clk_period/2;
  reset_s  <= '1', '0' after 10 ns;
  data_i_s <= data;
  kernel_s <= kernel;
end;