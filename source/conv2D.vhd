library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library LIB_RTL;
use LIB_RTL.utils.all;

entity conv2D is
  generic (
    INPUT_HEIGHT : integer := 32; --! Number of rows in input matrix
    INPUT_WIDTH  : integer := 32; --! Number of columns in input matrix
    KERNEL_SIZE  : integer := 3;  --! Size of convolution kernel
    STRIDE       : integer := 1   --! Convolution stride
  );
  port (
    -- Clock and Reset Ports
    clk_i   : in std_logic; --! Input Clock
    reset_i : in std_logic; --! Input Reset

    -- Data Ports
    data_i   : in matrix_t(0 to INPUT_HEIGHT - 1, 0 to INPUT_WIDTH - 1);                                                --! Input Data Matrix
    kernel_i : in matrix_t(0 to KERNEL_SIZE - 1, 0 to KERNEL_SIZE - 1);                                                 --! Input kernel Matrix
    data_o   : out matrix_t(0 to (INPUT_HEIGHT - KERNEL_SIZE)/STRIDE + 1, 0 to (INPUT_WIDTH - KERNEL_SIZE)/STRIDE + 1); --! Output Matrix

    -- Control Ports
    output_valid_o : out std_logic
  );
end entity conv2D;

architecture conv2D_arch of conv2D is

  signal sum_unsigned_s : unsigned(31 downto 0); --! Accumulator for the dot product
begin

  process (clk_i, reset_i)
  begin
    if reset_i = '1' then
      -- TODO: reset
    elsif rising_edge(clk_i) then
      -- Convolution operation
      for i in 0 to (INPUT_HEIGHT - KERNEL_SIZE)/STRIDE loop
        for j in 0 to (INPUT_WIDTH - KERNEL_SIZE)/STRIDE loop
          data_o(i, j)   <= (others => '0');
          sum_unsigned_s <= (others => '0');

          -- Compute dot product
          for k in 0 to KERNEL_SIZE - 1 loop
            for l in 0 to KERNEL_SIZE - 1 loop
              sum_unsigned_s <= sum_unsigned_s + -- Accumulation
                unsigned(data_i(i + k, j + l)) *   -- Convert std_logic_vector to unsigned
                unsigned(kernel_i(k, l));          -- Same for the kernel
            end loop;
          end loop;

          data_o(i, j) <= std_logic_vector(sum_unsigned_s(7 downto 0));
        end loop;
      end loop;
    end if;
  end process;
end architecture;