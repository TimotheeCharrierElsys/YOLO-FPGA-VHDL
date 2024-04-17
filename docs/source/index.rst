Welcome to the YOLO implementation on FPGA's documentation!
===========================================================

.. note::
   This project is under active development.

.. warning::
  In case ``enable_output_register`` is set, the implementation does not keep track of
  the exact level on the write side. When there is no word in the output register,
  e.g when the FIFO is empty, the ``write_level`` reported will be one higher than the
  real level.


.. toctree::
      getting-started
      code/module_common.rst