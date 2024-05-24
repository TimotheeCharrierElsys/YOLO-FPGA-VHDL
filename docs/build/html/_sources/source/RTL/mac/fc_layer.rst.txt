
Entity: fc_layer
================


* **File**\ : fc_layer.vhd
* **File:**        fc_layer
* **Brief:**       This entity implements a pipelined fully connected layer.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: fc_layer.svg
   :target: fc_layer.svg
   :alt: Diagram


Description
-----------

It performs multiplication and then additions
Entity fc_layer
This entity implements a full connected layer layer using an adder tree.

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
   * - VECTOR_SIZE
     - integer
     - 8
     - Input Vector Size


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
     - t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input data
   * - i_weight
     - in
     - t_vec(VECTOR_SIZE - 1 downto 0)(BITWIDTH - 1 downto 0)
     - Input weights
   * - o_sum
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output value


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - r_mult_to_add
     - t_vec(VECTOR_SIZE - 1 downto 0)(2 * BITWIDTH - 1 downto 0)
     - Signal between the multiplications and the additions
   * - r_sum
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output signal register


Instantiations
--------------


* adder_tree_inst: adder_tree
