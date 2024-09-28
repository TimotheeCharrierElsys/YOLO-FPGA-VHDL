Conv2d Implementation
**********************

This document describes the implementation of the Conv2D layer.

1. **Introduction**
#######################################


Output Table
############

This is an example of the output of the conv2d layer where the input image is a 64x64 RGB image. The hyperparameters
used are: *Stride=1*, *Padding=1* and with a *Kernel Size=3*. The output size is a 64x64 gray image.

.. raw:: html
   :file: ../_static/html/conv2d_implementation/input_image.html

+-----------+------------------+------------------------------------------------------------------+
| Operation |     Kernels      |                           Image result                           |
+===========+==================+==================================================================+
| Blur      | .. math::        | .. image:: ../_static/images/conv2d_implementation/blur.png      |
|           |                  |                                                                  |
|           |   \frac{1}{9}    |                                                                  |
|           |   \begin{bmatrix}|                                                                  |
|           |   1 & 1 & 1 \\   |                                                                  |
|           |   1 & 1 & 1 \\   |                                                                  |
|           |   1 & 1 & 1      |                                                                  |
|           |   \end{bmatrix}  |                                                                  |
|           |                  |                                                                  |
+-----------+------------------+------------------------------------------------------------------+
| Edge      | .. math::        | .. image:: ../_static/images/conv2d_implementation/edge.png      |
|           |                  |                                                                  |
|           |   \begin{bmatrix}|                                                                  |
|           |   -1 & -1 & -1 \\|                                                                  |
|           |   -1 & 8 & -1 \\ |                                                                  |
|           |   -1 & -1 & -1   |                                                                  |
|           |   \end{bmatrix}  |                                                                  |
|           |                  |                                                                  |
+-----------+------------------+------------------------------------------------------------------+
| Emboss    | .. math::        | .. image:: ../_static/images/conv2d_implementation/emboss.png    |
|           |                  |                                                                  |
|           |   \begin{bmatrix}|                                                                  |
|           |   -2 & -1 & 0 \\ |                                                                  |
|           |   -1 & 1 & 1 \\  |                                                                  |
|           |   0 & 1 & 2      |                                                                  |
|           |   \end{bmatrix}  |                                                                  |
|           |                  |                                                                  |
+-----------+------------------+------------------------------------------------------------------+
| Prewitt X | .. math::        | .. image:: ../_static/images/conv2d_implementation/prewitt_x.png |
|           |                  |                                                                  |
|           |   \begin{bmatrix}|                                                                  |
|           |   -1 & 0 & 1 \\  |                                                                  |
|           |   -1 & 0 & 1 \\  |                                                                  |
|           |   -1 & 0 & 1     |                                                                  |
|           |   \end{bmatrix}  |                                                                  |
|           |                  |                                                                  |
+-----------+------------------+------------------------------------------------------------------+
| Sobel Y   | .. math::        | .. image:: ../_static/images/conv2d_implementation/sobel_y.png   |
|           |                  |                                                                  |
|           |   \begin{bmatrix}|                                                                  |
|           |   -1 & -2 & -1 \\|                                                                  |
|           |   0 & 0 & 0 \\   |                                                                  |
|           |   1 & 2 & 1      |                                                                  |
|           |   \end{bmatrix}  |                                                                  |
|           |                  |                                                                  |
+-----------+------------------+------------------------------------------------------------------+
