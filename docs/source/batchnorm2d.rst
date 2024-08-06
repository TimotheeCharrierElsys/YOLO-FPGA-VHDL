Batchnorm2d Layer
=================

This document describes the implementation choices and considerations for implementing the Batchnorm2d layer in VHDL
Some part are extracted from `Pytorch, BatchNorm2d documentation <https://pytorch.org/docs/stable/_modules/torch/nn/modules/batchnorm.html#BatchNorm2d>`__ .

**1. Overwiew**
---------------

4D is a mini-batch of 2D inputs with additional channel dimension. Method described in the paper
`Batch Normalization: Accelerating Deep Network Training by Reducing Internal Covariate Shift <https://arxiv.org/abs/1502.03167>`__ .

.. math::

    y = \frac{x - \mathrm{E}[x]}{ \sqrt{\mathrm{Var}[x] + \epsilon}} * \gamma + \beta

The mean and standard-deviation are calculated per-dimension over
the mini-batches and :math:`\gamma` and :math:`\beta` are learnable parameter vectors
of size `C` (where `C` is the number of features or channels of the input).

**2. Square Root Hardware Implementation**
------------------------------------------

A square root implementation was found on `Stack Overflow <https://stackoverflow.com/questions/40779152/how-to-find-square-root-number-in-vhdl>`__ using Mr. Crenshaw's algorithm. This leads to an implementation using only addition/substraction and arithmetic shifts.
The higher the bit width, the heavier the computation.

.. code-block:: vhdl
    :caption: Algorithm used for efficient square root

    vone := to_unsigned(2 ** (BITWIDTH - 2), BITWIDTH);
    vop  := unsigned(i_data);
    vres := (others => '0');
    while (vone /= 0) loop
        if (vop >= vres + vone) then
            vop  := vop - (vres + vone);
            vres := vres/2 + vone;
        else
            vres := vres/2;
        end if;
        vone := vone/4;
    end loop;