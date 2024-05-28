Welcome to the YOLO implementation on FPGA's documentation!
===========================================================

.. |pic_repository| image:: fig/repository.svg
  :alt: Repository
  :target: https://github.com/TimotheeCharrierElsys/doc/tree/dev

|pic_repository|

.. note::
   This project is under active development.

.. warning::
  In case ``enable_output_register`` is set, the implementation does not keep track of
  the exact level on the write side. When there is no word in the output register,
  e.g when the FIFO is empty, the ``write_level`` reported will be one higher than the
  real level.

.. toctree::
  :caption: User guide

  getting_started

.. toctree::
  :caption: RTL

  source/RTL/types_pkg
  source/RTL/adder_tree/adder_tree
  source/RTL/adder_tree/binary_adder_tree
  source/RTL/mac/mac
  source/RTL/mac/pipelined_mac
  source/RTL/mac/mac_layer
  source/RTL/mac/fc_layer
  source/RTL/conv/conv_layer
  source/RTL/conv/conv_layer_fc_tb

.. toctree::
  :caption: Modules

  modules/common/doc/module_common

.. toctree::
  :caption: Bibliography

  references
  