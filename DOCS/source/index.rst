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
  :maxdepth: 1
  :caption: User guide

  getting_started
  convolution
  activation_function

.. toctree::
  :maxdepth: 0
  :caption: RTL

  source/RTL/types_pkg
  source/RTL/common/adder_tree
  source/RTL/common/pipeline
  source/RTL/mac/mac
  source/RTL/mac/accumulative_mac
  source/RTL/mac/fc_layer
  source/RTL/conv/conv_layer
  source/RTL/window_slice/volume_slice
  source/RTL/conv/conv

.. toctree::
  :caption: Modules

  modules/common/doc/module_common

.. toctree::
  :caption: Bibliography

  references
  