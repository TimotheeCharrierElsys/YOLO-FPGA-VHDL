
Entity: conv2d_layer
====================


* **File**\ : conv2d_layer.vhd
* **File:**        conv2d_layer
* **Brief:**       This entity implements a convolution layer using three different architectures.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: conv2d_layer.svg
   :target: conv2d_layer.svg
   :alt: Diagram


Description
-----------

It performs conv2d_layer operations.
Entity conv2d_layer
This entity implements a convolution layer using a pipelined MAC unit with a 3x3 kernel.

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
   * - CHANNEL_NUMBER
     - integer
     - 3
     - Number of channels in the image
   * - KERNEL_SIZE
     - integer
     - 3
     - Size of the kernel (e.g., 3 for a 3x3 kernel)


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
     - Reset signal, active at low state
   * - i_sys_enable
     - in
     - std_logic
     - Enable signal, active at high state
   * - i_valid
     - in
     - std_logic
     - Valid signal, one clock cyle active high state
   * - i_data
     - in
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
   * - i_kernels
     - in
     - t_volume(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
   * - i_bias
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Input bias value
   * - o_result
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output value
   * - o_valid
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
   * - r_results
     - t_vec(CHANNEL_NUMBER downto 0)(2 * BITWIDTH - 1 downto 0)
     - Intermediate signal to hold the output of each MAC unit for each channel. Add the bias to the vector.


Constants
---------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Value
     - Description
   * - N_ADDITION_REG
     - integer
     - 1
     - Number of addition registers.
   * - N_OUTPUT_REG
     - integer
     - 1
     - Number of output registers.
   * - DFF_DELAY_UNPIPELINED
     - integer
     - N_ADDITION_REG + N_OUTPUT_REG + 1
     - Total delay when not pipelined


Instantiations
--------------


* pipeline_inst: pipeline
* adder_tree_inst: adder_tree
