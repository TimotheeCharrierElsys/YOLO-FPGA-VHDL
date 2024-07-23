
Entity: accumulative_mac
========================


* **File**\ : accumulative_mac.vhd
* **File:**        accumulative_mac
* **Brief:**       This entity implements a Multiply-Accumulate (MAC) unit.
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: accumulative_mac.svg
   :target: accumulative_mac.svg
   :alt: Diagram


Description
-----------

It performs multiplication of two operands followed by an addition
with a third operand.
Entity accumulative_mac
This entity implements a Multiply-Accumulate (MAC) unit.
It multiplies two operands and then adds the output.

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
     - Reset signal, active low
   * - i_sys_enable
     - in
     - std_logic
     - Global enable signal, active high
   * - i_clear
     - in
     - std_logic
     - Clear signal, active high
   * - i_multiplier1
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - First multiplication operand
   * - i_multiplier2
     - in
     - std_logic_vector(BITWIDTH - 1 downto 0)
     - Second multiplication operand
   * - o_result
     - out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)
     - Output result value


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - mac_out
     - std_logic_vector(2 * BITWIDTH - 1 downto 0)


Processes
---------


* unnamed: ( clock, reset_n )

  * **Description**
    Process
    Handles the synchronous and asynchronous operations of the MAC unit.
