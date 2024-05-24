
Entity: pipelined_mac
=====================


* **File**\ : pipelined_mac.vhd
* **Brief:**       This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: pipelined_mac.svg
   :target: pipelined_mac.svg
   :alt: Diagram


Description
-----------

Entity     pipelined_mac
It performs multiplication of two operands followed by an addition
with a third operand. The design is pipelined to improve performance.
Entity pipelined_mac
This entity implements a pipelined Multiply-Accumulate (pipelined_mac) unit.
It multiplies two operands and then adds a third operand.

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
   * - i_A
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - First multiplication operand
   * - i_B
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Second multiplication operand
   * - i_C
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Accumulation operand
   * - o_P
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output result


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - r_A
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Registered version of input operand A.
   * - r_B
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Registered version of input operand B.
   * - r_C
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Registered version of input operand C.
   * - r_mult
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Result of the multiplication of r_A and r_B.
   * - mult_stage_reg
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Registered output of the multiplication stage.
   * - add_stage_reg
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)


Processes
---------


* unnamed: ( clock, reset_n )

  * **Description**
    process
    Handles the synchronous and asynchronous operations of the pipelined pipelined_mac unit.
