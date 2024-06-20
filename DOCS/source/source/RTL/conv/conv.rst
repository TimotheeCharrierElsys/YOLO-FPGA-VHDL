
Entity: conv
============


* **File**\ : conv.vhd
* **File:**        conv
* **Brief:**       This entity implements a convolution using conv_layer units
* **Details:**     This entity takes an input matrix volume and applies convolution
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: conv.svg
   :target: conv.svg
   :alt: Diagram


Description
-----------

using multiple kernels, producing an output matrix.
Entity conv
This entity implements a convolution operation

Generics
--------

.. list-table::
   :header-rows: 1

   * - Generic name
     - Type
     - Value
     - Description
   * - BITWIDTH
     - integer
     - 8
     - Bit width of each operand
   * - INPUT_SIZE
     - integer
     - 64
     - Width and Height of the input
   * - CHANNEL_NUMBER
     - integer
     - 3
     - Number of channels in the input
   * - KERNEL_SIZE
     - integer
     - 3
     - Size of the kernel
   * - KERNEL_NUMBER
     - integer
     - 3
     - Number of kernels
   * - PADDING
     - integer
     - 1
     - Padding value
   * - STRIDE
     - integer
     - 2
     - Stride value


Ports
-----

.. list-table::
   :header-rows: 1

   * - Port name
     - Direction
     - Type
     - Description
   * - clock
     - in
     - std_logic
     - Clock signal
   * - reset_n
     - in
     - std_logic
     - Reset signal, active low
   * - i_sys_enable
     - in
     - std_logic
     - System enable signal, active high
   * - i_data
     - in
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_SIZE - 1 downto 0)(INPUT_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input data (CHANNEL_NUMBER x (INPUT_SIZE x INPUT_SIZE x BITWIDTH) bits)
   * - i_data_valid
     - in
     - std_logic
     - Data valid signal, active high
   * - i_kernel
     - in
     - t_input_feature(KERNEL_NUMBER - 1 downto 0)(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Kernel data (KERNEL_NUMBER x CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
   * - i_bias
     - in
     - t_vec(KERNEL_NUMBER - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input bias value
   * - o_data
     - out
     - t_volume(KERNEL_NUMBER - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)((INPUT_SIZE + 2 * PADDING - KERNEL_SIZE)/STRIDE + 1 - 1 downto 0)(2 * BITWIDTH - 1 downto 0)
     - Output data
   * - o_data_valid
     - out
     - std_logic
     - Output valid signal


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - padded_input_data
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(INPUT_PADDED_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Matrix volume with input padded on all channels
   * - sliced_input_volume
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Sliced volume for conv_layer input
   * - output_data_reg
     - t_volume(KERNEL_NUMBER - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(OUTPUT_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0)
     - Register to store the output data
   * - conv_result
     - t_vec(KERNEL_NUMBER - 1 downto 0)(2 * BITWIDTH - 1 downto 0)
     - Output result of the conv_layer
   * - conv_start
     - std_logic
     - Signal to start convolution
   * - conv_layer_done
     - std_logic
     - Signal indicating convolution layer completion
   * - row_index
     - std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
     - Current row index
   * - col_index
     - std_logic_vector(integer(ceil(log2(real(OUTPUT_SIZE)))) - 1 downto 0)
     - Current column index


Constants
---------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Value
     - Description
   * - INPUT_PADDED_SIZE
     - integer
     - INPUT_SIZE + 2 * PADDING
     - Input matrix size with padding
   * - OUTPUT_SIZE
     - integer
     - (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1
     - Size of the output


Processes
---------


* comb_proc: ( i_data )
* conv_control: ( clock, reset_n )

  * **Description**
    Process handling synchronous and asynchronous operations of the convolution

Instantiations
--------------


* volume_slice_inst: volume_slice
