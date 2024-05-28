
Entity: mac_layer
=======================


* **File**\ : mac_layer.vhd
* **File:**        mac_layer
* **Brief:**       This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: mac_layer.svg
   :target: mac_layer.svg
   :alt: Diagram


Description
-----------

with a KERNEL_SIZE x KERNEL_SIZE kernel.
It performs convolution operations using a 3x3 kernel over the input data.
Entity mac_layer
This entity implements a pipelined Multiply-Accumulate (MAC) unit with a 3x3 kernel.
It performs convolution operations using a 3x3 kernel over the input data.

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
   * - KERNEL_SIZE
     - integer
     - 3
     - Size of the kernel (ex: 3 for a 3x3 kernel)


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
   * - i_X
     - in
     - t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0)
     - Input data  (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
   * - i_theta
     - in
     - t_vec (0 to KERNEL_SIZE * KERNEL_SIZE - 1)(BITWIDTH - 1 downto 0)
     - Kernel data (KERNEL_SIZE x KERNEL_SIZE x BITWIDTH bits)
   * - o_Y
     - out
     - std_logic_vector (2 * BITWIDTH - 1 downto 0)
     - Output result


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - mac_out
     - t_vec(0 to KERNEL_SIZE * KERNEL_SIZE - 1)(2 * BITWIDTH - 1 downto 0)
     - Intermediate signal to hold the output of each MAC unit in the pipeline.

