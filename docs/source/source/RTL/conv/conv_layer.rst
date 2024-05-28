
Entity: conv_layer
==================


* **File**\ : conv_layer.vhd
* **File:**        conv_layer
* **Brief:**       This entity implements a convolution layer using three different architectures.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: conv_layer.svg
   :target: conv_layer.svg
   :alt: Diagram


Description
-----------

It performs conv_layer operations.
Entity conv_layer
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
   * - i_enable
     - in
     - std_logic
     - Enable signal, active at low state
   * - i_data
     - in
     - t_mat(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE * KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input data  (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
   * - i_kernels
     - in
     - t_mat(CHANNEL_NUMBER - 1 downto 0)(KERNEL_SIZE * KERNEL_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Kernel data (CHANNEL_NUMBER x (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH) bits)
   * - i_bias
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Input bias value
   * - o_Y
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
   * - mac_out
     - t_vec(0 to CHANNEL_NUMBER - 1)(2 * BITWIDTH - 1 downto 0)
     - Intermediate signal to hold the output of each MAC unit for each channel.
   * - r_count
     - integer range 0 to KERNEL_SIZE * KERNEL_SIZE - 1
     - Counter for o_valid data


Processes
---------


* unnamed: ( clock, reset_n )
