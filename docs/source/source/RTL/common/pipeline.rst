
Entity: pipeline
================


* **File**\ : pipeline.vhd
* **File:**        pipeline
* **Brief:**       This entity implements a register pipeline
* **Author:**      Timothée Charrier

Diagram
-------


.. image:: pipeline.svg
   :target: pipeline.svg
   :alt: Diagram


Description
-----------

It delays the input by the constant value N_STAGES
Entity pipeline
This entity implements a pipeline.

Generics
--------

.. list-table::
   :header-rows: 1

   * - Generic name
     - Type
     - Value
     - Description
   * - N_STAGES
     - integer
     - 4
     - Number of pipeline stages


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
   * - i_data
     - in
     - std_logic
     - Input data
   * - o_data
     - out
     - std_logic
     - Output data


Signals
-------

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - pipeline_regs
     - reg_array


Types
-----

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - reg_array
     - 
     - 

