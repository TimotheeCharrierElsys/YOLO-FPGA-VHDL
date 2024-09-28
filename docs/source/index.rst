CNN in Hardware Description Language
====================================

.. |pic_repository| image:: _static/images/index/repository.svg
  :alt: Repository
  :target: https://github.com/TimotheeCharrierElsys/doc/tree/feat

|pic_repository|

.. note::
   This project is under active development.

.. toctree::
  :maxdepth: 1
  :caption: Table of Contents
  :name: mastertoc

  docs/getting_started
  docs/deep_learning
  docs/conv2d_implementation
  docs/modules


.. toctree::
  :caption: Bibliography

  references

Project Structure
=================

.. code-block:: none

  ../
  ├── README.rst
  ├── docs
  │   ├── Makefile
  │   └── source ...
  ├── requirements.txt
  ├── script
  │   ├── oss_cad_suite_setup.py
  │   └── wsl_setup.sh
  └── src
      ├── Makefile
      ├── bench
      │   ├── batchnorm2d_layer
      │   │   ├── Makefile
      │   │   └── test_batchnorm2d_layer.py
      │   ├── conv
      │   │   ├── Makefile
      │   │   ├── lib.py
      │   │   └── test_conv.py
      │   ├── conv2d
      │   │   ├── Makefile
      │   │   ├── test_conv2d.py
      │   │   └── wolf.jpg
      │   ├── conv2d_layer_mac
      │   │   ├── Makefile
      │   │   └── test_conv2d_layer_mac.py
      │   ├── conv_fsm
      │   │   ├── Makefile
      │   │   └── test_conv_fsm.py
      │   ├── mac
      │   │   ├── Makefile
      │   │   └── test_mac.py
      │   ├── mnist
      │   │   ├── Makefile
      │   │   ├── lib.py
      │   │   └── test_mnist_layers.py
      │   ├── mnist_cnn.pt
      │   ├── model.py
      │   ├── silu_activation
      │   │   ├── Makefile
      │   │   └── test_silu_activation.py
      │   └── utils.py
      └── rtl
          ├── batchnorm2d
          │   ├── batchnorm2d_layer.vhd
          │   └── silu_activation.vhd
          ├── conv
          │   ├── conv.vhd
          │   ├── conv_fsm.vhd
          │   └── mnist_layers.vhd
          ├── conv2d
          │   ├── conv2d_layer.vhd
          │   └── mac.vhd
          └── types_pkg.vhd
  